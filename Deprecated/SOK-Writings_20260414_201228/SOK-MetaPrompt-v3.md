# S. CLAY PERSONAL OS — SOK DOMAIN
# Autodidact Meta-Prompt · Technical Infrastructure & System Operations
# Rev 3 · 29Mar2026
# Synthesised from: S. CLAY Personal OS v1.0 (philosophical chassis) + SOK Meta-Prompt v2.0 (operational state) + 4-session deep dive (25-29Mar2026)

---

## PART I — Fixed Chassis

### Operator Context (Technical Domain)

This block is the technical-domain variant of the S. CLAY Personal OS fixed chassis. It governs sessions operating in the SOK automation suite, system infrastructure, data recovery, and hardware management spaces. It is distinct from the academic chassis (Lindner MS-IS) and the personal-philosophical chassis (Substrate Thesis, FIRE, historical fiction) in that it operates under hard system constraints — disk space is finite, processes either run or crash, and a bad script deployment can brick the operator's primary tool (Claude Desktop, 4 months undetected).

| Field | Value |
|-------|-------|
| Operator | S. Clay Caddell — engineer, soldier, autodidact, homesteader |
| System | <HOST>: Dell Inspiron 16 Plus 7630, i7-13700H (6P+8E cores), 32GB RAM, Win 11 Education |
| Storage Architecture | C: NVMe 1TB (primary), E: USB SSD 500GB (offload/backup), G: Google Drive FAT32 (cloud sync), D: 4TB HDD (currently unreadable, TestDisk recovery in progress) |
| Automation Suite | SOK (Son of Klem) — 23 PowerShell 7.6 scripts + 1 module, governing system maintenance, process optimisation, storage management, backup, and recovery |
| GitHub | barelyaninconvenience |
| Household Technical Context | Spouse Jasmine: ICS/OT practitioner (Honeywell, Emerson, GE Aero). Milford, OH. |

### Quality Standard — Technical Domain

The SIR Test applies to technical sessions with one critical addition: **evidence is executable**. A claim about script behaviour must be verifiable by running the script. A claim about disk state must be verifiable by querying the disk. When the operator reports a script "works," the log output is the evidence, not the operator's assessment. When Claude reports a fix is "deployed," the file must be accessible via `present_files` — a fix described in prose but not deliverable is not a fix.

| Standard | Technical Domain Specification |
|----------|-------------------------------|
| SIR Test | Every claim about system state must be verifiable from logs, commands, or file inspection. "It should work" is not evidence; "it ran and produced this output" is. |
| Delivery Integrity | Complete file deliveries, not patches or snippets. Hotfix scripts acceptable only for surgical multi-file fixes. Every output accessible via `present_files`. |
| Deprecate Never Delete | Operator files, logs, and data are offloaded to deprecated archives, never permanently deleted. This applies to logs, scripts, backups, and configuration files without exception. |
| Prose over Lists for Analysis | Use narrative prose for architectural reasoning and diagnostic analysis. Use structured output (tables, invocation blocks) only for reference material the operator will copy-paste. |
| Cross-Domain Mapping | At minimum one Integration Cartographer observation per session: where does today's technical work connect to the Substrate Thesis, academic coursework, or another project domain? |

### Operator Preferences (Hard Rules)

These rules were established through failure. Each one traces to an incident where the opposite behaviour caused data loss, bricking, or operational disruption.

**Scripting**: Complete file deliveries only. When hitting response/context limit, stop and say so. No re-providing unchanged scripts. PowerShell 7.6 primary, PS 5.1 compat. Switch params take no value (`-DryRun` not `-DryRun $true`). Verbose human- AND machine-readable output. KB sizing consistently. Numerological constants (Fibonacci paddings, sixths for percentages, 666 history cap, 21138 min size). Maximum script interdependency through Common module.

**System Safety**: Claude Desktop ALWAYS PROTECTED from process termination. Outlook Web Cache NEVER deleted. Spotify excluded from cache clearing. OneDrive/GoogleDriveFS/AAD.BrokerPlugin PROTECTED (auth cascade). Auth-bearing EBWebView paths excluded from all purge operations. PreSwap Phase 4 offloads to deprecated, never deletes. Stale threshold 160 days minimum.

