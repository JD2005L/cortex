# 🧠 Cortex

**Self-improving memory architecture for [OpenClaw](https://github.com/openclaw/openclaw) agents.**

Stop forgetting. Start compounding.

---

## The Problem

Out of the box, OpenClaw agents dump everything into a flat `MEMORY.md`. Context fills up, compaction loses information, and the agent forgets what it learned last week. It's like having a brilliant employee with amnesia who takes notes on napkins.

## The Solution

Cortex transforms your agent into one that **gets smarter every day** through:

- **Structured memory** — Purpose-specific files instead of one flat dump
- **Nightly distillation** — Daily work automatically distilled into permanent knowledge
- **Weekly synthesis** — Pattern detection across days catches recurring problems and unfinished threads
- **Enforced principles** — Habits that prevent knowledge loss (decision capture, tool documentation, sub-agent debriefs)
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
git clone https://github.com/JD2005L/cortex.git
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

## Requirements

- [OpenClaw](https://github.com/openclaw/openclaw) 2026.2.x+
- Anthropic API key (for sonnet cron jobs)

## License

MIT

## Credits

Created by [JD2005L](https://github.com/JD2005L)
