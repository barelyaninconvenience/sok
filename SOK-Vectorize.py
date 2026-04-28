#!/usr/bin/env python3
"""
SOK-Vectorize.py — Project directory chunker for AIML retrieval.

Walks the project tree, extracts text from source files, and writes
overlapping chunks to a JSONL index. Designed for RAG/context retrieval
in Claude Code sessions and future embedding pipelines.

CHUNKING STRATEGY:
  Files <= SMALL_FILE_LINES: one chunk (the whole file)
  Files  > SMALL_FILE_LINES: sliding window — CHUNK_CHARS chars, OVERLAP_CHARS overlap

OUTPUT:
  <output_dir>/chunks.jsonl        — one JSON object per line, one chunk per object
  <output_dir>/manifest.json       — file mtimes; drives incremental updates
  <output_dir>/summary.txt         — human-readable run summary

CHUNK SCHEMA:
  id            str   sha1(source + chunk_idx)
  source        str   relative path from project root
  extension     str   .ps1 / .py / .md / etc.
  chunk_idx     int   0-based index within file
  total_chunks  int   total chunks for this file
  line_start    int   1-based first line of chunk
  line_end      int   1-based last line of chunk
  char_start    int   byte offset start in file
  char_end      int   byte offset end in file
  content       str   the actual text
  mtime         float file modification time (epoch)
  size_bytes    int   full file size

USAGE:
  python SOK-Vectorize.py                   # full run, default paths
  python SOK-Vectorize.py --dry-run         # preview: list files, no writes
  python SOK-Vectorize.py --incremental     # skip files unchanged since last run
  python SOK-Vectorize.py --search "InfraFix junction" --top 5
  python SOK-Vectorize.py --output C:\\custom\\path

NOTES:
  Author:  S. Clay Caddell
  Version: 1.0.0
  Date:    2026-04-03
  Domain:  Utility — recurrent project chunker; feeds AIML retrieval
  Python:  3.14 (py -3.14 SOK-Vectorize.py)
  Schedule: weekly via Task Scheduler or on-demand before context-heavy sessions
"""

import argparse
import hashlib
import json
import os
import re
import sys
import time
from datetime import datetime
from pathlib import Path

# ── configuration ─────────────────────────────────────────────────────────────

# Files larger than this get sliding-window chunked; smaller get one chunk each
SMALL_FILE_LINES = 80

# Sliding window parameters (chars, not tokens — ~4 chars/token average)
CHUNK_CHARS   = 2000   # ~500 tokens per chunk
OVERLAP_CHARS = 200    # ~50 token overlap between adjacent chunks

# Included extensions (anything not in this set is skipped)
INCLUDE_EXTS = {
    '.ps1', '.psm1', '.psd1',
    '.py',
    '.md',
    '.json',
    '.yaml', '.yml',
    '.ts', '.tsx', '.js', '.jsx',
    '.go', '.rs', '.sh', '.bat', '.cmd',
    '.sql', '.r',
    '.txt', '.cfg', '.ini', '.toml', '.conf',
    '.css', '.html',
    '.ahk',
}

# Skip any path component matching these patterns
EXCLUDE_PATTERNS = re.compile(
    r'(?ix)'
    r'[\\/](Deprecated|\.git|__pycache__|node_modules|\.venv|venv|env|'
    r'dist|build|\.mypy_cache|\.pytest_cache|\.tox|'
    r'Logs|Transcripts|Archives|_bak|_old)[\\/]'
    r'|[\\/]\.'      # hidden files/dirs
)

