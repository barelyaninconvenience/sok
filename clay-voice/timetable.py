"""
Clay Voice / Standalone — Timetable Calculator
Cascading time estimation with ADHD buffers.

Usage:
    python timetable.py                          # Interactive mode
    python timetable.py --anchor "11:11 AM" --direction backward  # Anchor + direction
    python timetable.py --preset airport-depart  # Load a preset

Presets:
    airport-depart  — CVG departure from Milford
    airport-return  — CVG return to Milford
    class-night     — Commute to Lindner Hall
    custom          — Build your own (interactive)

The ADHD buffer (default 1.5x on transition steps + 15 min global buffer)
can be adjusted via --buffer-multiplier and --global-buffer.
"""

import argparse
import sys
from datetime import datetime, timedelta
from typing import Optional


class Waypoint:
    """A single step in a timetable with estimated duration."""

    def __init__(self, name: str, minutes: int, notes: str = "", is_transition: bool = False):
        self.name = name
        self.minutes = minutes
        self.notes = notes
        self.is_transition = is_transition  # Transitions get ADHD buffer multiplied


class Timetable:
    """Cascading timetable calculator."""

    def __init__(self, adhd_multiplier: float = 1.5, global_buffer_min: int = 15):
        self.waypoints: list[Waypoint] = []
        self.adhd_multiplier = adhd_multiplier
        self.global_buffer = global_buffer_min

    def add(self, name: str, minutes: int, notes: str = "", is_transition: bool = False):
        """Add a waypoint to the timetable."""
        self.waypoints.append(Waypoint(name, minutes, notes, is_transition))
        return self  # Chainable

    def calculate_backward(self, anchor_time: datetime) -> list[dict]:
        """Work backward from an anchor time (e.g., flight departure)."""
        results = []
        current = anchor_time

        # Add anchor
        results.append({
            "time": current,
            "name": "ANCHOR: " + (self.waypoints[-1].name if self.waypoints else "Target"),
            "duration": 0,
            "notes": "",
        })

        # Walk backward through waypoints (reversed)
        for wp in reversed(self.waypoints):
            adjusted_min = wp.minutes
            if wp.is_transition:
                adjusted_min = int(wp.minutes * self.adhd_multiplier)

            current = current - timedelta(minutes=adjusted_min)
            results.insert(0, {
                "time": current,
                "name": wp.name,
                "duration": adjusted_min,
                "notes": wp.notes + (f" (ADHD: {wp.minutes}→{adjusted_min} min)" if wp.is_transition and adjusted_min != wp.minutes else ""),
            })

        # Add global buffer at the start
        if self.global_buffer > 0:
            current = current - timedelta(minutes=self.global_buffer)
            results.insert(0, {
                "time": current,
                "name": f"ADHD BUFFER ({self.global_buffer} min)",
                "duration": self.global_buffer,
                "notes": "Leave this much earlier than the math says.",
            })

        return results

    def calculate_forward(self, anchor_time: datetime) -> list[dict]:
        """Work forward from an anchor time (e.g., landing time)."""
        results = []
        current = anchor_time

        results.append({
            "time": current,
            "name": "ANCHOR: Start",
            "duration": 0,
            "notes": "",
        })

        for wp in self.waypoints:
            adjusted_min = wp.minutes
            if wp.is_transition:
                adjusted_min = int(wp.minutes * self.adhd_multiplier)

            current = current + timedelta(minutes=adjusted_min)
            results.append({
                "time": current,
                "name": wp.name,
                "duration": adjusted_min,
                "notes": wp.notes + (f" (ADHD: {wp.minutes}→{adjusted_min} min)" if wp.is_transition and adjusted_min != wp.minutes else ""),
            })

        # Add global buffer at the end
        if self.global_buffer > 0:
            current = current + timedelta(minutes=self.global_buffer)
            results.append({
                "time": current,
                "name": f"ADHD BUFFER ({self.global_buffer} min)",
                "duration": self.global_buffer,
                "notes": "Add this cushion to the estimate.",
            })

        return results

    def display(self, results: list[dict], title: str = "TIMETABLE"):
        """Pretty-print a timetable."""
        print(f"\n{'='*60}")
        print(f"  {title}")
        print(f"  ADHD multiplier: {self.adhd_multiplier}x on transitions")
        print(f"  Global buffer: {self.global_buffer} min")
        print(f"{'='*60}\n")

        for i, r in enumerate(results):
            time_str = r["time"].strftime("%I:%M %p")
            duration_str = f"({r['duration']} min)" if r["duration"] > 0 else ""
            notes_str = f"  → {r['notes']}" if r["notes"] else ""

            marker = "▶" if i == 0 else "│" if i < len(results) - 1 else "◀"
            print(f"  {marker} {time_str:>8}  {r['name']:<40} {duration_str}{notes_str}")

        print(f"\n{'='*60}\n")


