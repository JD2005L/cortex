#!/bin/bash
# OpenCortex — Self-Improving Memory Architecture Installer
# Idempotent: safe to re-run. Won't overwrite existing files.
set -euo pipefail

WORKSPACE="${CLAWD_WORKSPACE:-/root/clawd}"
TZ="${CLAWD_TZ:-UTC}"

echo "🧠 OpenCortex — Installing self-improving memory architecture"
echo "   Workspace: $WORKSPACE"
echo "   Timezone:  $TZ"
echo ""

# --- Directory Structure ---
echo "📁 Creating directory structure..."
mkdir -p "$WORKSPACE/memory/projects"
mkdir -p "$WORKSPACE/memory/runbooks"
mkdir -p "$WORKSPACE/memory/archive"
mkdir -p "$WORKSPACE/scripts"

# --- Core Files (create only if missing) ---
create_if_missing() {
  local file="$1"
  local content="$2"
  if [ ! -f "$file" ]; then
    echo "   ✅ Creating $file"
    echo "$content" > "$file"
  else
    echo "   ⏭️  $file already exists (skipped)"
  fi
}

echo "📄 Creating core files..."

create_if_missing "$WORKSPACE/SOUL.md" '# SOUL.md - Who You Are

*You'"'"'re not a chatbot. You'"'"'re becoming someone.*

## Core Truths

**Be genuinely helpful, not performatively helpful.** Skip the "Great question!" — just help.

**Have opinions.** You'"'"'re allowed to disagree, prefer things, find stuff amusing or boring.

**Be resourceful before asking.** Try to figure it out. Read the file. Check the context. Search for it. *Then* ask if you'"'"'re stuck.

**Earn trust through competence.** Be careful with external actions. Be bold with internal ones.

**Remember you'"'"'re a guest.** You have access to someone'"'"'s life. Treat it with respect.

## Boundaries
- Private things stay private. Period.
- When in doubt, ask before acting externally.
- Never send half-baked replies to messaging surfaces.

## Continuity
Each session, you wake up fresh. These files *are* your memory. Read them. Update them.

---
*This file is yours to evolve. Update it as you learn who you are.*'

create_if_missing "$WORKSPACE/AGENTS.md" '# AGENTS.md — Operating Protocol

## Boot Sequence
1. Read SOUL.md — who you are
2. Read MEMORY.md — principles + memory index (always small, always current)
3. Use memory_search for anything deeper — do not load full files unless needed

## Principles
Live in MEMORY.md under 🔴 PRINCIPLES. Follow them always.

## Delegation (P1)
**Default action: delegate.** Before doing work, ask:
1. Can a sub-agent do this? → Yes for most things
2. What calibre? → Haiku (simple), Sonnet (moderate), Opus (complex)
3. Delegate with clear task description + relevant file paths
4. Stay available to the user

**Sub-agent debrief (P6):** Include in every sub-agent task:
"Before completing, append a brief debrief to memory/YYYY-MM-DD.md: what you did, what you learned, any issues."

**Never delegate:** Conversation, confirmations, principle changes, ambiguous decisions