# Skip files larger than this (bytes) — large JSON data dumps, etc.
#
# MEDIUM-7 fix 2026-04-22: previous flat 500KB cap excluded legitimate
# SOK_Inventory_*.json outputs (often >500KB) and session transcripts — the
# very artifacts RAG retrieval most needs. Raised the default to 2MB which
# covers typical SOK inventory + session-transcript sizes while still
# excluding pathological data dumps (multi-MB JSON arrays, vendored assets).
#
# Operator override: set SOK_VECTORIZE_MAX_FILE_BYTES env var to any integer
# byte value (or "0" for no limit). Example:
#   $env:SOK_VECTORIZE_MAX_FILE_BYTES = '5000000'   # 5 MB
#   py -3.14 SOK-Vectorize.py
#
# Per-extension caps: could be added later if a single blanket value proves
# insufficient. For now, env-var-tunable is the minimal non-breaking change.
_DEFAULT_MAX_FILE_BYTES = 2_000_000   # 2 MB — up from prior 500KB
_env_override = os.environ.get("SOK_VECTORIZE_MAX_FILE_BYTES", "").strip()
if _env_override:
    try:
        _parsed = int(_env_override)
        MAX_FILE_BYTES = _parsed if _parsed > 0 else float("inf")
    except ValueError:
        print(f"[WARN] SOK_VECTORIZE_MAX_FILE_BYTES={_env_override!r} not an int; using default {_DEFAULT_MAX_FILE_BYTES}", file=sys.stderr)
        MAX_FILE_BYTES = _DEFAULT_MAX_FILE_BYTES
else:
    MAX_FILE_BYTES = _DEFAULT_MAX_FILE_BYTES

# Skip files that look like binary
BINARY_SIGNATURES = [b'\x00', b'\xff\xfe', b'\xfe\xff', b'\xef\xbb\xbf\x00']

# Default paths
# Note: SOK boundary per CLAUDE.md §2 — only SOK\Logs\ accepts writes.
# Prior path SOK\Chunks\ violated this; moved to SOK\Logs\Vectorize\.
DEFAULT_PROJECT_ROOT = Path(r'C:\Users\shelc\Documents\Journal\Projects')
DEFAULT_OUTPUT_DIR   = DEFAULT_PROJECT_ROOT / 'SOK' / 'Logs' / 'Vectorize'


# ── helpers ───────────────────────────────────────────────────────────────────

def chunk_id(source: str, chunk_idx: int) -> str:
    return hashlib.sha1(f'{source}::{chunk_idx}'.encode()).hexdigest()[:12]


def is_likely_binary(path: Path) -> bool:
    try:
        with open(path, 'rb') as f:
            head = f.read(512)
        # Null bytes anywhere in first 512 = binary
        return b'\x00' in head
    except OSError:
        return True


def read_text(path: Path) -> str | None:
    for enc in ('utf-8', 'utf-8-sig', 'latin-1'):
        try:
            return path.read_text(encoding=enc, errors='strict')
        except (UnicodeDecodeError, ValueError):
            continue
    return None


def should_skip(path: Path) -> bool:
    path_str = str(path)
    if EXCLUDE_PATTERNS.search(path_str):
        return True
    if path.suffix.lower() not in INCLUDE_EXTS:
        return True
    try:
        if path.stat().st_size > MAX_FILE_BYTES:
            return True
        if path.stat().st_size == 0:
            return True
    except OSError:
        return True
    if is_likely_binary(path):
        return True
    return False


def sliding_chunks(text: str, chunk_chars: int, overlap_chars: int) -> list[tuple[int, int]]:
    """Return list of (char_start, char_end) byte ranges for sliding window."""
    ranges = []
    start = 0
    length = len(text)
    while start < length:
        end = min(start + chunk_chars, length)
        ranges.append((start, end))
        if end == length:
            break
        start += chunk_chars - overlap_chars
    return ranges


def char_to_line(text: str, char_pos: int) -> int:
    """Return 1-based line number for char_pos in text."""
    return text[:char_pos].count('\n') + 1


def make_chunks(source_rel: str, text: str, mtime: float, size_bytes: int) -> list[dict]:
    lines = text.splitlines()
    ext = Path(source_rel).suffix.lower()

    if len(lines) <= SMALL_FILE_LINES:
        # Single chunk
        return [{
            'id':           chunk_id(source_rel, 0),
            'source':       source_rel,
            'extension':    ext,
            'chunk_idx':    0,
            'total_chunks': 1,
            'line_start':   1,
            'line_end':     len(lines),
            'char_start':   0,
            'char_end':     len(text),
            'content':      text,
            'mtime':        mtime,
            'size_bytes':   size_bytes,
        }]

    ranges = sliding_chunks(text, CHUNK_CHARS, OVERLAP_CHARS)
    total = len(ranges)
    result = []
    for idx, (cs, ce) in enumerate(ranges):
        snippet = text[cs:ce]
        result.append({
            'id':           chunk_id(source_rel, idx),
            'source':       source_rel,
            'extension':    ext,
            'chunk_idx':    idx,
            'total_chunks': total,
            'line_start':   char_to_line(text, cs),
            'line_end':     char_to_line(text, ce - 1),
            'char_start':   cs,
            'char_end':     ce,
            'content':      snippet,
            'mtime':        mtime,
            'size_bytes':   size_bytes,
        })
    return result


