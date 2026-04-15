# CLAUDE.md — Clay Voice Project Scope
# Applies when working directory is clay-voice/

## Project
Clay Voice — Persistent Claude-powered voice assistant with memory across conversations.

## Architecture
See ARCHITECTURE.md in this directory for full design.

## Conventions
- Python 3.12+
- Type hints on all function signatures
- Docstrings on all public functions
- Config via config.yaml (config.local.yaml for secrets, gitignored)
- SQLite for conversation persistence
- sentence-transformers for embeddings (lazy-loaded)
- Claude API via `anthropic` SDK

## Key Design Decisions
- Memory is semantic (embedding-based search), not keyword
- System prompt is dynamically assembled (identity + calendar + memories + session history)
- Jaz Mode reduces technical jargon, drops project/military context
- Voice responses kept under 75 words (~30 sec speech)
- Three modes: text (testing), push-to-talk (voice), wake-word (hands-free)

## Testing
```bash
python main.py --text   # Test brain/memory without audio
python main.py --push   # Push-to-talk with Whisper STT
python main.py --stats  # Show conversation database stats
```

## Dependencies
See requirements.txt. Core: anthropic, faster-whisper, piper-tts, sentence-transformers, sounddevice.
