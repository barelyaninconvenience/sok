"""
Clay Voice — Main Entry Point
Wake word → Listen → Think → Speak loop.

Usage:
    python main.py              # Full voice mode with wake word
    python main.py --push       # Push-to-talk mode (press Enter to speak)
    python main.py --text       # Text-only mode (type instead of speak, for testing)
    python main.py --stats      # Show memory stats and exit

Requires: pip install -r requirements.txt
Config: config.yaml (copy to config.local.yaml with your API keys)
"""

import argparse
import os
import sys
import uuid
from datetime import datetime
from pathlib import Path

import yaml

from brain import VoiceBrain


def load_config() -> dict:
    """Load config from YAML, with local overrides and env var substitution."""
    config_path = Path("config.local.yaml")
    if not config_path.exists():
        config_path = Path("config.yaml")

    with open(config_path, "r") as f:
        config = yaml.safe_load(f)

    # Substitute environment variables
    for key, value in config.items():
        if isinstance(value, str) and value.startswith("${") and value.endswith("}"):
            env_var = value[2:-1]
            config[key] = os.environ.get(env_var, "")

    return config


def text_mode(brain: VoiceBrain):
    """Text-only mode for testing without audio hardware."""
    print("\n=== Clay Voice — Text Mode ===")
    print("Type your messages. Type 'quit' to exit, 'stats' for memory stats.\n")

    while True:
        try:
            user_input = input("You: ").strip()
        except (KeyboardInterrupt, EOFError):
            print("\nGoodbye!")
            break

        if not user_input:
            continue
        if user_input.lower() == "quit":
            print("Goodbye!")
            break
        if user_input.lower() == "stats":
            stats = brain.get_stats()
            print(f"  Total conversations: {stats['total_exchanges']}")
            print(f"  Unique days: {stats['unique_days']}")
            print(f"  This session: {stats['current_session_turns']} turns")
            print(f"  Latest: {stats['latest_conversation']}")
            continue

        # Think and respond
        print("Clay Voice: ", end="", flush=True)
        for chunk in brain.think_streaming(user_input):
            print(chunk, end="", flush=True)
        print()


def push_to_talk_mode(brain: VoiceBrain, config: dict):
    """Push-to-talk: press Enter to start recording, speak, press Enter to stop."""
    try:
        import sounddevice as sd
        import numpy as np
        from faster_whisper import WhisperModel
    except ImportError as e:
        print(f"Missing dependency for voice mode: {e}")
        print("Run: pip install sounddevice numpy faster-whisper")
        sys.exit(1)

    print("\n=== Clay Voice — Push-to-Talk Mode ===")
    print("Press Enter to start recording, speak, press Enter to stop.")
    print("Type 'quit' to exit.\n")

    # Load Whisper model
    whisper_size = config.get("whisper_model", "base")
    print(f"Loading Whisper model ({whisper_size})... ", end="", flush=True)
    whisper = WhisperModel(whisper_size, device="cpu", compute_type="int8")
    print("ready.")

    sample_rate = config.get("sample_rate", 16000)

    while True:
        cmd = input("[Press Enter to speak, 'quit' to exit] ").strip()
        if cmd.lower() == "quit":
            break

        # Record audio
        print("🎤 Recording... (press Enter to stop)")
        frames = []
        recording = True

        def callback(indata, frame_count, time_info, status):
            if recording:
                frames.append(indata.copy())

        stream = sd.InputStream(
            samplerate=sample_rate, channels=1, dtype="float32", callback=callback
        )
        stream.start()
        input()  # Wait for Enter
        recording = False
        stream.stop()
        stream.close()

        if not frames:
            print("No audio captured.")
            continue

        # Concatenate and transcribe
        audio = np.concatenate(frames, axis=0).flatten()
        print("Transcribing... ", end="", flush=True)

        segments, _ = whisper.transcribe(audio, language="en")
        transcript = " ".join(seg.text for seg in segments).strip()

        if not transcript:
            print("(silence)")
            continue

        print(f'"{transcript}"')

        # Think and respond
        print("Clay Voice: ", end="", flush=True)
        response_text = []
        for chunk in brain.think_streaming(transcript):
            print(chunk, end="", flush=True)
            response_text.append(chunk)
        print()

        # TTS output (if available)
        full_response = "".join(response_text)
        try:
            _speak(full_response, config)
        except Exception:
            pass  # TTS optional; text output is the fallback


def _speak(text: str, config: dict):
    """Text-to-speech output. Tries Piper, falls back to system TTS."""
    try:
        # Try Piper TTS
        from piper import PiperVoice

        model_path = config.get("piper_model", "en_US-amy-medium")
        voice = PiperVoice.load(model_path)
        # Piper synthesis would go here — implementation depends on piper-tts version
        # For now, fall through to system TTS
        raise NotImplementedError("Piper integration pending model download")
    except (ImportError, NotImplementedError):
        pass

    # Fallback: Windows SAPI (built-in, no install needed)
    try:
        import subprocess
        # Use PowerShell's built-in speech synthesis
        ps_cmd = f'Add-Type -AssemblyName System.Speech; $s = New-Object System.Speech.Synthesis.SpeechSynthesizer; $s.Speak("{text.replace(chr(34), "")}")'
        subprocess.Popen(
            ["powershell", "-NoProfile", "-Command", ps_cmd],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
    except Exception:
        pass  # Silent fallback — text output is always available


def main():
    parser = argparse.ArgumentParser(description="Clay Voice — Personal AI Voice Agent")
    parser.add_argument("--text", action="store_true", help="Text-only mode (no audio)")
    parser.add_argument("--push", action="store_true", help="Push-to-talk mode")
    parser.add_argument("--stats", action="store_true", help="Show memory stats and exit")
    args = parser.parse_args()

    # Load config
    config = load_config()

    # Initialize brain
    brain = VoiceBrain(config)
    session_id = f"voice-{datetime.now().strftime('%Y%m%d-%H%M%S')}-{uuid.uuid4().hex[:8]}"
    brain.start_session(session_id)

    if args.stats:
        stats = brain.get_stats()
        print(f"Total conversations: {stats['total_exchanges']}")
        print(f"Unique days: {stats['unique_days']}")
        print(f"This session: {stats['current_session_turns']} turns")
        print(f"Latest: {stats['latest_conversation']}")
        return

    if args.text:
        text_mode(brain)
    elif args.push:
        push_to_talk_mode(brain, config)
    else:
        # Full voice mode with wake word (requires Porcupine or openWakeWord)
        print("Full wake-word mode requires Porcupine setup.")
        print("For now, use --push (push-to-talk) or --text (text-only).")
        print("See ARCHITECTURE.md for wake word setup instructions.")
        push_to_talk_mode(brain, config)


if __name__ == "__main__":
    main()