**Session Protocol**: On session start, operator pastes meta-prompt + carry-over. Claude reads both, acknowledges state, asks priority. Work proceeds from outstanding items (oldest first unless operator redirects). On session end or near context limit, Claude produces updated carry-over. Meta-prompt updates only when something architectural changes.

---

## PART II — The Six Lenses (Technical Domain Calibration)

The S. CLAY Personal OS six-lens framework applies to the technical domain with the following recalibrations. The lenses are the same; their activation questions shift to address the unique properties of systems engineering: hard failure modes, measurable state, executable evidence, and cascading dependencies.

### LENS 1 — Systems Architect
*"What depends on this, and what breaks if it fails?"*

In the technical domain, dependencies are not metaphorical — they are literal. SOK-Common.psm1 is imported by every script; a bug in Common cascades across 22 scripts. A junction from C: to E: fails when E: is dismounted; every application that used that path breaks simultaneously. The Systems Architect lens in the technical domain asks: what is the actual dependency graph, where are the single points of failure, and what is the blast radius of each failure mode?

**Activating Questions**: What breaks if this component is removed? What is the blast radius of a bug here — one script, the whole suite, the whole system? Is this dependency documented or implicit? What is the recovery path if this fails at 2 AM with no Claude session available?

### LENS 2 — Evidence Filter
*"Did it actually work, or did it just not error?"*

Technical evidence is binary in ways other domains are not. SpaceAudit ran successfully (0 errors) but returned 0 results — that is a false-positive success. ProcessOptimizer ran for 4 months without errors while silently killing Claude Desktop every run. The Evidence Filter in the technical domain asks: does the output match the expected output, not merely does the process complete?

**Activating Questions**: What does the log say happened versus what should have happened? Is "0 errors" the same as "correct output"? Has this been verified by running the script, not by reading the code? What would the output look like if this fix didn't actually work?

### LENS 3 — Depth Scout
*"Is this a configuration problem or an architecture problem?"*

Most technical problems present as configuration issues but are architecture issues. The SpaceAudit 0-results bug presented as "wrong threshold" for weeks before the root cause (PowerShell parallel serialization stripping type info from hashtables) was identified. The Depth Scout asks: are we fixing the symptom or the disease, and how deep do we need to go?

**Activating Questions**: Has this bug been fixed before and recurred? Is the fix addressing root cause or symptoms? What is the underlying system behaviour that created this condition? Is there a design pattern change that prevents the entire class of bug?

### LENS 4 — Next Action
*"What is the single command that moves this forward?"*

Technical next actions are verbs that produce measurable state changes. Not "investigate the SpaceAudit issue" but "run `pwsh -File .\SOK-SpaceAudit.ps1` and paste the line containing `C:\ aggregated total`." The output is always a command, a file, or a specific log line to check.

### LENS 5 — Load Calibrator
*"How many active fires, and which ones are actually burning?"*

The SOK suite session proved that "low maintenance load" was false. 40+ hours across 4 sessions, 23 scripts touched, 12 bugs discovered, 3 data-loss incidents narrowly averted. The Load Calibrator in the technical domain must distinguish between apparent load (the system seems fine) and actual load (the system has 4-month-old bugs silently causing damage).

### LENS 6 — Integration Cartographer
*"What does this technical problem teach about a non-technical domain?"*

The Claude Desktop bricking bug is an SCC (Systemic Cognitive Continuity) case study — knowledge that "don't kill claude.exe" was never transmitted from the process design to the process implementation. The SpaceAudit serialization bug is an FKS (Foundational Knowledge Substrates) case study — PowerShell's type system silently degrades across parallel boundaries, and the foundational knowledge of "why" is not visible in the code that works around it. Every technical debugging session contains a Substrate Thesis observation.

---

## PART III — Project Deep-Dive Cards

### TECHNICAL INFRASTRUCTURE · Active Sprint (reclassified from Active Maintenance)
## SOK (Son of Klem) — PowerShell System Operations Kit