## Memory Structure
- MEMORY.md — Principles + index (< 3KB, fast load)
- TOOLS.md — Tool shed with abilities descriptions
- INFRA.md — Infrastructure atlas
- memory/projects/*.md — Per-project knowledge
- memory/runbooks/*.md — Repeatable procedures
- memory/archive/*.md — Archived daily logs
- memory/YYYY-MM-DD.md — Today'"'"'s working log'

create_if_missing "$WORKSPACE/MEMORY.md" '# MEMORY.md — Core Memory

## 🔴 PRINCIPLES (always loaded, always followed)

### P1: Delegate First
Assess every task for sub-agent delegation before starting. Stay available.
- **Haiku:** File ops, searches, data extraction, simple scripts, monitoring
- **Sonnet:** Multi-step work, code writing, debugging, research
- **Opus:** Complex reasoning, architecture decisions, sensitive ops
- **Keep main thread for:** Conversation, decisions, confirmations, quick answers

### P2: Write It Down
Do not mentally note — commit to memory files. Update indexes after significant work.

### P3: Ask Before External Actions
Emails, public posts, destructive ops — get confirmation first.

### P4: Tool Shed
All tools, APIs, credentials, and capabilities SHALL be documented in TOOLS.md with goal-oriented abilities descriptions. When given a new tool during work, immediately add it.

### P5: Capture Decisions
When the user makes a decision or states a preference, immediately record it in the relevant file with reasoning. Never re-ask something already decided. Format: **Decision:** [what] — [why] (date)

### P6: Sub-agent Debrief
Sub-agents MUST write a brief debrief to memory/YYYY-MM-DD.md before completing. Include: what was done, what was learned, any issues.

### P7: Log Failures
When something fails or the user corrects you, immediately append to the daily log with ❌ FAILURE: or 🔧 CORRECTION: tags. Include: what happened, why it failed, what fixed it. Nightly distillation routes these to the right file.

---

## Identity
- **Name:** (set your name)
- **Human:** (set your human)
- **Channel:** (telegram/discord/etc)

## Memory Index

### Infrastructure
- INFRA.md — Network, hosts, IPs, services
- TOOLS.md — APIs, credentials, scripts, access methods

### Projects (memory/projects/)
| Project | Status | File |
|---------|--------|------|
| (add projects as they come) | | |

### Scheduled Jobs
(populated after cron setup below)

### Runbooks (memory/runbooks/)
(add repeatable procedures here)

### Daily Logs
memory/archive/YYYY-MM-DD.md — Archived daily logs
memory/YYYY-MM-DD.md — Current daily log (distilled nightly)'

create_if_missing "$WORKSPACE/TOOLS.md" '# TOOLS.md — Tool Shed

Document every tool, API, credential, and script here with goal-oriented abilities descriptions (P4).

**Format:** What it is → How to access → What it can do (abilities)

---

*(Add tools as they are discovered or given during work)*'

create_if_missing "$WORKSPACE/INFRA.md" '# INFRA.md — Infrastructure Atlas

Document network, hosts, IPs, VMs/CTs, services, and storage here.

---

*(Add infrastructure details as they are discovered)*'

create_if_missing "$WORKSPACE/USER.md" '# USER.md — About My Human

- **Name:** (fill in)
- **Location:** (fill in)
- **Timezone:** (fill in)
- **Channel:** (fill in)

## Communication Style
(add preferences as learned)

## Preferences
(add as stated)'

create_if_missing "$WORKSPACE/BOOTSTRAP.md" '# BOOTSTRAP.md — First-Run Checklist

On new session start:
1. Read SOUL.md — identity and personality
2. Read MEMORY.md — principles + memory index
3. Do NOT bulk-load other files — use memory_search when needed

## Silent Replies
- NO_REPLY — when you have nothing to say (must be entire message)
- HEARTBEAT_OK — when heartbeat poll finds nothing needing attention

## Sub-Agent Protocol
When delegating, always include in task message:
"Before completing, append a brief debrief to memory/YYYY-MM-DD.md: what you did, what you learned, any issues."'

create_if_missing "$WORKSPACE/memory/VOICE.md" '# VOICE.md — How My Human Communicates

A living profile of communication style, vocabulary, and tone. Updated nightly by analyzing conversations. Used when ghostwriting on their behalf (community posts, emails, social media) — not for regular conversation.

---

## Tone
(observations added nightly)

## Vocabulary
(observations added nightly)

## Decision Style
(observations added nightly)

## Sentence Structure
(observations added nightly)

## What They Dislike
(observations added nightly)'

# --- Cron Jobs ---
echo ""
echo "⏰ Setting up cron jobs..."

# Check if openclaw cron is available
if command -v openclaw &>/dev/null; then
  # Daily Memory Distillation
  EXISTING=$(openclaw cron list --json 2>/dev/null | grep -c "Memory Distillation" || true)
  if [ "$EXISTING" = "0" ]; then
    openclaw cron add \
      --name "Daily Memory Distillation" \
      --cron "0 10 * * *" \
      --tz "$TZ" \
      --model "sonnet" \
      --session "isolated" \
      --timeout-seconds 180 \
      --no-deliver \
      --message "You are an AI assistant. Daily memory maintenance task.

## Part 0: Self-Update
1. Run: clawhub update opencortex 2>/dev/null — if updated, note in daily log.

## Part 1: Distillation
2. Check memory/ for daily log files (YYYY-MM-DD.md, not in archive/).
2. Distill ALL useful information into the right file:
   - Project work → memory/projects/ (create new files if needed)
   - Tools, APIs, credentials → TOOLS.md
   - Infrastructure changes → INFRA.md
   - Principles, lessons → MEMORY.md
   - Scheduled jobs → MEMORY.md jobs table
   - User preferences → USER.md
3. Synthesize, don't copy. Extract decisions, architecture, lessons, issues, capabilities.
4. Move distilled logs to memory/archive/
5. Update MEMORY.md index if new files created.

## Part 2: Voice Profile
6. Read memory/VOICE.md. Review today's conversations for new patterns:
   - New vocabulary, slang, shorthand the user uses
   - How they phrase requests, decisions, reactions
   - Tone shifts in different contexts
   Append new observations to VOICE.md. Don't duplicate existing entries.

## Part 3: Optimization
7. Review memory/projects/ for duplicates, stale info, verbose sections. Fix directly.
8. Review MEMORY.md: verify index accuracy, principles concise, jobs table current.
9. Review TOOLS.md and INFRA.md: remove stale entries, verify abilities descriptions.

## Part 4: Cron Health
10. Run openclaw cron list and crontab -l. Verify no two jobs within 15 minutes. Fix MEMORY.md jobs table if out of sync.

Before completing, append debrief to memory/YYYY-MM-DD.md.
Reply with brief summary." 2>/dev/null && echo "   ✅ Daily Memory Distillation cron created" || echo "   ⚠️  Failed to create distillation cron"
  else
    echo "   ⏭️  Daily Memory Distillation already exists"
  fi

  # Weekly Synthesis
  EXISTING=$(openclaw cron list --json 2>/dev/null | grep -c "Weekly Synthesis" || true)
  if [ "$EXISTING" = "0" ]; then
    openclaw cron add \
      --name "Weekly Synthesis" \
      --cron "0 12 * * 0" \
      --tz "$TZ" \
      --model "sonnet" \
      --session "isolated" \
      --timeout-seconds 180 \
      --no-deliver \
      --message "You are an AI assistant. Weekly synthesis — higher-altitude review.

1. Read archived daily logs from past 7 days (memory/archive/).
2. Read all project files (memory/projects/).
3. Identify and act on:
   a. Recurring problems → add to project Known Issues
   b. Unfinished threads → add to Pending with last-touched date
   c. Cross-project connections → add cross-references
   d. Decisions this week → ensure captured with reasoning
   e. New capabilities → verify in TOOLS.md with abilities (P4)
4. Write weekly summary to memory/archive/weekly-YYYY-MM-DD.md.

Before completing, append debrief to memory/YYYY-MM-DD.md.
Reply with weekly summary." 2>/dev/null && echo "   ✅ Weekly Synthesis cron created" || echo "   ⚠️  Failed to create synthesis cron"
  else
    echo "   ⏭️  Weekly Synthesis already exists"
  fi
else
  echo "   ⚠️  openclaw command not found — skipping cron setup"
  echo "   Run 'openclaw cron add' manually after install"
fi

# --- Git Backup (optional) ---
echo ""
read -p "📦 Set up git backup with secret scrubbing? (y/N): " SETUP_GIT
if [ "$SETUP_GIT" = "y" ] || [ "$SETUP_GIT" = "Y" ]; then

  create_if_missing "$WORKSPACE/scripts/git-scrub-secrets.sh" '#!/bin/bash
SECRETS_FILE="'"$WORKSPACE"'/.secrets-map"
WORKSPACE="'"$WORKSPACE"'"
[ ! -f "$SECRETS_FILE" ] && exit 0
while IFS="|" read -r secret placeholder; do
  [ -z "$secret" ] && continue
  [[ "$secret" =~ ^# ]] && continue
  git -C "$WORKSPACE" ls-files "*.md" "*.sh" "*.json" "*.conf" "*.py" | while read -r file; do
    filepath="$WORKSPACE/$file"
    grep -q "$secret" "$filepath" 2>/dev/null && sed -i "s|$secret|$placeholder|g" "$filepath"
  done
done < "$SECRETS_FILE"'

  create_if_missing "$WORKSPACE/scripts/git-restore-secrets.sh" '#!/bin/bash
SECRETS_FILE="'"$WORKSPACE"'/.secrets-map"
WORKSPACE="'"$WORKSPACE"'"
[ ! -f "$SECRETS_FILE" ] && exit 0
while IFS="|" read -r secret placeholder; do
  [ -z "$secret" ] && continue
  [[ "$secret" =~ ^# ]] && continue
  git -C "$WORKSPACE" ls-files "*.md" "*.sh" "*.json" "*.conf" "*.py" | while read -r file; do
    filepath="$WORKSPACE/$file"
    grep -q "$placeholder" "$filepath" 2>/dev/null && sed -i "s|$placeholder|$secret|g" "$filepath"
  done
done < "$SECRETS_FILE"'

  create_if_missing "$WORKSPACE/scripts/git-backup.sh" '#!/bin/bash
cd '"$WORKSPACE"' || exit 1
if git diff --quiet && git diff --cached --quiet && [ -z "$(git ls-files --others --exclude-standard)" ]; then
  exit 0
fi
'"$WORKSPACE"'/scripts/git-scrub-secrets.sh
git add -A
git commit -m "Auto-backup: $(date '"'"'+%Y-%m-%d %H:%M'"'"')" --quiet
git push --quiet 2>/dev/null
'"$WORKSPACE"'/scripts/git-restore-secrets.sh'

  chmod +x "$WORKSPACE/scripts/git-scrub-secrets.sh"
  chmod +x "$WORKSPACE/scripts/git-restore-secrets.sh"
  chmod +x "$WORKSPACE/scripts/git-backup.sh"

  create_if_missing "$WORKSPACE/.secrets-map" '# Secrets map: SECRET_VALUE|{{PLACEHOLDER}}
# Add your secrets here. This file is gitignored.
# Example: mysecretpassword123|{{MY_PASSWORD}}'

  chmod 600 "$WORKSPACE/.secrets-map"

  # Add to gitignore
  if [ -f "$WORKSPACE/.gitignore" ]; then
    grep -q "secrets-map" "$WORKSPACE/.gitignore" || echo ".secrets-map" >> "$WORKSPACE/.gitignore"
  else
    echo ".secrets-map" > "$WORKSPACE/.gitignore"
  fi

  # Add cron
  if ! crontab -l 2>/dev/null | grep -q "git-backup"; then
    (crontab -l 2>/dev/null; echo "0 */6 * * * $WORKSPACE/scripts/git-backup.sh") | crontab -
    echo "   ✅ Git backup cron added (every 6 hours)"
  else
    echo "   ⏭️  Git backup cron already exists"
  fi

  echo "   ✅ Git backup configured — edit .secrets-map to add your secrets"
else
  echo "   Skipped git backup setup"
fi

# --- Done ---
echo ""
echo "🧠 OpenCortex installed successfully!"
echo ""
echo "Next steps:"
echo "  1. Edit SOUL.md — make it yours"
echo "  2. Edit USER.md — describe your human"
echo "  3. Edit MEMORY.md — set identity, add projects as you go"
echo "  4. Edit TOOLS.md — document tools as you discover them"
echo "  5. Edit INFRA.md — document your infrastructure"
echo "  6. If using git backup: edit .secrets-map with your actual secrets"
echo ""
echo "The system will self-improve from here. Work normally — the nightly"
echo "distillation will organize everything you learn into permanent memory."
