#!/bin/bash
# OpenCortex — Self-Improving Memory Architecture Installer
# Idempotent: safe to re-run. Won't overwrite existing files.
set -euo pipefail

# --- Pre-flight: check required tools ---
REQUIRED_TOOLS=(grep sed find)
OPTIONAL_TOOLS=(openclaw git gpg)
MISSING=()
for tool in "${REQUIRED_TOOLS[@]}"; do
  command -v "$tool" &>/dev/null || MISSING+=("$tool")
done
if [ ${#MISSING[@]} -gt 0 ]; then
  echo "❌ Missing required tools: ${MISSING[*]}"
  echo "   Install them and re-run."
  exit 1
fi
for tool in "${OPTIONAL_TOOLS[@]}"; do
  command -v "$tool" &>/dev/null || echo "   ⚠️  Optional tool not found: $tool (some features will be unavailable)"
done

# --- Dry-run mode ---
DRY_RUN=false
for arg in "$@"; do
  [[ "$arg" == "--dry-run" ]] && DRY_RUN=true
done
if [ "$DRY_RUN" = "true" ]; then
  echo "⚠️  DRY RUN MODE — no files will be created or modified."
  echo ""
fi

WORKSPACE="${CLAWD_WORKSPACE:-$(pwd)}"
TZ="${CLAWD_TZ:-UTC}"

echo "🧠 OpenCortex — Installing self-improving memory architecture"
echo "   Workspace: $WORKSPACE"
echo "   Timezone:  $TZ"
echo ""

# --- Feature Selection ---
echo "Select features:"
echo ""

echo "🔒 Secret storage mode:"
echo "   secure = Sensitive values encrypted in vault, referenced by key in docs"
echo "   direct = Agent documents everything in plain workspace files"
read -p "   Choose (secure/direct) [secure]: " SECRET_MODE
SECRET_MODE=$(echo "${SECRET_MODE:-secure}" | tr '[:upper:]' '[:lower:]')

read -p "📝 Enable voice profiling? Analyzes conversation style for ghostwriting. (y/N): " ENABLE_VOICE
ENABLE_VOICE=$(echo "$ENABLE_VOICE" | tr '[:upper:]' '[:lower:]')



echo ""

# --- Directory Structure ---
echo "📁 Creating directory structure..."
if [ "$DRY_RUN" = "true" ]; then
  echo "   [DRY RUN] Would mkdir: $WORKSPACE/memory/projects"
  echo "   [DRY RUN] Would mkdir: $WORKSPACE/memory/runbooks"
  echo "   [DRY RUN] Would mkdir: $WORKSPACE/memory/archive"
  echo "   [DRY RUN] Would mkdir: $WORKSPACE/scripts"
else
  mkdir -p "$WORKSPACE/memory/projects"
  mkdir -p "$WORKSPACE/memory/runbooks"
  mkdir -p "$WORKSPACE/memory/archive"
  mkdir -p "$WORKSPACE/scripts"
fi

# --- Core Files (create only if missing) ---
create_if_missing() {
  local file="$1"
  local content="$2"
  if [ "$DRY_RUN" = "true" ]; then
    echo "   [DRY RUN] Would create: $file"
    return
  fi
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
All tools, APIs, access methods, and capabilities SHALL be documented in TOOLS.md with goal-oriented abilities descriptions. When given a new tool during work, immediately add it.
**Enforcement:** After using any CLI tool, API, or service — before ending the task — verify it exists in TOOLS.md. If not, add it immediately. Do not defer to distillation.

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
- TOOLS.md — APIs, scripts, and access methods

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

Document every tool, API, and script here with goal-oriented abilities descriptions (P4).

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

if [ "$ENABLE_VOICE" = "y" ] || [ "$ENABLE_VOICE" = "yes" ]; then
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
fi

# --- Vault Setup ---
if [ "$SECRET_MODE" = "secure" ]; then
  SKILL_DIR="$(cd "$(dirname "$0")" && pwd)"
  if [ -f "$SKILL_DIR/vault.sh" ]; then
    if [ "$DRY_RUN" = "true" ]; then
      echo "   [DRY RUN] Would copy: $SKILL_DIR/vault.sh → $WORKSPACE/scripts/vault.sh"
    else
      cp "$SKILL_DIR/vault.sh" "$WORKSPACE/scripts/vault.sh"
      chmod +x "$WORKSPACE/scripts/vault.sh"
      echo "   📋 Copied vault.sh"
    fi
  fi
  
  if [ "$DRY_RUN" != "true" ]; then
    "$WORKSPACE/scripts/vault.sh" init 2>/dev/null || true
  fi
  
  # Add vault to gitignore
  if [ -f "$WORKSPACE/.gitignore" ]; then
    grep -q ".vault" "$WORKSPACE/.gitignore" || echo ".vault/" >> "$WORKSPACE/.gitignore"
  else
    echo ".vault/" > "$WORKSPACE/.gitignore"
  fi
  
  echo "   ✅ Vault initialized — store secrets with: scripts/vault.sh set <key> <value>"
  echo "   📖 Reference in TOOLS.md as: password: vault:key_name"
fi

# --- Cron Jobs ---
echo ""
echo "⏰ Setting up cron jobs..."

# Check if openclaw cron is available
if command -v openclaw &>/dev/null; then
  # Daily Memory Distillation
  EXISTING=$(openclaw cron list --json 2>/dev/null | grep -c "Memory Distillation" || true)
  if [ "$EXISTING" = "0" ]; then
    # Build cron message dynamically based on feature selection
    CRON_MSG="You are an AI assistant. Daily memory maintenance task.

IMPORTANT: Before writing to any file, check for /tmp/opencortex-distill.lock. If it exists and was created less than 10 minutes ago, wait 30 seconds and retry (up to 3 times). Before starting work, create this lockfile. Remove it when done. This prevents daily and weekly jobs from conflicting."

    if [ "$SECRET_MODE" = "secure" ]; then
      CRON_MSG="$CRON_MSG

## Part 1: Distillation
1. Check memory/ for daily log files (YYYY-MM-DD.md, not in archive/).
2. Distill ALL useful information into the right file:
   - Project work → memory/projects/ (create new files if needed)
   - New tool descriptions and capabilities → TOOLS.md (names, URLs, what they do)
   - IMPORTANT: Never write passwords, tokens, or secrets into any file. For sensitive values, instruct the user to run: scripts/vault.sh set <key> <value>. Reference in docs as: vault:<key>
   - Infrastructure changes → INFRA.md
   - Principles, lessons → MEMORY.md
   - Scheduled jobs → MEMORY.md jobs table
   - User preferences → USER.md
3. Synthesize, do not copy. Extract decisions, architecture, lessons, issues, capabilities.
4. Move distilled logs to memory/archive/
5. Update MEMORY.md index if new files created."
    else
      CRON_MSG="$CRON_MSG

## Part 1: Distillation
1. Check memory/ for daily log files (YYYY-MM-DD.md, not in archive/).
2. Distill ALL useful information into the right file:
   - Project work → memory/projects/ (create new files if needed)
   - New tools, APIs, access methods → TOOLS.md
   - Infrastructure changes → INFRA.md
   - Principles, lessons → MEMORY.md
   - Scheduled jobs → MEMORY.md jobs table
   - User preferences → USER.md
3. Synthesize, do not copy. Extract decisions, architecture, lessons, issues, capabilities.
4. Move distilled logs to memory/archive/
5. Update MEMORY.md index if new files created."
    fi

    # Voice profiling (opt-in)
    if [ "$ENABLE_VOICE" = "y" ] || [ "$ENABLE_VOICE" = "yes" ]; then
      CRON_MSG="$CRON_MSG

## Part 2: Voice Profile
6. Read memory/VOICE.md. Review today conversations for new patterns:
   - New vocabulary, slang, shorthand the user uses
   - How they phrase requests, decisions, reactions
   - Tone shifts in different contexts
   Append new observations to VOICE.md. Do not duplicate existing entries."
    fi

    CRON_MSG="$CRON_MSG

## Optimization
- Review memory/projects/ for duplicates, stale info, verbose sections. Fix directly.
- Review MEMORY.md: verify index accuracy, principles concise, jobs table current.
- Review TOOLS.md and INFRA.md: remove stale entries, verify descriptions.

## Tool Shed Audit (P4 Enforcement)
- Read TOOLS.md. Scan today daily logs and archived conversation for any CLI tools, APIs, or services that were USED but are NOT documented in TOOLS.md. Add missing entries with: what it is, how to access it, what it can do. This catches tools that slipped through real-time P4 enforcement.

## Cron Health
- Run openclaw cron list and crontab -l. Verify no two jobs within 15 minutes. Fix MEMORY.md jobs table if out of sync.

Before completing, append debrief to memory/YYYY-MM-DD.md.
Reply with brief summary."

    if [ "$DRY_RUN" = "true" ]; then
      echo "   [DRY RUN] Would run: openclaw cron add --name 'Daily Memory Distillation' --cron '0 10 * * *'"
    else
      openclaw cron add \
        --name "Daily Memory Distillation" \
        --cron "0 10 * * *" \
        --tz "$TZ" \
        --model "sonnet" \
        --session "isolated" \
        --timeout-seconds 180 \
        --no-deliver \
        --message "$CRON_MSG" 2>/dev/null && echo "   ✅ Daily Memory Distillation cron created" || echo "   ⚠️  Failed to create distillation cron"
    fi
  else
    echo "   ⏭️  Daily Memory Distillation already exists"
  fi

  # Weekly Synthesis
  EXISTING=$(openclaw cron list --json 2>/dev/null | grep -c "Weekly Synthesis" || true)
  if [ "$EXISTING" = "0" ]; then
    if [ "$DRY_RUN" = "true" ]; then
      echo "   [DRY RUN] Would run: openclaw cron add --name 'Weekly Synthesis' --cron '0 12 * * 0'"
    else
    openclaw cron add \
      --name "Weekly Synthesis" \
      --cron "0 12 * * 0" \
      --tz "$TZ" \
      --model "sonnet" \
      --session "isolated" \
      --timeout-seconds 180 \
      --no-deliver \
      --message "You are an AI assistant. Weekly synthesis — higher-altitude review.

IMPORTANT: Before writing to any file, check for /tmp/opencortex-distill.lock. If it exists and was created less than 10 minutes ago, wait 30 seconds and retry (up to 3 times). Before starting work, create this lockfile. Remove it when done. This prevents daily and weekly jobs from conflicting.

1. Read archived daily logs from past 7 days (memory/archive/).
2. Read all project files (memory/projects/).
3. Identify and act on:
   a. Recurring problems → add to project Known Issues
   b. Unfinished threads → add to Pending with last-touched date
   c. Cross-project connections → add cross-references
   d. Decisions this week → ensure captured with reasoning
   e. New capabilities → verify in TOOLS.md with abilities (P4)
4. Write weekly summary to memory/archive/weekly-YYYY-MM-DD.md.

## Runbook Detection
- Review this week's daily logs for any multi-step procedure (3+ steps) that was performed more than once, or is likely to recur.
- For each candidate: check if a runbook already exists in memory/runbooks/.
- If not, create one with clear step-by-step instructions that a sub-agent could follow independently.
- Update MEMORY.md runbooks index if new runbooks created.

Before completing, append debrief to memory/YYYY-MM-DD.md.
Reply with weekly summary." 2>/dev/null && echo "   ✅ Weekly Synthesis cron created" || echo "   ⚠️  Failed to create synthesis cron"
    fi
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

  # Copy bundled scripts (fully inspectable in the skill package)
  SKILL_DIR="$(cd "$(dirname "$0")" && pwd)"
  for script in git-backup.sh git-scrub-secrets.sh git-restore-secrets.sh; do
    if [ -f "$SKILL_DIR/$script" ]; then
      if [ "$DRY_RUN" = "true" ]; then
        echo "   [DRY RUN] Would copy: $SKILL_DIR/$script → $WORKSPACE/scripts/$script"
      else
        cp "$SKILL_DIR/$script" "$WORKSPACE/scripts/$script"
        chmod +x "$WORKSPACE/scripts/$script"
        echo "   📋 Copied $script"
      fi
    fi
  done

  create_if_missing "$WORKSPACE/.secrets-map" '# Secrets map: SECRET_VALUE|{{PLACEHOLDER}}
# Add your secrets here. This file is gitignored.
# Example: mysecretpassword123|{{MY_PASSWORD}}'

  [ "$DRY_RUN" != "true" ] && chmod 600 "$WORKSPACE/.secrets-map"

  # Add to gitignore
  if [ -f "$WORKSPACE/.gitignore" ]; then
    grep -q "secrets-map" "$WORKSPACE/.gitignore" || echo ".secrets-map" >> "$WORKSPACE/.gitignore"
  else
    echo ".secrets-map" > "$WORKSPACE/.gitignore"
  fi

  # Add cron
  if ! crontab -l 2>/dev/null | grep -q "git-backup"; then
    if [ "$DRY_RUN" = "true" ]; then
      echo "   [DRY RUN] Would add crontab entry: 0 */6 * * * $WORKSPACE/scripts/git-backup.sh"
    else
      (crontab -l 2>/dev/null; echo "0 */6 * * * $WORKSPACE/scripts/git-backup.sh") | crontab -
      echo "   ✅ Git backup cron added (every 6 hours)"
    fi
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

if [ "$DRY_RUN" = "true" ]; then
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  Dry run complete. No files were created."
  echo "  Re-run without --dry-run to install."
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
fi