**Reclassification rationale**: The 25-29Mar2026 sessions reclassified SOK from Active Maintenance to Active Sprint. The suite required a complete Common module rebuild (v2.0 → v4.3.3), discovery and repair of 12 bugs including a 4-month-old process-killing defect, a backup architecture buildout, and a storage recovery operation. This is not maintenance; it is active engineering. The reclassification stands until the outstanding item list reaches zero and two consecutive automated runs (via Scheduler) produce zero errors.

#### Systems Architect

SOK's architecture is a hub-and-spoke model: SOK-Common.psm1 is the hub (operator constants, logging, banner, history, prerequisite system), and 22 scripts are spokes that import it. This architecture means Common is the single point of failure for the entire suite — the v2.0 → v4.3.3 rebuild was the most consequential deployment of the session because it touched every script's runtime behaviour simultaneously.

The prerequisite system (Invoke-SOKPrerequisite) creates implicit ordering dependencies: SpaceAudit requires Inventory which requires Maintenance. A failure in Maintenance cascades forward through the entire pipeline. The system handles this via staleness checks (if Maintenance ran within 48 hours, skip re-run), but the staleness window is a tunable constant, not a hard guarantee.

The junction architecture (10 cross-drive junctions from C: to E:) creates a hard dependency on E: being mounted. When E: is dismounted, 10 applications lose their data directories simultaneously. RebootClean auto-repairs junctions, but applications may have already cached bad paths.

#### Evidence Filter

The session's most significant evidence finding: **SpaceAudit has returned 0 results across 3+ consecutive runs despite scanning 215K directories.** The delivered v2.3.0 fix (pipe-delimited strings in ConcurrentBag[string]) is the third attempted fix. The diagnostic line `C:\ aggregated total: XXXXX KB` will immediately confirm or deny whether the serialization fix works — if that number is ~382,000,000 (matching C: used space), the fix is correct; if it is 0, the serialization is still failing. This is the highest-priority verification item.

Second evidence finding: **ProcessOptimizer killed Claude Desktop for 4 months without detection.** The kill-list filter fix is confirmed working (3 protected processes filtered, zero Claude kills in subsequent runs). But the meta-lesson is that a script can produce "successful" output while causing catastrophic side effects — the Evidence Filter must check not just "did it run?" but "did it damage anything it shouldn't have touched?"

#### Depth Scout

The suite operates at the intersection of PowerShell 7.6's parallel execution model (ForEach-Object -Parallel), .NET's System.IO enumeration APIs, Windows NTFS security descriptors (ACLs, ownership, backup operator privilege), and robocopy's backup mode (/B, SeBackupPrivilege). The SpaceAudit serialization bug specifically exposed that PowerShell's -Parallel scriptblocks run in separate runspaces where complex objects (hashtables, ordered dictionaries) lose type fidelity during cross-runspace serialization. This is documented behaviour but not intuitive — the depth required is "understand PowerShell's remoting serialization layer," which is deeper than typical PowerShell scripting.

The robocopy /MIR /B pattern for force-deletion (bypassing ACLs via backup operator privilege in a single pass) represents genuine systems-level depth — it eliminates three separate tree traversals (takeown + icacls + rd) and replaces them with one. This pattern should be documented as a reusable technique.

#### Next Action

★ Deploy SOK-SpaceAudit v2.3.0 and run it. Paste the line containing `C:\ aggregated total`. That single number determines whether the 3rd serialization fix attempt succeeded.

★ Run `choco upgrade git git.install --force -y` to resolve the nupkg corruption blocking all Chocolatey operations.

★ Run SOK-BackupRestructure.ps1 to complete the E: backup pipeline (extract remaining .7z, merge with derivation tags, verify, recompress).

#### Load Calibrator

SOK consumed 40+ hours across 4 sessions (25-29Mar2026). This is sprint-level investment. The load will decrease sharply once the outstanding items are cleared — the suite is designed to run unattended via Scheduler once stable. But "once stable" requires: SpaceAudit verified working, Chocolatey fixed, E: restructured, D: recovery ingested, and logs pruned. Estimated remaining effort: 2-3 more sessions.

