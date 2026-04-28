# Role-Scoped Deployments — KLEM/OS v3.1 Per-Role Compartmentalization

**Purpose:** infrastructure layer for running Claude Code sessions scoped to specific concurrent roles (Job A / Job B / Personal / etc.) under the overemployment operating model.

**Reference architecture:** `Writings/Overemployment_Stack_Integration_20260421.md` Part A (two-layer model) + Part F.7 (role-scoped Claude Code deployments).

---

## The two-layer model

Per-role compartmentalization operates on a strict column-A / column-B split:

### Column A — Role-scoped (compartmentalized)

- Identity / credentials (Job A email, Job B email, per-role OAuth tokens)
- Calendar blocks (non-overlapping time exclusivity)
- Communication channels (Slack A vs Slack B vs personal Gmail)
- Working directories (filesystem isolation)
- Browser profiles (prevent accidental cross-contamination)
- Confidential documents (role-siloed knowledge)

### Column B — Shared backbone (unified)

- SOK-Secrets DPAPI vault (role-prefixed secret names — `JOBA_X`, `JOBB_X`)
- KLEM/OS orchestration (n8n workflows, custom MCPs)
- Clay-personal knowledge base (Writings/, Learning/, memory/)
- Unified calendar (master view with per-role color overlay)
- Observability / Clay-personal dashboard

---

## Contents

| File | Purpose |
|---|---|
| `start-role-session.ps1` | Entry-point launcher. Sets `ROLE_CONTEXT` env var + changes to role-scoped working dir + loads role-specific MCP config. |
| `role-config.template.json` | Template for `role-config.json` — define each role's identity, credentials prefix, MCP config path, time block, browser profile. |
| `README.md` | This file |

---

## Deployment

### Step 1 — Copy template and customize

```powershell
Copy-Item `
  'C:\Users\shelc\Documents\Journal\Projects\scripts\role-scoped-deployments\role-config.template.json' `
  'C:\Users\shelc\Documents\Journal\Projects\scripts\role-scoped-deployments\role-config.json'
```

Edit `role-config.json` to reflect your actual roles. Replace placeholder `joba` / `jobb` with meaningful identifiers (e.g., `companya`, `companyb`, `consulting`, `academic`).

### Step 2 — Per-role credential storage

For each role, store credentials in DPAPI with role-prefixed names:

```powershell
Import-Module 'C:\Users\shelc\Documents\Journal\Projects\scripts\common\SOK-Secrets.psm1' -Force

# Job A credentials
Set-SOKSecret -Name 'JOBA_SUPABASE_URL'                -Value '<url>'
Set-SOKSecret -Name 'JOBA_SUPABASE_SERVICE_ROLE_KEY'   -Value '<key>'
Set-SOKSecret -Name 'JOBA_SLACK_TOKEN'                 -Value '<token>'
Set-SOKSecret -Name 'JOBA_GMAIL_OAUTH_REFRESH_TOKEN'   -Value '<token>'

# Job B credentials
Set-SOKSecret -Name 'JOBB_SUPABASE_URL'                -Value '<url>'
Set-SOKSecret -Name 'JOBB_SUPABASE_SERVICE_ROLE_KEY'   -Value '<key>'
Set-SOKSecret -Name 'JOBB_SLACK_TOKEN'                 -Value '<token>'
Set-SOKSecret -Name 'JOBB_GMAIL_OAUTH_REFRESH_TOKEN'   -Value '<token>'
```

### Step 3 — Per-role MCP config (optional but recommended)

Create `~/.claude-joba/.mcp.json` and `~/.claude-jobb/.mcp.json` with role-scoped MCP entries. Each MCP's PS1 launcher should read `$env:ROLE_CONTEXT` and fetch role-prefixed credentials:

```powershell
# Example inside start-supabase-mcp.ps1 role-aware extension:
$role = $env:ROLE_CONTEXT
if ($role) {
    $secretName = "${role.ToUpper()}_SUPABASE_SERVICE_ROLE_KEY"
    $supaKey = Get-SOKSecret -Name $secretName
} else {
    $supaKey = Get-SOKSecret -Name 'SUPABASE_SERVICE_ROLE_KEY'
}
```

