"""
Clay Voice — Morning Briefing Module
Generates a spoken daily briefing for the Morning Launch Pad block.

Usage:
    python morning_briefing.py          # Print briefing to console
    python morning_briefing.py --speak  # TTS output (requires main.py TTS setup)

Designed to run at 8:00 AM or be triggered by the voice agent via
"Give me my morning briefing."
"""

import os
import sys
from datetime import datetime, timedelta
from pathlib import Path

# Reuse context module from clay-voice
sys.path.insert(0, str(Path(__file__).parent))
from context import build_calendar_block, load_claude_memory


def generate_briefing() -> str:
    """Generate a natural-language morning briefing."""
    now = datetime.now()
    day_name = now.strftime("%A")
    date_str = now.strftime("%B %d, %Y")

    sections = []

    # Greeting
    sections.append(f"Good morning, Clay. It's {day_name}, {date_str}.")

    # Calendar context
    cal = build_calendar_block()
    if cal:
        sections.append(cal)

    # Day-specific reminders
    reminders = _get_day_reminders(day_name, now)
    if reminders:
        sections.append(reminders)

    # ADHD prompt
    sections.append(
        "For your Launch Pad: What are your three priorities today? "
        "One MUST, one SHOULD, one NICE."
    )

    return "\n\n".join(sections)


def _get_day_reminders(day_name: str, now: datetime) -> str:
    """Generate day-specific reminders."""
    reminders = []

    if day_name in ("Monday", "Wednesday"):
        reminders.append(
            "Class night. Commute to Lindner by 2:30. "
            "Pack food for the between-class transition or eat before you leave."
        )

    if day_name in ("Tuesday", "Thursday"):
        reminders.append(
            "Deep work day. Protect your focus blocks. "
            "Phone on DND from 9 to noon, then 1 to 4."
        )

    if day_name == "Friday":
        reminders.append(
            "Friday Seminars at 3:30. Business formal."
        )

    if day_name == "Saturday":
        reminders.append(
            "Assignment Sprint at 9 AM. What's most overdue?"
        )

    if day_name == "Sunday":
        reminders.append(
            "Weekly Planning at 10 AM. Fill out the Weekly Review Form first. "
            "Review 10 contacts from the audit sheet."
        )

    # Check for upcoming drills (hardcoded for now; future: read from calendar API)
    drill_dates = [
        (datetime(2026, 4, 9), datetime(2026, 4, 13), "CSTX"),
        (datetime(2026, 4, 17), datetime(2026, 4, 19), "Drill"),
    ]

    for start, end, name in drill_dates:
        days_until = (start - now).days
        if days_until == 1:
            reminders.append(
                f"USAR {name} starts tomorrow. "
                "Did you pack? Email professors? Confirm reporting time?"
            )
        elif days_until == 0 or (start <= now <= end):
            reminders.append(f"USAR {name} is today. Stay sharp.")
        elif days_until == 2:
            reminders.append(
                f"USAR {name} is in 2 days. Start drill prep tonight."
            )

    return " ".join(reminders) if reminders else ""


if __name__ == "__main__":
    briefing = generate_briefing()
    print(briefing)

    if "--speak" in sys.argv:
        try:
            # Use Windows SAPI as fallback TTS
            import subprocess
            clean = briefing.replace('"', '').replace('\n', ' ')
            subprocess.run(
                ["powershell", "-NoProfile", "-Command",
                 f'Add-Type -AssemblyName System.Speech; '
                 f'$s = New-Object System.Speech.Synthesis.SpeechSynthesizer; '
                 f'$s.Rate = 1; $s.Speak("{clean}")'],
                check=True
            )
        except Exception as e:
            print(f"\n[TTS unavailable: {e}]")
