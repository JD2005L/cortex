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
openclaw skill install cortex.skill
```

### Option 2: From source
```bash
git clone https://github.com/JD2005L/opencortex.git
cd cortex
bash scripts/install.sh
```

The installer is idempotent — safe to re-run. It won't overwrite existing files.

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
| Sunday 5 AM | Weekly Synthesis | Find patterns, recurring problems, unfinished threads, validate decisions |

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

### 1. No Required Environment Variables or API Keys

OpenCortex does not require or reference any API keys, tokens, or environment variables. Cron jobs specify `--model "sonnet"` which is resolved by your OpenClaw gateway using whatever model provider you've already configured. **OpenCortex has zero knowledge of your API credentials.**

### 2. Credential Handling in TOOLS.md

The P4 (Tool Shed) principle instructs the *agent* to document tools and access methods. **OpenCortex itself never writes credentials into any file.** The agent, during normal conversation with you, may document tools you give it — that's the agent's behavior, not the skill's. If you prefer metadata-only documentation (e.g., "Database: see env var $DB_PASS"), instruct your agent accordingly.

### 3. Git Backup & Secret Scrubbing (Optional, Off by Default)

Git backup is **opt-in** — the installer asks before creating any backup scripts. If enabled:

- `.secrets-map` defines `secret|{{PLACEHOLDER}}` pairs (you write this manually)
- `git-scrub-secrets.sh` replaces all secrets with placeholders via `sed` before commit
- `git-restore-secrets.sh` reverses the replacements after push
- `git-backup.sh` calls scrub → `git add -A` → commit → push → restore
- `.secrets-map` is gitignored with 600 permissions

**No scrubbing happens unless you populate `.secrets-map`.** The scripts contain no network calls, no external endpoints, no telemetry. They are pure `sed` + `git` operations. [Read them in full](scripts/).

**Recommendation:** Test in a throwaway repo before pointing at a real remote. Run `git-scrub-secrets.sh` then inspect `git diff` to verify scrubbing works before your first push.

### 4. Workspace & Privileges

The installer defaults to `CLAWD_WORKSPACE` env var, falling back to `/root/clawd`. To install in a non-root location:

```bash
CLAWD_WORKSPACE=/home/myuser/agent bash scripts/install.sh
```

All file operations are confined to the workspace directory. No system-wide changes are made outside of cron job registration.

### 5. Autonomous Cron Jobs

Two cron jobs are created (both run as isolated OpenClaw sessions):

| Job | What it reads | What it writes | Network access |
|-----|--------------|----------------|----------------|
| Daily Distillation | `memory/*.md`, workspace `*.md` | `memory/projects/`, `MEMORY.md`, `TOOLS.md`, `INFRA.md`, `USER.md`, `memory/VOICE.md` | `clawhub update opencortex` only (self-update check, can be removed) |
| Weekly Synthesis | `memory/archive/*.md`, `memory/projects/*.md` | `memory/archive/weekly-*.md`, project files | None |

Cron jobs **do not** make external API calls, send emails, post to services, or access anything outside the workspace — with one exception: the optional `clawhub update opencortex` self-update check. Remove that line from the cron if you want fully air-gapped operation.

### 6. Voice Profiling (Optional)

`memory/VOICE.md` is created as an empty template. The nightly distillation *suggests* analyzing conversation patterns — but this only works if your OpenClaw instance stores conversation logs in the workspace. **No conversation data is transmitted externally.** All analysis stays in local files.

To disable voice profiling: delete `memory/VOICE.md` and remove Part 2 from the distillation cron (`openclaw cron edit <id>`).

### 7. No Hidden Endpoints

OpenCortex contains **zero network operations** beyond the optional `clawhub update` call. No telemetry, no phone-home, no external uploads. Every script is plain bash with `sed`, `git`, `grep`, and `find`. [Full source is public](https://github.com/JD2005L/opencortex).

### Summary

| Concern | Status |
|---------|--------|
| Required API keys/env vars | **None.** Model access handled by OpenClaw gateway. |
| Raw secrets in TOOLS.md | **Not by the skill.** Agent behavior, controllable by user instruction. |
| Git scrubbing reliability | **Opt-in, manual .secrets-map, auditable scripts.** Test before use. |
| Root workspace default | **Configurable via `CLAWD_WORKSPACE`.** |
| Autonomous file writes | **Workspace-only.** No system files touched. |
| Voice profiling privacy | **Optional, local-only, removable.** |
| Network access | **None** except optional self-update. Removable. |
| Hidden endpoints | **None.** Full source public and auditable. |

## Requirements

- [OpenClaw](https://github.com/openclaw/openclaw) 2026.2.x+

## License

MIT

## Credits

Created by [JD2005L](https://github.com/JD2005L)