This pattern lets the same MCP wrapper work in single-role AND role-scoped modes.

### Step 4 — Per-role browser profile

Create Chrome / Brave / Vivaldi profiles per role:
- Chrome: `chrome://settings/profiles` → Add Profile → name per `browser_profile_name` from config
- Separate profiles prevent OAuth cross-contamination, session cookie mixing, and accidental credential use

### Step 5 — Launch

```powershell
.\start-role-session.ps1 -Role joba
```

Opens a new pwsh session with:
- `ROLE_CONTEXT=joba`
- Working dir set to Job A's directory
- `CLAUDE_MCP_CONFIG_PATH` pointing to role-specific MCP config (if Claude Code honors this env var)
- Operational reminders printed (time block, async-first communication, L-15 mitigation)

Within the role-session shell, launch Claude Code / Cursor / browser as needed. All child processes inherit `ROLE_CONTEXT`.

Exit the shell to end the role session. No role-bleed into the parent environment.

---

## Integration with Operating Stack v1.4 L-15

Per `Writings/Operating_Stack_v1_4_L15_Delta_20260421.md`:

- **L-15 Role-Context Switching Cost** applies multiplicatively to tasks within the 0-30min ramp-up window post-switch
- `start-role-session.ps1` creates the explicit boundary that triggers the L-15 window
- The printed operational reminders are the discipline-anchors that help mitigate L-15 penalty

When L-15 is active (just switched roles), defer xhigh-effort work until ramp-up completes. Use the first 5-15 min for orientation tasks: inbox review, calendar check, prior-day close-out notes.

---

## Integration with Briefmatic / unified control

The unified calendar and notification-router (column B) sits above the role compartments. Briefmatic (or equivalent) aggregates tasks/notifications from both Slack A + Slack B + Gmail-joba + Gmail-jobb into one dashboard — but when you start a role session, you focus only on that role's pane.

This is how "unified visibility" per v3.1 Part D coexists with "mental exclusivity" per L-15 discipline: the data is available in one place; the attention is bounded to one role per time-block.

---

## Anti-patterns

- **Don't overlap role blocks.** Running both Job A and Job B sessions simultaneously defeats mental exclusivity, triggers L-15 × L-01 compounding, and creates risk of accidental cross-communication.
- **Don't share browser profiles.** Even with different Claude Code sessions, a shared Chrome profile can leak OAuth tokens or autocomplete sensitive data across role boundaries.
- **Don't use a single Gmail for multiple roles.** Even if the email gateway is personal, each role should have its own dedicated work email.
- **Don't check Role B during Role A deep work blocks.** This triggers unnecessary L-15 ramp-up penalties and defeats the block structure.

---

## Ethics / values note

Per `Writings/Overemployment_Stack_Integration_20260421.md` Part G: overemployment often involves non-disclosure of concurrent roles to employers. Whether this is compatible with Clay's Substrate Thesis Quiet-Professional ethos + CLAUDE.md §3 high-caliber DoD is a reflection question only Clay can answer.

The infrastructure here is **agnostic to the ethics framing**. It works whether you disclose your concurrent roles (e.g., consulting-practice declared to both employers) or don't (stealth-mode overemployment). The scaffolding doesn't incentivize either path.

If Clay pursues disclosed concurrent work (e.g., cleared declarations per DISS/JPAS requirements), this same scaffolding supports it. If stealth, same scaffolding. Clay's choice; not Claude's.

---

## Status

- **Scaffolding:** this directory (`scripts/role-scoped-deployments/`)
- **Companion architecture:** `Writings/Overemployment_Stack_Integration_20260421.md`
- **Operating Stack integration:** `Writings/Operating_Stack_v1_4_L15_Delta_20260421.md`
- **Activation gate:** Clay's directional signal on overemployment pursuit

Remains *unactivated* until Clay signals multi-role pursuit is live. Scaffolding sits ready; nothing breaks by its presence.

---

*The architecture is agnostic. The choice is Clay's. When the choice lands, the infrastructure is already built.*