# ── search ────────────────────────────────────────────────────────────────────

def search_chunks(chunks_path: Path, query: str, top_n: int = 5) -> None:
    """Simple keyword search over chunks.jsonl. Scores by term frequency."""
    if not chunks_path.exists():
        print(f'[ERROR] chunks.jsonl not found at {chunks_path}', file=sys.stderr)
        print('  Run without --search first to generate the index.', file=sys.stderr)
        sys.exit(1)

    terms = re.compile(
        '|'.join(re.escape(t) for t in query.split()),
        re.IGNORECASE
    )

    scored: list[tuple[int, dict]] = []
    with open(chunks_path, encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                chunk = json.loads(line)
            except json.JSONDecodeError:
                continue
            hits = len(terms.findall(chunk.get('content', '')))
            if hits > 0:
                scored.append((hits, chunk))

    scored.sort(key=lambda x: x[0], reverse=True)
    results = scored[:top_n]

    if not results:
        print(f'No results for: {query}')
        return

    print(f'\n-- Search: "{query}" -- top {len(results)} results --\n')
    for score, chunk in results:
        # Encode-safe printing for Windows cp1252 terminal
        header = f'  [{score} hits] {chunk["source"]}  lines {chunk["line_start"]}-{chunk["line_end"]}  (chunk {chunk["chunk_idx"]+1}/{chunk["total_chunks"]})'
        print(header.encode('ascii', errors='replace').decode('ascii'))
        snippet = chunk['content'][:300].replace('\n', ' ').strip()
        print(f'  {snippet.encode("ascii", errors="replace").decode("ascii")}')
        print()


# ── main run ──────────────────────────────────────────────────────────────────

def _acquire_vectorize_lock(output_dir: Path) -> Path | None:
    """HIGH-8 fix 2026-04-21: concurrent-run guard.

    Two concurrent invocations (scheduled + on-demand) both open chunks.jsonl
    in 'w' mode; Windows file handles are not cooperatively locked, so writes
    interleave and corrupt the JSONL. This helper writes PID + timestamp to
    output_dir/.vectorize.lock and refuses to proceed if a fresh (<15min old)
    lock with a live PID is present. Stale locks are reclaimed automatically.

    Returns the lock path on successful acquisition, or None if blocked.
    """
    import errno as _errno
    LOCK_STALE_SEC = 900  # 15 minutes
    lock_path = output_dir / '.vectorize.lock'

    def _lock_is_stale(p: Path) -> bool:
        try:
            age = time.time() - p.stat().st_mtime
            if age > LOCK_STALE_SEC:
                return True
            try:
                with open(p, 'r', encoding='utf-8') as lf:
                    owning_pid = int(lf.readline().strip().split(':', 1)[0])
                os.kill(owning_pid, 0)
                return False
            except (ValueError, ProcessLookupError, PermissionError):
                return True
            except OSError as e:
                if e.errno in (_errno.EINVAL, _errno.ESRCH):
                    return True
                return False
        except OSError:
            return False

    if lock_path.exists() and not _lock_is_stale(lock_path):
        print(f'[ABORT] Another vectorize run appears active: {lock_path} — refusing to proceed '
              f'(would corrupt JSONL). Remove the lockfile if you confirmed no other run is executing.')
        return None
    try:
        with open(lock_path, 'w', encoding='utf-8') as lf:
            lf.write(f'{os.getpid()}:{datetime.now().isoformat()}\n')
    except OSError as e:
        print(f'[WARN] Lockfile create failed ({e}) — proceeding without lock; concurrent-run risk present')
        return None
    return lock_path


def _release_vectorize_lock(lock_path: Path | None) -> None:
    if lock_path is None:
        return
    try:
        lock_path.unlink(missing_ok=True)
    except OSError:
        pass


def run(project_root: Path, output_dir: Path, dry_run: bool, incremental: bool, verbose: bool) -> None:
    manifest_path = output_dir / 'manifest.json'
    chunks_path   = output_dir / 'chunks.jsonl'
    summary_path  = output_dir / 'summary.txt'

    # HIGH-8 fix 2026-04-21: acquire lock BEFORE any output-dir work.
    # Dry-run skips locking because it never writes chunks.jsonl.
    lock_path: Path | None = None
    if not dry_run:
        output_dir.mkdir(parents=True, exist_ok=True)
        lock_path = _acquire_vectorize_lock(output_dir)
        if lock_path is None:
            return  # lock acquisition failed and printed its own reason

    # Load prior manifest for incremental
    prior_manifest: dict[str, float] = {}
    if incremental and manifest_path.exists():
        try:
            prior_manifest = json.loads(manifest_path.read_text(encoding='utf-8'))
            print(f'[Incremental] Loaded manifest: {len(prior_manifest)} prior files')
        except (json.JSONDecodeError, OSError):
            print('[Incremental] Manifest unreadable — full reindex')

    if not dry_run:
        output_dir.mkdir(parents=True, exist_ok=True)

    # Walk and collect
    all_files: list[Path] = []
    skipped_count = 0
    for dirpath, dirnames, filenames in os.walk(project_root):
        dp = Path(dirpath)
        # Prune excluded dirs in-place to avoid descending
        dirnames[:] = [
            d for d in dirnames
            if not EXCLUDE_PATTERNS.search(str(dp / d) + '\\')
        ]
        for fname in filenames:
            fp = dp / fname
            if should_skip(fp):
                skipped_count += 1
                continue
            all_files.append(fp)

    all_files.sort()

    # Filter to changed files if incremental
    if incremental and prior_manifest:
        to_process = []
        unchanged = 0
        for fp in all_files:
            rel = str(fp.relative_to(project_root))
            try:
                mtime = fp.stat().st_mtime
            except OSError:
                continue
            if prior_manifest.get(rel) == mtime:
                unchanged += 1
            else:
                to_process.append(fp)
        print(f'[Incremental] {unchanged} unchanged, {len(to_process)} to process')
    else:
        to_process = all_files

    print(f'Files to process: {len(to_process)}  (skipped: {skipped_count})')

    if dry_run:
        print('\n[DRY RUN] Would process:')
        for fp in to_process[:50]:
            rel = fp.relative_to(project_root)
            try:
                size = fp.stat().st_size
                # LOW-6 fix 2026-04-22: previously read_text().splitlines() loaded
                # the entire file into memory for the line count. With MAX_FILE_BYTES
                # now 2MB (up from 500KB), a pathological file near the cap would
                # allocate 2-8x its size in Python string objects. Streaming line
                # count is O(1) memory regardless of file size.
                lines = 0
                with open(fp, 'r', encoding='utf-8', errors='replace') as _f:
                    for _ in _f:
                        lines += 1
                print(f'  {rel}  ({size:,}B, {lines} lines)')
            except OSError:
                print(f'  {rel}  (unreadable)')
        if len(to_process) > 50:
            print(f'  ... and {len(to_process) - 50} more')
        print(f'\n[DRY RUN] No files written. Output would go to: {output_dir}')
        return

    # Process
    run_start     = time.time()
    total_chunks  = 0
    total_files   = 0
    new_manifest  = dict(prior_manifest)  # start from prior; update touched files
    errors: list[str] = []

    # In incremental mode, preserve prior chunks for unchanged files
    # We rebuild the full JSONL: prior unchanged + newly processed
    prior_unchanged_chunks: list[str] = []
    if incremental and prior_manifest and chunks_path.exists():
        unchanged_sources = set()
        for fp in all_files:
            rel = str(fp.relative_to(project_root))
            try:
                mtime = fp.stat().st_mtime
            except OSError:
                continue
            if prior_manifest.get(rel) == mtime:
                unchanged_sources.add(rel.replace('\\', '/'))
                unchanged_sources.add(rel)

        with open(chunks_path, encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    c = json.loads(line)
                    if c.get('source', '').replace('\\', '/') in unchanged_sources or \
                       c.get('source', '') in unchanged_sources:
                        prior_unchanged_chunks.append(line)
                        total_chunks += 1
                except json.JSONDecodeError:
                    pass

    with open(chunks_path, 'w', encoding='utf-8') as out:
        # Write preserved chunks first
        for line in prior_unchanged_chunks:
            out.write(line + '\n')

        # Process new/changed files
        for fp in to_process:
            rel = str(fp.relative_to(project_root))
            try:
                stat   = fp.stat()
                mtime  = stat.st_mtime
                size   = stat.st_size
                text   = read_text(fp)
                if text is None:
                    errors.append(f'encoding error: {rel}')
                    continue
                chunks = make_chunks(rel, text, mtime, size)
                for chunk in chunks:
                    out.write(json.dumps(chunk, ensure_ascii=False) + '\n')
                total_chunks += len(chunks)
                total_files  += 1
                new_manifest[rel] = mtime
                if verbose:
                    print(f'  {rel}  → {len(chunks)} chunk(s)')
            except OSError as e:
                errors.append(f'OS error {rel}: {e}')

    # Write manifest
    manifest_path.write_text(json.dumps(new_manifest, indent=2), encoding='utf-8')

    elapsed = time.time() - run_start
    ts      = datetime.now().strftime('%Y-%m-%d %H:%M:%S')

    summary = (
        f'SOK-Vectorize run: {ts}\n'
        f'  Project root:  {project_root}\n'
        f'  Output dir:    {output_dir}\n'
        f'  Mode:          {"incremental" if incremental else "full"}\n'
        f'  Files walked:  {len(all_files):,}\n'
        f'  Files indexed: {total_files:,}\n'
        f'  Total chunks:  {total_chunks:,}\n'
        f'  JSONL size:    {chunks_path.stat().st_size:,} bytes\n'
        f'  Elapsed:       {elapsed:.1f}s\n'
        f'  Errors:        {len(errors)}\n'
    )
    if errors:
        summary += '  Error list:\n'
        for e in errors[:20]:
            summary += f'    {e}\n'

    summary_path.write_text(summary, encoding='utf-8')
    print(summary)

    # HIGH-8 fix 2026-04-21: release concurrent-run lock at clean exit
    _release_vectorize_lock(lock_path)


# ── entry point ───────────────────────────────────────────────────────────────

def main() -> None:
    parser = argparse.ArgumentParser(
        description='SOK-Vectorize: chunk project files for AIML retrieval',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument('--root',        default=str(DEFAULT_PROJECT_ROOT),
                        help=f'Project root to walk (default: {DEFAULT_PROJECT_ROOT})')
    parser.add_argument('--output',      default=str(DEFAULT_OUTPUT_DIR),
                        help=f'Output directory for chunks.jsonl (default: {DEFAULT_OUTPUT_DIR})')
    parser.add_argument('--dry-run',     action='store_true',
                        help='Preview files to process without writing anything')
    parser.add_argument('--incremental', action='store_true',
                        help='Only reprocess files changed since last run')
    parser.add_argument('--verbose',     action='store_true',
                        help='Print each file as it is processed')
    parser.add_argument('--search',      metavar='QUERY',
                        help='Keyword search over existing chunks.jsonl (space-separated terms OR\'d by hits)')
    parser.add_argument('--top',         type=int, default=5,
                        help='Number of results for --search (default: 5)')
    parser.add_argument('--chunk-chars', type=int, default=CHUNK_CHARS,
                        help=f'Characters per sliding-window chunk (default: {CHUNK_CHARS})')
    parser.add_argument('--overlap',     type=int, default=OVERLAP_CHARS,
                        help=f'Overlap chars between chunks (default: {OVERLAP_CHARS})')

    args = parser.parse_args()

    project_root = Path(args.root).resolve()
    output_dir   = Path(args.output).resolve()

    if not project_root.exists():
        print(f'[ERROR] Project root not found: {project_root}', file=sys.stderr)
        sys.exit(1)

    # Search mode
    if args.search:
        search_chunks(output_dir / 'chunks.jsonl', args.search, args.top)
        return

    # Update module-level chunk params if CLI overrides were given
    globals()['CHUNK_CHARS']   = args.chunk_chars
    globals()['OVERLAP_CHARS'] = args.overlap

    run(
        project_root = project_root,
        output_dir   = output_dir,
        dry_run      = args.dry_run,
        incremental  = args.incremental,
        verbose      = args.verbose,
    )


if __name__ == '__main__':
    main()