# ─── PRESETS ────────────────────────────────────────────────

def preset_airport_depart() -> Timetable:
    """CVG departure from Milford, OH."""
    tt = Timetable(adhd_multiplier=1.5, global_buffer_min=15)
    tt.add("Drive Milford → I-275 → CVG long-term parking", 45, "Morning traffic", is_transition=True)
    tt.add("Park + walk to shuttle stop", 10, "Long-term lots are spread out")
    tt.add("Wait for shuttle + ride to terminal", 15, "Shuttles every 10-15 min")
    tt.add("Enter terminal → through TSA", 30, "Budget for lines")
    tt.add("Walk to gate", 10)
    tt.add("Buffer at gate", 30, "Read, coffee, breathe")
    return tt


def preset_airport_return() -> Timetable:
    """CVG return to Milford, OH."""
    tt = Timetable(adhd_multiplier=1.0, global_buffer_min=15)
    tt.add("Taxi to gate", 10)
    tt.add("Deplane + walk to exit", 10, "Carry-on only? Skip baggage.")
    tt.add("Walk to shuttle pickup", 7)
    tt.add("Wait + shuttle to long-term lot", 20, "Evening shuttles busier")
    tt.add("Walk to car + pay/exit", 10)
    tt.add("Drive CVG → I-275 → Milford", 45, "Rush hour possible", is_transition=True)
    tt.add("Pick up dinner", 20, "Order on app during shuttle = no wait")
    return tt


def preset_class_night() -> Timetable:
    """Commute to Lindner Hall from home."""
    tt = Timetable(adhd_multiplier=1.5, global_buffer_min=10)
    tt.add("Pack bag + last-minute prep", 10, is_transition=True)
    tt.add("Drive to Lindner Hall", 30, "Traffic dependent")
    tt.add("Park + walk to room", 10)
    tt.add("Settle in before class", 5)
    return tt


PRESETS = {
    "airport-depart": ("CVG DEPARTURE — Milford to Gate", preset_airport_depart, "backward"),
    "airport-return": ("CVG RETURN — Landing to Front Door", preset_airport_return, "forward"),
    "class-night": ("CLASS NIGHT — Home to Lindner Hall", preset_class_night, "backward"),
}


def main():
    parser = argparse.ArgumentParser(description="Timetable Calculator with ADHD buffers")
    parser.add_argument("--preset", choices=list(PRESETS.keys()), help="Load a preset timetable")
    parser.add_argument("--anchor", help="Anchor time (e.g., '11:11 AM', '16:33')")
    parser.add_argument("--direction", choices=["forward", "backward"], default="backward")
    parser.add_argument("--buffer-multiplier", type=float, default=1.5, help="ADHD transition multiplier")
    parser.add_argument("--global-buffer", type=int, default=15, help="Global buffer in minutes")
    args = parser.parse_args()

    if args.preset:
        title, factory, direction = PRESETS[args.preset]
        tt = factory()

        if args.anchor:
            anchor = parse_time(args.anchor)
        else:
            anchor_input = input(f"Enter anchor time for '{title}' (e.g., 11:11 AM): ").strip()
            anchor = parse_time(anchor_input)

        if direction == "backward":
            results = tt.calculate_backward(anchor)
        else:
            results = tt.calculate_forward(anchor)

        tt.display(results, title)
    else:
        print("Interactive mode not yet implemented. Use --preset for now.")
        print(f"Available presets: {', '.join(PRESETS.keys())}")


def parse_time(time_str: str) -> datetime:
    """Parse a time string into a datetime (today's date)."""
    today = datetime.now().date()
    for fmt in ("%I:%M %p", "%H:%M", "%I:%M%p", "%H%M"):
        try:
            t = datetime.strptime(time_str.strip(), fmt).time()
            return datetime.combine(today, t)
        except ValueError:
            continue
    raise ValueError(f"Could not parse time: '{time_str}'. Try '11:11 AM' or '16:33'.")


if __name__ == "__main__":
    main()
