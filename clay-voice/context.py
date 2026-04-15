"""
Clay Voice — Context Layer
Reads Claude Code memory files, calendar, and environmental context.
"""

import os
import glob
from datetime import datetime
from pathlib import Path
from typing import Optional


def load_claude_memory(memory_dir: str) -> dict[str, str]:
    """Load all Claude Code memory files into a dict."""
    memories = {}
    memory_path = Path(memory_dir)

    if not memory_path.exists():
        return {"error": f"Memory directory not found: {memory_dir}"}

    for md_file in memory_path.glob("*.md"):
        if md_file.name == "MEMORY.md":
            continue  # Index file, skip
        try:
            content = md_file.read_text(encoding="utf-8")
            memories[md_file.stem] = content
        except Exception as e:
            memories[md_file.stem] = f"[Error reading: {e}]"

    return memories


def build_identity_block(memories: dict[str, str]) -> str:
    """Extract identity and preference info from Claude memory files."""
    priority_files = [
        "user_identity",
        "user_adhd_routines",
        "user_email_accounts",
        "feedback_approach",
    ]

    blocks = []
    for key in priority_files:
        if key in memories:
            # Strip YAML frontmatter
            content = memories[key]
            if content.startswith("---"):
                parts = content.split("---", 2)
                if len(parts) >= 3:
                    content = parts[2].strip()
            blocks.append(content)

    return "\n\n".join(blocks) if blocks else "No identity information loaded."


def build_calendar_block() -> str:
    """Build a natural-language summary of today's schedule.

    For now, reads from a cached file. Future: direct Google Calendar API.
    """
    # TODO: Integrate with Google Calendar API or workspace-mcp
    # For now, return time-of-day awareness
    now = datetime.now()
    hour = now.hour
    day_name = now.strftime("%A")
    date_str = now.strftime("%B %d, %Y")

    time_of_day = (
        "early morning" if hour < 8
        else "morning" if hour < 12
        else "afternoon" if hour < 17
        else "evening" if hour < 21
        else "late night"
    )

    # Day-of-week context
    day_context = {
        "Monday": "Class night: IS 7036 (3:30-5:20) then IS 7060 (6:00-10:00) at Lindner Hall.",
        "Tuesday": "Deep work day. Academic focus 9-12, PhD/SOK 1-4.",
        "Wednesday": "Class night: IS 7036 (3:30-5:20) then IS 8044 (6:00-10:00) at Lindner Hall.",
        "Thursday": "Deep work day. Academic focus 9-12, PhD/SOK 1-4.",
        "Friday": "Friday Seminars at 3:30 (Business Formal).",
        "Saturday": "Assignment Sprint 9-12. Otherwise flexible.",
        "Sunday": "Weekly Planning & Review at 10:00 AM.",
    }

    schedule = day_context.get(day_name, "")

    return (
        f"Today is {day_name}, {date_str}. It's {time_of_day}.\n"
        f"{schedule}"
    )


def build_tasks_block() -> str:
    """Build a summary of active high-priority tasks.

    Future: read from Google Tasks API.
    """
    # TODO: Integrate with Google Tasks API
    return "Tasks: Check Google Tasks for current priorities."


def build_system_prompt(
    template_path: str,
    memory_dir: str,
    conversation_memories: str = "",
) -> str:
    """Assemble the full system prompt from template + context."""
    # Load template
    template = Path(template_path).read_text(encoding="utf-8")

    # Load Claude memory files
    memories = load_claude_memory(memory_dir)
    identity_block = build_identity_block(memories)

    # Build context blocks
    calendar_block = build_calendar_block()
    tasks_block = build_tasks_block()

    # Substitute into template
    prompt = template.replace("{identity_block}", identity_block)
    prompt = prompt.replace("{calendar_block}", calendar_block)
    prompt = prompt.replace("{tasks_block}", tasks_block)
    prompt = prompt.replace("{memory_block}", conversation_memories or "No past conversations yet.")

    return prompt
