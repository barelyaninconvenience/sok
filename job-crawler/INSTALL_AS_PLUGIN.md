# Installing the Overemployment Pipeline as a Claude Code Plugin

The pipeline is structured as a Claude Code plugin. You can use it as scripts directly, OR register it as a local plugin for portability across sessions.

## Structure

```
scripts/job-crawler/
├── .claude-plugin/
│   └── plugin.json             # Plugin metadata (Anthropic spec)
├── skills/
│   └── overemployment-job-filter/
│       └── SKILL.md            # The 6-dimension rubric as a Skill
├── commands/
│   ├── score-job.md            # /score-job slash command
│   ├── shortlist.md            # /shortlist slash command
│   └── generate-cover-letter.md # /generate-cover-letter slash command
├── lib/                        # Python modules
├── bin/                        # Python CLI tools
├── data/                       # DB, raw scrapes, shortlists, cover letters
├── README.md
├── BATCH_RUN.md                # How to run the 1000-job Handshake batch
├── run_batch.ps1               # Orchestration script
├── schema.sql
├── rubric.md
└── requirements.txt
```

## Install as a plugin (local)

From Claude Code, add this directory as a plugin marketplace:

```
/plugin marketplace add C:\Users\shelc\Documents\Journal\Projects\scripts\job-crawler
```

Then browse or install:

```
/plugin install overemployment-pipeline
```

After install, the slash commands become available:

- `/score-job` — Score a pasted job posting
- `/shortlist` — Export the current shortlist
- `/generate-cover-letter` — Tailored application letter

The Skill (`overemployment-job-filter`) is automatically loaded and invoked whenever Claude detects a job-filtering task.

## Install as a plugin (published)

If you publish the plugin to a GitHub repo (e.g., `barelyaninconvenience/overemployment-pipeline`):

```
/plugin marketplace add barelyaninconvenience/overemployment-pipeline
/plugin install overemployment-pipeline
```

Other machines can then install the same plugin with a single command.

## Not installing as a plugin

You don't have to. The Python pipeline at `scripts/job-crawler/` runs standalone:

```bash
cd scripts/job-crawler
python bin/scrape.py --source remoteok --limit 50 --init-db
python bin/dry_score.py
python bin/score.py --model claude-sonnet-4-6
python bin/shortlist.py --min-score 9
```

The plugin layer adds slash commands + a Skill for the rubric. Both are optional.

## Why package as a plugin

- **Portability**: one install command gets the whole toolkit.
- **Discoverability**: slash commands appear in Claude Code's command menu.
- **Rubric encapsulation**: the Skill codifies the 6-dimension scoring so the rubric stays consistent across sessions + machines.
- **Future extension**: add MCP servers (`.mcp.json`), more skills (cover-letter-voice-matcher, company-research, salary-negotiator), more commands.

## Relationship to the broader Operating Stack

Per Clay's `Operating_Stack_v1` + meticul.OS direction, this plugin is a concrete instance of the packaging pattern. If meticul.OS eventually ships as a coherent rebrand, each tool in the stack (SOK, job crawler, session-close protocol, ENDEAVOR sweep) could be its own plugin under a meticul.OS marketplace.
