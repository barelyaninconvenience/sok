# Kaggle Dataset Ingest

Adds Kaggle job-postings datasets as a source. Useful when a curated dataset is
already available (MIT-licensed, redistributable) rather than scraping live.

## Setup (one-time)

1. Install Kaggle CLI (already in requirements.txt):
   ```bash
   pip install kaggle
   ```

2. Get API credentials:
   - Go to https://www.kaggle.com/settings
   - Scroll to **API** → **Create New API Token**
   - Download `kaggle.json`

3. Place credentials at `~/.kaggle/kaggle.json` (Windows: `%USERPROFILE%\.kaggle\kaggle.json`):
   ```powershell
   New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.kaggle" | Out-Null
   Move-Item -Path "$env:USERPROFILE\Downloads\kaggle.json" -Destination "$env:USERPROFILE\.kaggle\kaggle.json" -Force
   ```

4. Verify:
   ```bash
   kaggle datasets list --search "jobs remote" | head
   ```

## Usage

### Clay's referenced dataset

```bash
cd scripts/job-crawler
python bin/ingest_kaggle.py --dataset jessysisca/job-descriptions-and-remote-task-descriptions
```

The ingester:
1. Downloads the dataset zip to `data/kaggle/<dataset-slug>/`.
2. Unzips.
3. Detects the primary CSV/JSON file.
4. Auto-maps columns using the `DEFAULT_COLUMN_MAP` in `lib/sources/kaggle_dataset.py` (tries `job_title` → `title` → `position`, etc.).
5. Inserts each row as a normalized job with `source="kaggle:<dataset-slug>"`.

### Custom column mapping

If the auto-detect doesn't match your dataset's schema:

```bash
python bin/ingest_kaggle.py \
  --dataset OWNER/DATASET \
  --column-map '{"title":"RoleName","company":"CompanyName","description":"FullDescription","pay":"AnnualSalary"}'
```

### Limit for testing

```bash
python bin/ingest_kaggle.py --dataset OWNER/DATASET --limit 50
```

## After ingest

The jobs are in the same DB as the live-scraped ones. Run the normal pipeline:

```bash
python bin/dry_score.py        # free heuristic scoring
python bin/score.py            # LLM scoring (costs API credits)
python bin/dedupe.py           # detect duplicates across sources
python bin/shortlist.py --min-score 9
```

## Why Kaggle ingest matters

- **Offline eval**: scoring a static dataset gives you a stable corpus to tune the rubric against
- **Training data**: a large Kaggle corpus can be used to prompt-tune or evaluate the dry-score heuristic
- **Benchmark**: compare what the rubric says about a broad real-world job-posting corpus vs. just your scraped set
- **Redistributable**: MIT-licensed Kaggle datasets can be redistributed, unlike scraped Handshake/LinkedIn data

## Dataset signals to evaluate before ingesting

Before committing to a Kaggle dataset:

- **License**: MIT / CC0 / CC-BY = fine. Non-commercial or proprietary = check before using for any public work.
- **Recency**: datasets more than 2-3 years old may not reflect current pay norms, remote-work conventions, or posting-format evolution.
- **Size**: 10k+ rows gives the rubric room to find range; under 1k is boutique.
- **Geography**: US-only vs. global affects pay-range interpretation.
- **Source**: was it scraped from LinkedIn? Indeed? Manually curated? Different sources have different structural quirks.

## Dataset: jessysisca/job-descriptions-and-remote-task-descriptions

**License**: MIT (confirmed from Kaggle page)
**Author**: JessySisca
**Description**: "Job descriptions and remote task descriptions" (minimal public metadata)

**Expected schema** (to be confirmed after first ingest — the auto-mapper will attempt title/company/description/pay fields):

The specific focus on **remote task descriptions** as a separate field is unusual and potentially valuable — it suggests the dataset may distinguish between the job's listed responsibilities and the remote-specific task execution details. If that's the case, it's especially useful for the automatability dimension of the rubric: tasks that are remote-specific often expose the degree of asynchrony and AI-automability directly.

First ingest: run with `--limit 50` to inspect column names, then tune the column-map for a full run.
