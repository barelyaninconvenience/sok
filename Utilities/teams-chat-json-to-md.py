"""
Companion post-processor: convert the JSON output of teams-chat-extract.js
into a clean chronological markdown chat log.

Usage:
    python teams-chat-json-to-md.py path/to/chat.json [> path/to/chat.md]

Input format (from the DOM extractor):
    [
      { "sender": "...", "timestamp": "...", "body": "...", "bodyHtml": "...",
        "attachments": [...], "reactions": [...] },
      ...
    ]
"""
import json
import sys
from datetime import datetime


def to_iso(ts: str | None) -> str | None:
    """Best-effort timestamp normalization."""
    if not ts:
        return None
    try:
        return datetime.fromisoformat(ts.replace("Z", "+00:00")).isoformat(timespec="seconds")
    except Exception:
        return ts


def render(messages: list[dict]) -> str:
    lines = [
        "# Teams chat capture (DOM extract)",
        "",
        f"Captured: {datetime.now().isoformat(timespec='seconds')}",
        f"Message count: {len(messages)}",
        "",
        "---",
        "",
    ]

    for m in messages:
        sender = m.get("sender") or "(unknown sender)"
        timestamp = to_iso(m.get("timestamp")) or "(no timestamp)"

        lines.append(f"### {sender} — {timestamp}")
        lines.append("")

        body = (m.get("body") or "").strip()
        if body:
            lines.append(body)
            lines.append("")

        attachments = m.get("attachments") or []
        if attachments:
            lines.append("**Attachments:**")
            for a in attachments:
                text = a.get("text", "(unnamed)")
                href = a.get("href", "")
                lines.append(f"- {text}{f' — {href}' if href else ''}")
            lines.append("")

        reactions = m.get("reactions") or []
        if reactions:
            lines.append(f"_Reactions: {', '.join(reactions)}_")
            lines.append("")

    return "\n".join(lines)


def main():
    if len(sys.argv) < 2:
        print("Usage: python teams-chat-json-to-md.py <chat.json>", file=sys.stderr)
        sys.exit(1)

    with open(sys.argv[1], "r", encoding="utf-8") as f:
        messages = json.load(f)

    if not isinstance(messages, list):
        print("Input JSON must be an array of message objects", file=sys.stderr)
        sys.exit(1)

    print(render(messages))


if __name__ == "__main__":
    main()
