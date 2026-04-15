"""
Clay Voice — Timer Module
Pomodoro and custom timers with audio alerts.

Usage:
    Triggered by voice: "Start a 25-minute Pomodoro"
    Or from CLI: python timer.py 25
    Or imported by brain.py as a tool the voice agent can invoke.
"""

import sys
import time
import threading
from datetime import datetime, timedelta


class VoiceTimer:
    """Simple timer with callback for voice agent integration."""

    def __init__(self, on_complete=None):
        self.active_timer = None
        self.on_complete = on_complete or self._default_alert

    def start_pomodoro(self, work_min: int = 25, break_min: int = 5) -> str:
        """Start a Pomodoro cycle: work → alert → break → alert."""
        self.start(work_min, label=f"Pomodoro work ({work_min} min)")
        return f"Pomodoro started. {work_min} minutes of focus. I'll let you know when it's time for a {break_min}-minute break."

    def start(self, minutes: int, label: str = "Timer") -> str:
        """Start a custom timer."""
        if self.active_timer and self.active_timer.is_alive():
            return "A timer is already running. Say 'cancel timer' to stop it first."

        end_time = datetime.now() + timedelta(minutes=minutes)
        self.active_timer = threading.Timer(
            minutes * 60,
            self._timer_done,
            args=(label, minutes),
        )
        self.active_timer.daemon = True
        self.active_timer.start()

        return f"{label} set for {minutes} minutes. Ends at {end_time.strftime('%I:%M %p')}."

    def cancel(self) -> str:
        """Cancel the active timer."""
        if self.active_timer and self.active_timer.is_alive():
            self.active_timer.cancel()
            self.active_timer = None
            return "Timer cancelled."
        return "No active timer to cancel."

    def status(self) -> str:
        """Check if a timer is running."""
        if self.active_timer and self.active_timer.is_alive():
            return "A timer is currently running."
        return "No active timer."

    def _timer_done(self, label: str, minutes: int):
        """Called when timer completes."""
        message = f"Time's up! Your {label} ({minutes} minutes) is complete."
        if self.on_complete:
            self.on_complete(message)
        self.active_timer = None

    @staticmethod
    def _default_alert(message: str):
        """Default alert: print + system beep + Windows TTS."""
        print(f"\n🔔 {message}")

        # System beep
        try:
            import winsound
            for _ in range(3):
                winsound.Beep(800, 300)
                time.sleep(0.2)
        except ImportError:
            print("\a")  # Terminal bell fallback

        # TTS announcement
        try:
            import subprocess
            clean = message.replace('"', '')
            subprocess.Popen(
                ["powershell", "-NoProfile", "-Command",
                 f'Add-Type -AssemblyName System.Speech; '
                 f'$s = New-Object System.Speech.Synthesis.SpeechSynthesizer; '
                 f'$s.Speak("{clean}")'],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
        except Exception:
            pass


if __name__ == "__main__":
    minutes = int(sys.argv[1]) if len(sys.argv) > 1 else 25
    timer = VoiceTimer()
    print(timer.start_pomodoro(minutes))
    print("Timer running in background. Press Ctrl+C to cancel.")
    try:
        while timer.active_timer and timer.active_timer.is_alive():
            time.sleep(1)
    except KeyboardInterrupt:
        print(timer.cancel())