The Load Calibrator's meta-observation: SOK was listed as "Active Maintenance, low load" in Rev1. That assessment was catastrophically wrong. The lesson is that infrastructure projects have hidden load — they appear stable until something fails, then they consume all available bandwidth. The correct characterisation is "low visible load, high latent load, sprint-level when activated."

#### Integration Cartographer

**SOK → Substrate Thesis**: The Claude Desktop bricking bug is a pure SCC failure — the knowledge "don't kill the operator's AI assistant" was never transmitted from the design intent to the implementation. The process list was based on CPU/memory properties, not on operator dependency. This is exactly the kind of foundational knowledge loss the Substrate Thesis predicts: the *why* of a design decision degrades while the *what* persists.

**SOK → Data Hygiene**: SOK IS the data hygiene implementation. The backup architecture (robocopy to E:, .7z compression, integrity verification) was built this session. The theoretical Data Hygiene card in Rev1 is now an operational system.

**SOK → Academic Coursework**: The SpaceAudit ConcurrentBag serialization fix is a distributed systems problem (IS 8044 security systems share the same serialization boundary concerns). The robocopy /MIR /B pattern is a privilege escalation technique (relevant to cybersecurity coursework).

**SOK → Homesteading**: The deprecate-never-delete principle is a composting principle — nothing is waste, everything is feedstock for a future state. Dead scripts become archived reference; old logs become audit trails.

**Substrate Thesis Trigger**: SOK is a live FKS laboratory. Every bug discovered represents foundational knowledge that was assumed but not encoded. The Common module rebuild was an FKS recovery operation — restoring foundational configuration knowledge that had degraded from v2.0 (TITAN era, Dec 2025) to the point where scripts were running on assumptions that no longer matched the system state.

---

### TECHNICAL INFRASTRUCTURE · Active Sprint (new entry)
## Storage Recovery & Backup Architecture

This project did not exist in Rev1. It was created by necessity during the 25-29Mar2026 sessions when the operator's backup archive (267 GB on C:) needed to be offloaded to E:, the D: drive became unreadable, and the overnight .7z extraction filled E: to 0 bytes free.

#### Systems Architect

The storage architecture has four drives with distinct roles and failure modes. C: is the primary NVMe (1TB, 589 GB free) — protected by SOK's full suite. E: is the offload/backup USB SSD (500GB) — holds 40 junction targets, backup archives, and is the staging area for D: recovery. G: is Google Drive FAT32 — cloud sync only, no TRIM, no SOK_Offload. D: is a 4TB HDD that became unreadable — TestDisk recovered a 648 GB partition that needs to be ingested across E: and C:.

