---
name: opencortex
description: >
  Self-improving memory architecture for OpenClaw agents. Transforms the default flat memory
  into a structured, self-maintaining knowledge system that grows smarter over time.
  Use when: (1) setting up a new OpenClaw instance, (2) user asks to improve/organize memory,
  (3) user wants the agent to stop forgetting things, (4) bootstrapping a fresh agent with
  best practices. NOT for: runtime memory_search queries (use built-in memory tools).
  Triggers: "set up memory", "organize yourself", "stop forgetting", "memory architecture",
  "self-improving", "cortex", "bootstrap memory", "memory optimization".
---

# OpenCortex — Self-Improving Memory Architecture

Transform a default OpenClaw agent into one that compounds knowledge daily.

## What This Does

1. **Structures memory** into purpose-specific files instead of one flat dump
2. **Installs nightly maintenance** that distills daily work into permanent knowledge
3. **Installs weekly synthesis** that catches patterns across days
4. **Establishes principles** that enforce good memory habits
5. **Builds a voice profile** of your human from daily conversations for authentic ghostwriting
6. **Enables safe git backup** with automatic secret scrubbing

## Installation

Run `scripts/install.sh` from this skill directory. It is idempotent — safe to re-run.

```bash
bash scripts/install.sh
```

The script will:
- Create the file hierarchy (non-destructively — won't overwrite existing files)
- Create directory structure
- Set up cron jobs (daily distillation, weekly synthesis)
- Optionally set up git backup with secret scrubbing

The installer also creates `memory/VOICE.md` — a living profile of how your human communicates. The nightly distillation analyzes each day's conversations and builds up vocabulary, tone, phrasing patterns, and decision style. Use this when ghostwriting on their behalf (community posts, emails, social media) — not for regular conversation.

After install, review and customize:
- `SOUL.md` — personality and identity (make it yours)
- `USER.md` — info about your human
- `MEMORY.md` — principles (add/remove as needed)
- `.secrets-map` — add your actual secrets for git scrubbing

## Architecture

```
SOUL.md          ← Identity, personality, boundaries
AGENTS.md        ← Operating protocol, delegation rules
MEMORY.md        ← Principles + memory index (< 3KB, loaded every session)
TOOLS.md         ← Tool shed: APIs, credentials, scripts with abilities descriptions
INFRA.md         ← Infrastructure atlas: hosts, IPs, services, network
USER.md          ← Human's preferences, projects, communication style
BOOTSTRAP.md     ← First-run checklist for new sessions

memory/
  projects/      ← One file per project (distilled, not raw)
  runbooks/      ← Step-by-step procedures (delegatable to sub-agents)
  archive/       ← Archived daily logs + weekly summaries
  YYYY-MM-DD.md  ← Today's working log (distilled nightly)
```

## Principles (installed by default)

| # | Name | Purpose |
|---|------|---------|
| P1 | Delegate First | Assess tasks for sub-agent delegation; stay available |
| P2 | Write It Down | Commit to files, not mental notes |
| P3 | Ask Before External | Confirm before emails, public posts, destructive ops |
| P4 | Tool Shed | Document every tool/API with goal-oriented abilities description |
| P5 | Capture Decisions | Record decisions with reasoning; never re-ask |
| P6 | Sub-agent Debrief | Sub-agents write learnings to daily log before completing |
| P7 | Log Failures | Tag failures/corrections in daily log for distillation routing |

## Cron Jobs (installed)

| Schedule | Name | What it does |
|----------|------|-------------|
| Daily 3 AM (local) | Distillation | Reads daily logs → distills into project/tools/infra files → optimizes → archives |
| Weekly Sunday 5 AM | Synthesis | Reviews week for patterns, recurring problems, unfinished threads, decisions |

Customize times by editing cron jobs: `openclaw cron list` then `openclaw cron edit <id> --cron "..."`.

The nightly distillation also checks for OpenCortex updates via `clawhub update opencortex`. If a new version is available, it pulls it automatically.

## Git Backup (optional)

If enabled during install, creates:
- `scripts/git-backup.sh` — auto-commit every 6 hours
- `scripts/git-scrub-secrets.sh` — replaces secrets with `{{PLACEHOLDER}}` before commit
- `scripts/git-restore-secrets.sh` — restores secrets after push
- `.secrets-map` — maps secrets to placeholders (gitignored, 600 perms)

Add secrets to `.secrets-map` in format: `actual_secret|{{PLACEHOLDER_NAME}}`

## Customization

**Adding a new project:** Create `memory/projects/my-project.md`, add to MEMORY.md index. Nightly distillation will route relevant daily log entries to it.

**Adding a new principle:** Append to MEMORY.md under 🔴 PRINCIPLES. Keep it short — one sentence proclamation.

**Adding a runbook:** Create `memory/runbooks/my-procedure.md` with step-by-step instructions. Sub-agents can follow these directly.

**Adding a tool:** Add to TOOLS.md with: what it is, how to access it, and a goal-oriented abilities description (so future intent-based lookup matches).

## How It Compounds

```
Daily work → daily log
  → nightly distill → routes to project/tools/infra/principles files
                     → optimization pass (dedup, prune stale, condense)
  → weekly synthesis → patterns, recurring problems, unfinished threads
Sub-agent work → debrief (P6) → daily log → same pipeline
Decisions → captured with reasoning (P5) → never re-asked
New tools → documented with abilities (P4) → findable by intent
```

Each day the agent wakes up slightly more knowledgeable and better organized.
