# 🧠 OpenCortex

**Self-improving memory architecture for [OpenClaw](https://github.com/openclaw/openclaw) agents.**

Stop forgetting. Start compounding.

---

## The Problem

Out of the box, OpenClaw agents dump everything into a flat `MEMORY.md`. Context fills up, compaction loses information, and the agent forgets what it learned last week. It's like having a brilliant employee with amnesia who takes notes on napkins.

## The Solution

OpenCortex transforms your agent into one that **gets smarter every day** through:

- **Structured memory** — Purpose-specific files instead of one flat dump
- **Nightly distillation** — Daily work automatically distilled into permanent knowledge
- **Weekly synthesis** — Pattern detection across days catches recurring problems and unfinished threads
- **Enforced principles** — Habits that prevent knowledge loss (decision capture, tool documentation, sub-agent debriefs)
- **Encrypted vault** — AES-256 encrypted secret storage with key-only references in docs
- **Voice profiling** — Learns how your human communicates for authentic ghostwriting
- **Safe git backup** — Automatic secret scrubbing so credentials never hit your repo

## Architecture

```
SOUL.md          ← Identity & personality
AGENTS.md        ← Operating protocol & delegation rules
MEMORY.md        ← Principles + index (< 3KB, loaded every session)
TOOLS.md         ← Tool shed: APIs, scripts with abilities descriptions
INFRA.md         ← Infrastructure atlas: hosts, IPs, services
USER.md          ← Your human's preferences
BOOTSTRAP.md     ← Session startup checklist

memory/
  projects/      ← One file per project (distilled, not raw)
  runbooks/      ← Step-by-step procedures (delegatable to sub-agents)
  archive/       ← Archived daily logs + weekly summaries
  YYYY-MM-DD.md  ← Today's working log (distilled nightly)
```

## How It Compounds

```
Week 1:  Agent knows basics, asks lots of questions
Week 4:  Agent has project history, knows tools, follows decisions
Week 12: Agent has deep institutional knowledge, patterns, runbooks
Week 52: Agent knows more about your setup than you remember
```

The key: **daily distillation + weekly synthesis + decision capture** means the agent improves at a rate proportional to how much you use it.

## Install

### Option 1: OpenClaw Skill
```bash
openclaw skill install opencortex.skill
```

### Option 2: From source
```bash
git clone https://github.com/JD2005L/opencortex.git
cd opencortex
bash scripts/install.sh
```

The installer is idempotent — safe to re-run. It won't overwrite existing files. Pass `--dry-run` to preview what would be created without writing anything:

```bash
bash scripts/install.sh --dry-run
```

### After install:
1. Edit `SOUL.md` — make it yours
2. Edit `USER.md` — describe your human
3. Edit `MEMORY.md` — set identity, add projects as you go
4. Edit `TOOLS.md` — document tools as you discover them
5. If using git backup: edit `.secrets-map` with your secrets

## What Gets Installed

### Files (created only if missing)
| File | Purpose |
|------|---------|
| `SOUL.md` | Agent identity and personality |
| `AGENTS.md` | Operating protocol, delegation rules |
| `MEMORY.md` | Core principles + memory index |
| `TOOLS.md` | Tool/API catalog template |
| `INFRA.md` | Infrastructure reference template |
| `USER.md` | Human preferences template |
| `BOOTSTRAP.md` | Session startup checklist |

### Cron Jobs
| Schedule | Job | Purpose |
|----------|-----|---------|
| Daily 3 AM | Memory Distillation | Distill daily logs → permanent knowledge, optimize, check cron spacing |
| Sunday 5 AM | Weekly Synthesis | Find patterns, recurring problems, unfinished threads, validate decisions; auto-detects repeated procedures and creates runbooks |

Both jobs use a shared lockfile (`/tmp/opencortex-distill.lock`) to prevent conflicts when they run near each other.

### Principles (P1–P6)
| # | Principle | Purpose |
|---|-----------|---------|
| P1 | Delegate First | Sub-agent delegation by default |
| P2 | Write It Down | Never "mentally note" — commit to files |
| P3 | Ask Before External | Confirm before public/destructive actions |
| P4 | Tool Shed | Document every capability with abilities description |
| P5 | Capture Decisions | Record decisions with reasoning, never re-ask |
| P6 | Sub-agent Debrief | Delegated work feeds learnings back to daily log |
| P7 | Log Failures | Tag failures/corrections with ❌/🔧 for distillation routing |

### Voice Profile (`memory/VOICE.md`)
The nightly distillation analyzes each day's conversations and builds a living profile of how your human communicates — vocabulary, tone, phrasing, decision style. Used when ghostwriting on their behalf (community posts, emails, social media). Not used for regular agent conversation.

### Optional: Git Backup with Secret Scrubbing
- Auto-commit every 6 hours
- Secrets replaced with `{{PLACEHOLDER}}` before commit
- Restored locally after push
- `.secrets-map` file (gitignored, 600 perms)

## Customization

**Add a project:** Create `memory/projects/my-project.md`, add to MEMORY.md index.

**Add a principle:** Append to MEMORY.md under 🔴 PRINCIPLES. Keep it short.

**Add a runbook:** Create `memory/runbooks/my-procedure.md`. Sub-agents follow these directly.

**Add a tool:** Add to TOOLS.md with: what it is, how to access it, abilities description.

**Change schedule:** `openclaw cron list` then `openclaw cron edit <id> --cron "..."`.

## Security & Transparency

> **Scanner assessment:** OpenCortex will likely be flagged as "Suspicious — Medium Confidence" by automated security scans. This is expected for any skill that creates autonomous cron jobs. Below we address every concern category directly.

### Purpose & Capability

OpenCortex does exactly what it describes: creates structured memory files, registers nightly/weekly cron jobs for maintenance, and optionally sets up git backup. The installer (`scripts/install.sh`) and all helper scripts (`scripts/git-*.sh`) are bundled, auditable, and contain no obfuscated code. Every file is plain bash or markdown. The skill creates no executables, downloads no binaries, and installs no packages.

### Instruction Scope

The cron jobs instruct an OpenClaw agent session to read and write **workspace files only** — the same files listed in the Architecture section above. The distillation job routes information between workspace markdown files (e.g., daily log → project files). It does not access files outside the workspace, make API calls, or execute arbitrary commands. Voice profiling is **opt-in during installation** — declined by default.

### Install Mechanism

Installation is a single bash script (`scripts/install.sh`). It:
- Creates markdown files (only if they don't already exist — non-destructive)
- Creates directories (`memory/projects/`, `memory/runbooks/`, `memory/archive/`)
- Registers OpenClaw cron jobs via `openclaw cron add`
- Optionally copies the bundled `git-*.sh` scripts to the workspace

No external downloads, no package installs, no network calls during installation. The workspace path defaults to the current directory and is configurable via `CLAWD_WORKSPACE`.

### Credentials

OpenCortex declares no required environment variables, API keys, or config files. The cron jobs reference `--model "sonnet"` which is resolved by your existing OpenClaw gateway — OpenCortex never sees or handles model provider keys. The P4 (Tool Shed) principle guides the *agent* to document tools it encounters during conversation — this is agent behavior, not skill behavior. If you prefer metadata-only documentation in TOOLS.md, instruct your agent accordingly.

**Vault security:** Secrets encrypted at rest via GPG symmetric encryption (AES-256). The symmetric passphrase is stored in `.vault/.passphrase` with 600 permissions. The passphrase is generated locally by `openssl rand` during `vault init` and never transmitted externally. To rotate the passphrase, run `scripts/vault.sh rotate` — it re-encrypts all secrets in place with a new passphrase. Key names are validated on `vault.sh set`: alphanumeric and underscores only, must start with a letter or underscore.

### Persistence & Privilege

The installer creates two persistent cron jobs (daily distillation, weekly synthesis) that run as isolated OpenClaw sessions. These are the core value proposition — without them, the memory doesn't self-maintain. Both jobs:
- Read/write only within the workspace directory
- Run in isolated sessions (no access to your main conversation)
- Contain no destructive operations (no `rm`, no system changes)
- Can be listed (`openclaw cron list`), inspected, edited, or removed at any time

Optional features that add scope (all **off by default**, enabled only if you say yes during install):

- **Voice profiling:** Reads conversation logs within the workspace to build a communication profile
- **Git backup:** Runs `git push` on a cron — requires you to configure a remote and populate `.secrets-map`

To run fully air-gapped: decline all three optional features during install.

### 1. No Required Environment Variables or API Keys

OpenCortex does not require or reference any API keys, tokens, or environment variables. Cron jobs specify `--model "sonnet"` which is resolved by your OpenClaw gateway using whatever model provider you've already configured. **OpenCortex has zero knowledge of your API keys.**

### 2. Tool Documentation in TOOLS.md

The P4 (Tool Shed) principle instructs the *agent* to document tools and access methods. The agent, during normal conversation with you, may document tools you provide — that's the agent's behavior, not the skill's. If you prefer metadata-only documentation (e.g., "Database: see env var $DB_PASS"), instruct your agent accordingly. In secure mode, the vault stores encrypted values and TOOLS.md receives only `vault:<key>` references. Note: the vault passphrase itself is stored at `.vault/.passphrase` (mode 600) — secrets encrypted at rest, passphrase protected by filesystem permissions. Key names must be alphanumeric + underscores and start with a letter or underscore (`vault.sh set` enforces this).

### 3. Git Backup & Secret Scrubbing (Optional, Off by Default)

Git backup is **opt-in** — the installer asks before creating any backup scripts. If enabled:

- `.secrets-map` defines `secret|{{PLACEHOLDER}}` pairs (you write this manually)
- `git-scrub-secrets.sh` replaces all secrets with placeholders via `sed` before commit
- `git-restore-secrets.sh` reverses the replacements after push
- `git-backup.sh` calls scrub → `git add -A` → commit → **verifies no raw secrets remain in tracked files** → push → restore. If verification finds any secrets, the push is aborted and secrets are restored immediately.
- `.secrets-map` is gitignored with 600 permissions

**No scrubbing happens unless you populate `.secrets-map`.** The scripts contain no network calls, no external endpoints, no telemetry. They are pure `sed` + `git` operations. [Read them in full](scripts/).

**Recommendation:** Test in a throwaway repo before pointing at a real remote. Run `git-scrub-secrets.sh` then inspect `git diff` to verify scrubbing works before your first push.

### 4. Workspace & Privileges

The installer defaults to the current working directory (`CLAWD_WORKSPACE` env var). To install in a non-root location:

```bash
CLAWD_WORKSPACE=/home/myuser/agent bash scripts/install.sh
```

All file operations are confined to the workspace directory. No system-wide changes are made outside of cron job registration.

### 5. Autonomous Cron Jobs

Two cron jobs are created (both run as isolated OpenClaw sessions):

| Job | What it reads | What it writes | Network access |
|-----|--------------|----------------|----------------|
| Daily Distillation | `memory/*.md`, workspace `*.md` | `memory/projects/`, `MEMORY.md`, `TOOLS.md`, `INFRA.md`, `USER.md`, `memory/VOICE.md` | None |
| Weekly Synthesis | `memory/archive/*.md`, `memory/projects/*.md` | `memory/archive/weekly-*.md`, project files, `memory/runbooks/` | None |

Both jobs acquire a lockfile (`/tmp/opencortex-distill.lock`) before running, so concurrent execution is safe if the daily and weekly jobs overlap.

Cron jobs **do not** make external API calls, send emails, post to services, or access anything outside the workspace.

### 6. Voice Profiling (Optional)

`memory/VOICE.md` is created as an empty template. The nightly distillation *suggests* analyzing conversation patterns — but this only works if your OpenClaw instance stores conversation logs in the workspace. **No conversation data is transmitted externally.** All analysis stays in local files.

To disable voice profiling: delete `memory/VOICE.md` and remove Part 2 from the distillation cron (`openclaw cron edit <id>`).

### 7. No Hidden Endpoints

OpenCortex contains **zero network operations**. No telemetry, no phone-home, no external uploads. Every script is plain bash with `sed`, `git`, `grep`, and `find`. [Full source is public](https://github.com/JD2005L/opencortex).

### Summary

| Concern | Status |
|---------|--------|
| Required API keys/env vars | **None.** Model access handled by OpenClaw gateway. |
| Raw secrets in TOOLS.md | **Prevented in secure mode.** Vault stores encrypted values, TOOLS.md gets `vault:<key>` references only. |
| Git scrubbing reliability | **Opt-in, manual .secrets-map, auditable scripts. Pre-push verification aborts if secrets detected.** Test before use. |
| Root workspace default | **Configurable via `CLAWD_WORKSPACE`.** |
| Autonomous file writes | **Workspace-only.** No system files touched. |
| Voice profiling privacy | **Optional, local-only, removable.** |
| Network access | **None.** All operations are local file I/O. |
| Hidden endpoints | **None.** Full source public and auditable. |

## Requirements

- [OpenClaw](https://github.com/openclaw/openclaw) 2026.2.x+
- **Required:** `grep`, `sed`, `find` (standard on most systems)
- **Optional:** `git` (for backup), `gpg` (for vault), `openssl` (for passphrase generation)

## License

MIT

## Credits

Created by [JD2005L](https://github.com/JD2005L)
