# Clay Voice — Persistent Claude Voice Agent
## Architecture Document

---

## Vision
A unified voice assistant that:
- Responds to "Hey Claude" wake word
- Remembers ALL previous voice conversations
- Has access to Clay's Claude Code memory files (identity, preferences, projects)
- Makes soft references to past conversations, ongoing projects, calendar context
- Replaces Alexa as the household voice interface
- Jaz-friendly: natural, accurate, no mishearings, no upsells

---

## Architecture

```
                    ┌─────────────────────────────┐
                    │     Clay or Jaz speaks       │
                    └──────────┬──────────────────┘
                               │
                    ┌──────────▼──────────────────┐
                    │   Wake Word Detection        │
                    │   (Porcupine / openWakeWord) │
                    └──────────┬──────────────────┘
                               │ triggered
                    ┌──────────▼──────────────────┐
                    │   Speech-to-Text             │
                    │   (faster-whisper local)     │
                    └──────────┬──────────────────┘
                               │ transcript
                    ┌──────────▼──────────────────┐
                    │   Context Assembly           │
                    │   ┌─────────────────────┐    │
                    │   │ Memory Search        │    │
                    │   │ (past voice convos)  │    │
                    │   ├─────────────────────┤    │
                    │   │ Claude Memory Files   │    │
                    │   │ (.claude/projects/)   │    │
                    │   ├─────────────────────┤    │
                    │   │ Calendar Context      │    │
                    │   │ (today's events)      │    │
                    │   ├─────────────────────┤    │
                    │   │ Session History       │    │
                    │   │ (current convo turns) │    │
                    │   └─────────────────────┘    │
                    └──────────┬──────────────────┘
                               │ enriched prompt
                    ┌──────────▼──────────────────┐
                    │   Claude API                 │
                    │   (claude-sonnet-4-6)     │
                    │   System prompt + context    │
                    │   + conversation history     │
                    └──────────┬──────────────────┘
                               │ response text
                    ┌──────────▼──────────────────┐
                    │   Text-to-Speech             │
                    │   (Piper / Kokoro local)     │
                    └──────────┬──────────────────┘
                               │ audio
                    ┌──────────▼──────────────────┐
                    │   Speaker output             │
                    └──────────┬──────────────────┘
                               │
                    ┌──────────▼──────────────────┐
                    │   Conversation Persistence   │
                    │   (SQLite + embeddings)      │
                    └─────────────────────────────┘
```

---

## Memory Layers

### Layer 1: Session Memory
- Current conversation turns (user + assistant)
- Kept in memory, saved to SQLite when session ends or after each turn
- Last 10 turns always included in API context

### Layer 2: Persistent Voice Memory (SQLite)
- Every voice conversation ever, timestamped
- Columns: timestamp, speaker (Clay/Jaz/unknown), transcript, response, embedding
- Semantic search via sentence-transformer embeddings
- Top 3-5 relevant past exchanges included in each API call

### Layer 3: Claude Code Memory
- Read from: ~/.claude/projects/C--Users-shelc/memory/*.md
- User identity, ADHD context, project status, preferences, feedback rules
- Loaded into system prompt at startup, refreshed every 30 minutes

### Layer 4: Live Context
- Today's Google Calendar events (via local cache or API)
- Active Google Tasks
- Time of day (adjust tone: morning briefing vs late-night casual)
- Day of week (class day? drill day? deep work day?)

---

## File Structure

```
clay-voice/
├── ARCHITECTURE.md          # This file
├── requirements.txt         # Python dependencies
├── config.yaml              # API keys, paths, preferences
├── main.py                  # Entry point — wake word → listen → respond loop
├── stt.py                   # Speech-to-text module
├── tts.py                   # Text-to-speech module
├── wake.py                  # Wake word detection
├── brain.py                 # Claude API + context assembly
├── memory.py                # SQLite persistence + embedding search
├── context.py               # Calendar, tasks, Claude memory file reader
├── audio.py                 # Microphone input / speaker output utilities
├── models/                  # Local model files (whisper, TTS, wake word)
│   └── .gitkeep
├── data/
│   ├── conversations.db     # SQLite database of all voice conversations
│   └── embeddings.npy       # Cached embeddings (optional, for fast search)
└── prompts/
    └── system.md            # System prompt template for the voice agent
```

---

## System Prompt Strategy

The system prompt is assembled dynamically before each API call:

```
[IDENTITY BLOCK]
You are Clay's personal voice assistant. You know him well.
{loaded from memory/user_identity.md}
{loaded from memory/user_adhd_routines.md}

[MEMORY BLOCK]
Here are relevant past voice conversations:
{top 3-5 semantic matches from SQLite}

[CONTEXT BLOCK]
Today is {date}, {day_of_week}. Time: {time}.
Today's calendar: {events}
Active tasks: {top priority tasks}

[CONVERSATION BLOCK]
Recent conversation:
{last 10 turns}

[BEHAVIOR RULES]
- Be conversational, warm, and concise
- Reference past conversations naturally ("Last week you mentioned...")
- Proactively surface relevant reminders ("By the way, you have drill prep tomorrow")
- If Jaz is speaking (detect by context/voice), adjust tone — be friendly but less project-focused
- Keep responses under 30 seconds of speech (~75 words) unless asked to elaborate
- For complex questions, offer to "send details to your phone/email" instead of reading a wall of text
```

---

## Model Selection

- **Voice conversations:** claude-sonnet-4-6 (fast, cheap, good enough for spoken Q&A)
- **Complex research:** claude-opus-4-6 (only if explicitly requested or detected as complex)
- **Embeddings:** all-MiniLM-L6-v2 (384-dim, fast, local, free)

---

## Jaz Mode

If the system detects a different speaker pattern (or Clay says "Jaz mode"):
- Reduce technical jargon
- Don't reference SOK, PhD research, or military context
- Focus on: household, calendar, recipes, weather, general knowledge
- Warmer, more casual tone

---

## Cost Estimate

At home conversational rates (~50-200 exchanges/day):
- Claude API (Sonnet): ~$0.10-0.50/day ($3-15/month)
- All other components: $0 (local processing)
- Max subscription may include API credits — verify
```
