"""
Clay Voice — Tools Module
Actions the voice agent can take beyond just answering questions.
These are invoked by brain.py when it detects an actionable intent.
"""

import json
import os
from datetime import datetime, timedelta
from pathlib import Path


class VoiceTools:
    """Collection of tools the voice agent can invoke."""

    def __init__(self, config: dict):
        self.config = config
        self.grocery_file = Path(config.get("grocery_file", "data/grocery_list.json"))
        self.reminders_file = Path(config.get("reminders_file", "data/reminders.json"))
        self._ensure_files()

    def _ensure_files(self):
        """Create data files if they don't exist."""
        self.grocery_file.parent.mkdir(parents=True, exist_ok=True)
        if not self.grocery_file.exists():
            self.grocery_file.write_text("[]")
        if not self.reminders_file.exists():
            self.reminders_file.write_text("[]")

    # ─── GROCERY LIST ───────────────────────────────────

    def add_grocery_item(self, item: str) -> str:
        """Add an item to the grocery list."""
        items = json.loads(self.grocery_file.read_text())
        # Check for duplicates (case-insensitive)
        if any(i["item"].lower() == item.lower() for i in items):
            return f"{item} is already on the list."
        items.append({
            "item": item,
            "added": datetime.now().isoformat(),
            "got": False,
        })
        self.grocery_file.write_text(json.dumps(items, indent=2))
        return f"Added {item} to the grocery list. You now have {len(items)} items."

    def read_grocery_list(self) -> str:
        """Read the current grocery list."""
        items = json.loads(self.grocery_file.read_text())
        if not items:
            return "The grocery list is empty."
        pending = [i for i in items if not i["got"]]
        if not pending:
            return "All items have been checked off. Nice."
        return f"You have {len(pending)} items: " + ", ".join(i["item"] for i in pending)

    def clear_grocery_list(self) -> str:
        """Clear checked-off items from the grocery list."""
        items = json.loads(self.grocery_file.read_text())
        remaining = [i for i in items if not i["got"]]
        self.grocery_file.write_text(json.dumps(remaining, indent=2))
        cleared = len(items) - len(remaining)
        return f"Cleared {cleared} items. {len(remaining)} remaining."

    # ─── REMINDERS ──────────────────────────────────────

    def add_reminder(self, text: str, minutes_from_now: int = 30) -> str:
        """Add a simple reminder."""
        reminders = json.loads(self.reminders_file.read_text())
        remind_at = datetime.now() + timedelta(minutes=minutes_from_now)
        reminders.append({
            "text": text,
            "created": datetime.now().isoformat(),
            "remind_at": remind_at.isoformat(),
            "fired": False,
        })
        self.reminders_file.write_text(json.dumps(reminders, indent=2))
        return f"Reminder set: '{text}' in {minutes_from_now} minutes (at {remind_at.strftime('%I:%M %p')})."

    def check_reminders(self) -> list[str]:
        """Check for any reminders that should fire now."""
        reminders = json.loads(self.reminders_file.read_text())
        now = datetime.now()
        fired = []
        for r in reminders:
            if not r["fired"] and datetime.fromisoformat(r["remind_at"]) <= now:
                r["fired"] = True
                fired.append(r["text"])
        self.reminders_file.write_text(json.dumps(reminders, indent=2))
        return fired

    # ─── QUICK NOTES ────────────────────────────────────

    def save_note(self, text: str) -> str:
        """Save a quick voice note to the parking lot file."""
        parking_lot = Path("data/parking_lot.md")
        parking_lot.parent.mkdir(parents=True, exist_ok=True)
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M")
        with open(parking_lot, "a", encoding="utf-8") as f:
            f.write(f"\n- [{timestamp}] {text}")
        return f"Noted: '{text}'. It's in your parking lot."

    def read_notes(self) -> str:
        """Read today's parking lot notes."""
        parking_lot = Path("data/parking_lot.md")
        if not parking_lot.exists():
            return "No notes in the parking lot."
        content = parking_lot.read_text().strip()
        today = datetime.now().strftime("%Y-%m-%d")
        today_notes = [line for line in content.split("\n") if today in line]
        if not today_notes:
            return "No notes from today."
        return f"Today's notes: " + "; ".join(
            line.split("] ", 1)[1] if "] " in line else line
            for line in today_notes
        )

    # ─── DAILY CONTEXT ──────────────────────────────────

    def whats_next(self) -> str:
        """Quick summary of what's coming up."""
        now = datetime.now()
        hour = now.hour
        day = now.strftime("%A")

        if day in ("Monday", "Wednesday"):
            if hour < 14:
                return "Class night. You have until 2:30 before commute. Make it count."
            elif hour < 18:
                return "You should be at or heading to Lindner. IS 7036 starts at 3:30."
            elif hour < 22:
                return "You're in class mode. Second class ends at 10 PM."
            else:
                return "Classes are done. Wind-Down time. Don't start new tasks."
        elif day in ("Tuesday", "Thursday"):
            if hour < 9:
                return "Deep work day. Morning Launch Pad, then FOCUS block at 9."
            elif hour < 12:
                return "You're in the academic deep work block. Phone should be on DND."
            elif hour < 13:
                return "Lunch break. Eat something. Walk. Don't check email."
            elif hour < 16:
                return "PhD and SOK deep work block. What's the one thing you're working on?"
            else:
                return "Deep work blocks are done. Lighter tasks, exercise, or leisure."
        elif day == "Friday":
            if hour < 15:
                return "Light day. Catch up on anything from the week."
            else:
                return "Friday Seminars at 3:30 if scheduled. Business formal."
        elif day == "Saturday":
            if hour < 9:
                return "Assignment Sprint starts at 9. What's most overdue?"
            elif hour < 12:
                return "You're in the Sprint. One task at a time."
            else:
                return "Sprint is done. The rest of Saturday is yours."
        elif day == "Sunday":
            if hour < 10:
                return "Weekly Planning at 10 AM. Fill out the Review Form first."
            elif hour < 11:
                return "You should be in the Weekly Planning block. Use the checklist."
            else:
                return "Planning is done. Prep for Monday. Rest."
        return "Check your calendar for what's next."