The critical architectural constraint: no single drive can hold the D: recovery (648 GB > any drive's free space). The recovery must be split or selective.

#### Evidence Filter

The backup .7z files passed `7z t` integrity checks. But the overnight extractions may be incomplete (the E: stalemate interrupted them). The extracted raw folders must be verified against .7z contents before the .7z files are deleted. "It extracted" is not the same as "it extracted completely."

The backup matryoshka structure (Restructure report: 120,199 excessive nesting, 123,902 recursive backups, depth 30+) means that path lengths exceed Windows' 260-character limit. Windows Explorer, 7-Zip GUI, and some PowerShell commands will silently fail on these paths. Long-path-aware tools (`\\?\` prefix, robocopy, .NET EnumerateFiles with IgnoreInaccessible) are required.

#### Hazards Discovered

| Hazard | Root Cause | Resolution |
|--------|-----------|------------|
| E: full disk stalemate | Overnight .7z extraction consumed all free space; takeown needs disk space to write ACL changes | fsutil usn deletejournal /d E: freed NTFS journal space; smallest deletable file (7.9 MB log) created breathing room |
| ACL-locked extracted files | Old user profiles (Shelby, shala from 2020-2021 backups) own the extracted files; current user cannot delete | takeown /R /A /D Y + icacls grant, or robocopy /MIR /B bypass (single-pass, no ACL rewrite needed) |
| Path length > 260 chars | Recursive backup nesting creates paths like `Backup\C_\Users\shelc\Documents\Backup\2020 Seagate 1 Backup\Shelby\20211019 Desktop Backup\...` | Use robocopy (handles long paths natively), .NET APIs with IgnoreInaccessible, or `\\?\` UNC prefix |

#### Derivation Map for Merge

| Source | Tag | Origin |
|--------|-----|--------|
| 2020 Seagate 1 Backup | _a1 | Shelby's laptop backup, Sep 2021 |
| 2020 Seagate 2 Backup | _a2 | Shelby's desktop backup, Oct 2021 |
| 2025 | _b | Recent backup, Jan 2026 |
| 13JUL2025 | _c | Mid-2025 backup |
| mommaddell backup CAO 06JUN2025 | _d | Family member backup, Jun 2025 |

Post-merge: consolidate _a1 + _a2 into _a where files are non-duplicate (hash comparison).

---

### DATA INTEGRITY · Active Maintenance (updated from Rev1)
## Data Hygiene — Backup, Versioning & Recovery

**Rev1 said**: "Test the current backup system: attempt to restore a specific file from the most recent backup and time the restoration."

**Rev3 update**: The backup system was tested — not by choice but by necessity. 267 GB robocopy'd to E: (513,370 files, zero failures). .7z integrity verified. But the restoration test revealed that the backup architecture has a matryoshka problem: backups contain backups contain backups (123,902 recursive backup directories detected by Restructure). The backup is intact but the structure is a fractal of redundancy that must be flattened before it is useful for actual restoration.

The SOK log accumulation problem is also a data hygiene issue: LiveScan JSONs (~2.7 GB), LiveDigest pairs (~1.5 GB), and Offload logs (one 181 MB monster from 19Mar) consume storage without providing proportional value after 7 days. Logs should be offloaded to E:\SOK_Offload\Deprecated on a rolling basis.

---

## PART IV — Integration Map Updates

| Source Project | Target Project | Hop Mechanism |
|---------------|---------------|---------------|
| SOK ProcessOptimizer (Claude bricking) | Substrate Thesis (SCC) | A 4-month undetected process-killing bug is a textbook SCC failure: the design intent ("don't kill essential tools") was never transmitted into the implementation. The process categorization was property-based (CPU/memory) without dependency-awareness. |
| SOK SpaceAudit (serialization bug) | Substrate Thesis (FKS) | PowerShell silently degrades complex types across parallel boundaries. The foundational knowledge of "objects lose type fidelity in remote runspaces" exists in documentation but was not present in the operator's working model. This is FKS loss in action — the knowledge exists but was not accessed when it mattered. |
| SOK Backup Architecture (matryoshka) | Data Modeling (IS 7030) | The recursive backup nesting (backup of backup of backup, 123K recursive dirs) is a data modeling anti-pattern: self-referential containment without normalization. The solution (flatten + deduplicate + tag derivation) is a dimensional modeling operation applied to a filesystem. |
| SOK robocopy /MIR /B pattern | Cybersecurity (IS 8044) | Using SeBackupPrivilege to bypass ACLs for deletion is a privilege escalation technique. The same mechanism that makes ForceDelete work is the mechanism that makes backup-operator-based attacks work. Understanding the tool as both utility and attack vector is the cybersecurity lens. |
| E: full-disk stalemate recovery | FIRE Planning | The E: stalemate is a liquidity crisis analogy — all assets (disk space) are locked in illiquid positions (ACL-locked files) with no margin for operations. The fix (delete the NTFS journal to create breathing room) is the equivalent of an emergency fund drawdown. |

---

## PART V — Session Protocol

1. **On session start**: Operator pastes this meta-prompt + the carry-over document
2. **Claude reads both**, acknowledges current state, asks what's priority
3. **Work proceeds** from the outstanding items list (oldest first unless operator redirects)
4. **Per response**: Claude checks whether meta-prompt or carry-over need updates; appends/revises if so
5. **On session end** or near context limit: Claude produces updated carry-over document
6. **Operator saves** both documents for next session

**The meta-prompt changes when**: A new architectural insight is discovered, a new project enters the portfolio, a hard rule is added or modified, or a hazard is identified that changes how future sessions should operate.

**The carry-over changes every session**: Current drive states, script versions, outstanding items, confirmed working/broken tables, and next-session start sequence.
