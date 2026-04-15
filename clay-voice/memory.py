"""
Clay Voice — Memory Layer
Persistent conversation storage + semantic search over past voice interactions.
"""

import sqlite3
import json
import os
from datetime import datetime
from pathlib import Path
from typing import Optional

# Lazy-load heavy dependencies
_embedder = None


def _get_embedder():
    """Lazy-load sentence-transformers to avoid slow startup."""
    global _embedder
    if _embedder is None:
        from sentence_transformers import SentenceTransformer
        _embedder = SentenceTransformer("all-MiniLM-L6-v2")
    return _embedder


def init_db(db_path: str = "data/conversations.db") -> sqlite3.Connection:
    """Initialize the conversation database."""
    os.makedirs(os.path.dirname(db_path), exist_ok=True)
    conn = sqlite3.connect(db_path)
    conn.execute("""
        CREATE TABLE IF NOT EXISTS conversations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp TEXT NOT NULL,
            speaker TEXT DEFAULT 'clay',
            user_text TEXT NOT NULL,
            assistant_text TEXT NOT NULL,
            embedding BLOB,
            session_id TEXT,
            metadata TEXT
        )
    """)
    conn.execute("""
        CREATE TABLE IF NOT EXISTS sessions (
            id TEXT PRIMARY KEY,
            started_at TEXT NOT NULL,
            ended_at TEXT,
            turn_count INTEGER DEFAULT 0,
            summary TEXT
        )
    """)
    conn.execute("""
        CREATE INDEX IF NOT EXISTS idx_conversations_timestamp
        ON conversations(timestamp DESC)
    """)
    conn.commit()
    return conn


def save_turn(
    conn: sqlite3.Connection,
    user_text: str,
    assistant_text: str,
    speaker: str = "clay",
    session_id: Optional[str] = None,
    metadata: Optional[dict] = None,
) -> int:
    """Save a conversation turn and its embedding."""
    timestamp = datetime.now().isoformat()

    # Generate embedding from the combined exchange
    combined = f"User: {user_text}\nAssistant: {assistant_text}"
    embedder = _get_embedder()
    embedding = embedder.encode(combined).tobytes()

    cursor = conn.execute(
        """
        INSERT INTO conversations (timestamp, speaker, user_text, assistant_text, embedding, session_id, metadata)
        VALUES (?, ?, ?, ?, ?, ?, ?)
        """,
        (
            timestamp,
            speaker,
            user_text,
            assistant_text,
            embedding,
            session_id,
            json.dumps(metadata) if metadata else None,
        ),
    )
    conn.commit()
    return cursor.lastrowid


def search_memory(
    conn: sqlite3.Connection,
    query: str,
    top_k: int = 5,
    exclude_session: Optional[str] = None,
) -> list[dict]:
    """Semantic search over past conversations. Returns most relevant exchanges."""
    import numpy as np

    embedder = _get_embedder()
    query_emb = embedder.encode(query)

    # Load all embeddings (for small-medium databases this is fine;
    # for 10k+ conversations, switch to FAISS or similar)
    where_clause = ""
    params = []
    if exclude_session:
        where_clause = "WHERE session_id != ? OR session_id IS NULL"
        params = [exclude_session]

    rows = conn.execute(
        f"""
        SELECT id, timestamp, speaker, user_text, assistant_text, embedding
        FROM conversations
        {where_clause}
        ORDER BY timestamp DESC
        LIMIT 1000
        """,
        params,
    ).fetchall()

    if not rows:
        return []

    # Compute cosine similarities
    results = []
    for row in rows:
        row_id, ts, speaker, user_text, assistant_text, emb_bytes = row
        if emb_bytes is None:
            continue
        row_emb = np.frombuffer(emb_bytes, dtype=np.float32)
        similarity = np.dot(query_emb, row_emb) / (
            np.linalg.norm(query_emb) * np.linalg.norm(row_emb) + 1e-8
        )
        results.append(
            {
                "id": row_id,
                "timestamp": ts,
                "speaker": speaker,
                "user_text": user_text,
                "assistant_text": assistant_text,
                "similarity": float(similarity),
            }
        )

    # Sort by similarity, return top_k
    results.sort(key=lambda x: x["similarity"], reverse=True)
    return results[:top_k]


def get_recent_turns(
    conn: sqlite3.Connection,
    session_id: str,
    limit: int = 10,
) -> list[dict]:
    """Get the most recent turns from the current session."""
    rows = conn.execute(
        """
        SELECT timestamp, speaker, user_text, assistant_text
        FROM conversations
        WHERE session_id = ?
        ORDER BY timestamp DESC
        LIMIT ?
        """,
        (session_id, limit),
    ).fetchall()

    return [
        {
            "timestamp": r[0],
            "speaker": r[1],
            "user_text": r[2],
            "assistant_text": r[3],
        }
        for r in reversed(rows)  # Chronological order
    ]


def get_conversation_stats(conn: sqlite3.Connection) -> dict:
    """Get stats about the conversation database."""
    total = conn.execute("SELECT COUNT(*) FROM conversations").fetchone()[0]
    unique_days = conn.execute(
        "SELECT COUNT(DISTINCT DATE(timestamp)) FROM conversations"
    ).fetchone()[0]
    latest = conn.execute(
        "SELECT MAX(timestamp) FROM conversations"
    ).fetchone()[0]

    return {
        "total_exchanges": total,
        "unique_days": unique_days,
        "latest_conversation": latest,
    }


def format_memories_for_prompt(memories: list[dict]) -> str:
    """Format retrieved memories into natural language for the system prompt."""
    if not memories:
        return "No relevant past conversations found."

    lines = []
    for m in memories:
        ts = datetime.fromisoformat(m["timestamp"])
        relative = _relative_time(ts)
        lines.append(
            f"[{relative}] {m['speaker'].title()} asked: \"{m['user_text'][:200]}\"\n"
            f"  You responded: \"{m['assistant_text'][:200]}\""
        )
    return "\n\n".join(lines)


def _relative_time(dt: datetime) -> str:
    """Convert timestamp to natural relative time."""
    now = datetime.now()
    delta = now - dt
    if delta.days == 0:
        hours = delta.seconds // 3600
        if hours == 0:
            return "just now"
        return f"{hours} hour{'s' if hours != 1 else ''} ago"
    elif delta.days == 1:
        return "yesterday"
    elif delta.days < 7:
        return f"{delta.days} days ago"
    elif delta.days < 30:
        weeks = delta.days // 7
        return f"{weeks} week{'s' if weeks != 1 else ''} ago"
    else:
        return dt.strftime("%b %d")
