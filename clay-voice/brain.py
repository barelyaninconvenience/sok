"""
Clay Voice — Brain Layer
Claude API integration with context-aware prompting and streaming response.
"""

import os
from typing import Generator, Optional

import anthropic

from memory import (
    init_db,
    save_turn,
    search_memory,
    get_recent_turns,
    format_memories_for_prompt,
)
from context import build_system_prompt


class VoiceBrain:
    """The thinking layer: Claude API + memory + context assembly."""

    def __init__(self, config: dict):
        self.config = config
        self.client = anthropic.Anthropic(
            api_key=config.get("anthropic_api_key") or os.environ.get("ANTHROPIC_API_KEY")
        )
        self.model = config.get("model", "claude-sonnet-4-6")
        self.max_words = config.get("max_response_words", 75)
        self.max_context_turns = config.get("max_context_turns", 10)
        self.max_memory_results = config.get("max_memory_results", 5)

        # Initialize memory
        db_path = config.get("database_path", "data/conversations.db")
        self.conn = init_db(db_path)

        # Session tracking
        self.session_id = None
        self.session_turns: list[dict] = []

        # System prompt (built lazily)
        self._system_prompt = None
        self._prompt_template = config.get(
            "prompt_template", "prompts/system.md"
        )
        self._memory_dir = config.get(
            "claude_memory_dir",
            os.path.expanduser("~/.claude/projects/C--Users-shelc/memory"),
        )

    def start_session(self, session_id: str):
        """Start a new voice session."""
        self.session_id = session_id
        self.session_turns = []
        self._rebuild_system_prompt("")
        print(f"[Brain] Session started: {session_id}")

    def _rebuild_system_prompt(self, query: str):
        """Rebuild system prompt with fresh context and relevant memories."""
        # Search past conversations for relevance to current query
        if query:
            memories = search_memory(
                self.conn,
                query,
                top_k=self.max_memory_results,
                exclude_session=self.session_id,
            )
            memory_text = format_memories_for_prompt(memories)
        else:
            memory_text = "Session just started. No query context yet."

        self._system_prompt = build_system_prompt(
            template_path=self._prompt_template,
            memory_dir=self._memory_dir,
            conversation_memories=memory_text,
        )

    def think(self, user_text: str, speaker: str = "clay") -> str:
        """Process user speech and return Claude's response."""
        # Rebuild system prompt with memory relevant to this query
        self._rebuild_system_prompt(user_text)

        # Build messages from session history + new turn
        messages = []
        for turn in self.session_turns[-self.max_context_turns :]:
            messages.append({"role": "user", "content": turn["user_text"]})
            messages.append({"role": "assistant", "content": turn["assistant_text"]})

        # Add current turn
        messages.append({"role": "user", "content": user_text})

        # Call Claude
        response = self.client.messages.create(
            model=self.model,
            max_tokens=300,  # ~75 words for voice
            system=self._system_prompt,
            messages=messages,
        )

        assistant_text = response.content[0].text

        # Save to session and persistent memory
        self.session_turns.append(
            {"user_text": user_text, "assistant_text": assistant_text}
        )
        save_turn(
            self.conn,
            user_text=user_text,
            assistant_text=assistant_text,
            speaker=speaker,
            session_id=self.session_id,
        )

        return assistant_text

    def think_streaming(self, user_text: str, speaker: str = "clay") -> Generator[str, None, None]:
        """Stream Claude's response token-by-token for low-latency TTS."""
        self._rebuild_system_prompt(user_text)

        messages = []
        for turn in self.session_turns[-self.max_context_turns :]:
            messages.append({"role": "user", "content": turn["user_text"]})
            messages.append({"role": "assistant", "content": turn["assistant_text"]})
        messages.append({"role": "user", "content": user_text})

        full_response = []
        with self.client.messages.stream(
            model=self.model,
            max_tokens=300,
            system=self._system_prompt,
            messages=messages,
        ) as stream:
            for text in stream.text_stream:
                full_response.append(text)
                yield text

        # Save complete response
        assistant_text = "".join(full_response)
        self.session_turns.append(
            {"user_text": user_text, "assistant_text": assistant_text}
        )
        save_turn(
            self.conn,
            user_text=user_text,
            assistant_text=assistant_text,
            speaker=speaker,
            session_id=self.session_id,
        )

    def get_stats(self) -> dict:
        """Get memory stats for the current brain."""
        from memory import get_conversation_stats
        stats = get_conversation_stats(self.conn)
        stats["current_session_turns"] = len(self.session_turns)
        return stats
