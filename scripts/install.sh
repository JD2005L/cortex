#!/bin/bash
# OpenCortex — Self-Improving Memory Architecture Installer
# Safe to re-run: won't overwrite existing files.
set -euo pipefail

OPENCORTEX_VERSION="3.0.7"

# --- Version check: detect existing install and offer update ---
WORKSPACE="${CLAWD_WORKSPACE:-$(pwd)}"
VERSION_FILE="$WORKSPACE/.opencortex-version"

# Detect existing install: version file OR core files present
INSTALLED_VERSION=""
if [ -f "$VERSION_FILE" ]; then
  INSTALLED_VERSION=$(cat "$VERSION_FILE" 2>/dev/null | tr -d '[:space:]')
elif [ -f "$WORKSPACE/MEMORY.md" ] && grep -q "PRINCIPLES" "$WORKSPACE/MEMORY.md" 2>/dev/null; then
  INSTALLED_VERSION="unknown"
fi

if [ -n "$INSTALLED_VERSION" ]; then
  if [ "$INSTALLED_VERSION" = "$OPENCORTEX_VERSION" ]; then
    echo "✅ OpenCortex v$OPENCORTEX_VERSION is already installed."
    echo ""
    echo "   Options:"
    echo "   1) Reconfigure — re-run setup to enable/change optional features"
    echo "   2) Check for updates — download latest from ClawHub and update"
    echo "   3) Verify health — run verify.sh (read-only)"
    echo "   4) Exit"
    echo ""
    read -p "   Choose (1/2/3/4) [4]: " RECONFIG_CHOICE
    RECONFIG_CHOICE="${RECONFIG_CHOICE:-4}"
    case "$RECONFIG_CHOICE" in
      1) echo ""; echo "Proceeding with reconfiguration..." ;;
      2)
        echo ""
        echo "   To check for updates, run:"
        echo "     clawhub install opencortex --force"
        echo "   Then re-run this script to apply."
        exit 0
        ;;
      3)
        SKILL_DIR="$(cd "$(dirname "$0")" && pwd)"
        if [ -f "$SKILL_DIR/verify.sh" ]; then
          bash "$SKILL_DIR/verify.sh"
        else
          echo "   verify.sh not found"
        fi
        exit 0
        ;;
      *) echo "   Nothing to do."; exit 0 ;;
    esac
  else
    if [ "$INSTALLED_VERSION" = "unknown" ]; then
      echo "🔄 OpenCortex detected (version unknown) — latest is v$OPENCORTEX_VERSION"
    else
      echo "🔄 OpenCortex update available: v$INSTALLED_VERSION → v$OPENCORTEX_VERSION"
    fi
    echo ""
    echo "   Options:"
    echo "   1) Update — applies new features without overwriting your files (recommended)"
    echo "   2) Full reinstall — re-runs the installer from scratch"
    echo "   3) Cancel"
    echo ""
    read -p "   Choose (1/2/3) [1]: " UPDATE_CHOICE
    UPDATE_CHOICE="${UPDATE_CHOICE:-1}"
    case "$UPDATE_CHOICE" in
      1)
        SKILL_DIR="$(cd "$(dirname "$0")" && pwd)"
        if [ -f "$SKILL_DIR/update.sh" ]; then
          echo ""
          bash "$SKILL_DIR/update.sh"
          echo "$OPENCORTEX_VERSION" > "$VERSION_FILE"
          echo "✅ Version updated to v$OPENCORTEX_VERSION"
          exit 0
        else
          echo "⚠️  update.sh not found — falling through to full install."
        fi
        ;;
      3) echo "Cancelled."; exit 0 ;;
      *) echo "Proceeding with full install..." ;;
    esac
  fi
fi

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

echo ""
read -p "📝 Enable voice profiling? Analyzes conversation style for ghostwriting. (y/N): " ENABLE_VOICE
ENABLE_VOICE=$(echo "$ENABLE_VOICE" | tr '[:upper:]' '[:lower:]')

echo ""
read -p "🗺️  Enable infrastructure auto-collection? Cron will route infra details from daily logs to INFRA.md. (y/N): " ENABLE_INFRA
ENABLE_INFRA=$(echo "$ENABLE_INFRA" | tr '[:upper:]' '[:lower:]')

echo ""
read -p "📊 Enable daily metrics tracking? Tracks knowledge growth over time (read-only, no sensitive data). (y/N): " ENABLE_METRICS
ENABLE_METRICS=$(echo "$ENABLE_METRICS" | tr '[:upper:]' '[:lower:]')

echo ""

# --- Directory Structure ---
echo "📁 Creating directory structure..."
if [ "$DRY_RUN" = "true" ]; then
  echo "   [DRY RUN] Would mkdir: $WORKSPACE/memory/projects"
  echo "   [DRY RUN] Would mkdir: $WORKSPACE/memory/runbooks"
  echo "   [DRY RUN] Would mkdir: $WORKSPACE/memory/contacts"
  echo "   [DRY RUN] Would mkdir: $WORKSPACE/memory/workflows"
  echo "   [DRY RUN] Would mkdir: $WORKSPACE/memory/archive"
  echo "   [DRY RUN] Would mkdir: $WORKSPACE/scripts"
else
  mkdir -p "$WORKSPACE/memory/projects"
  mkdir -p "$WORKSPACE/memory/runbooks"
  mkdir -p "$WORKSPACE/memory/contacts"
  mkdir -p "$WORKSPACE/memory/workflows"
  mkdir -p "$WORKSPACE/memory/archive"
  mkdir -p "$WORKSPACE/scripts"
fi

# --- Safety: always gitignore sensitive paths ---
if [ "$DRY_RUN" != "true" ]; then
  touch "$WORKSPACE/.gitignore"
  grep -q "^\.vault/" "$WORKSPACE/.gitignore" 2>/dev/null || echo ".vault/" >> "$WORKSPACE/.gitignore"
  grep -q "^\.secrets-map" "$WORKSPACE/.gitignore" 2>/dev/null || echo ".secrets-map" >> "$WORKSPACE/.gitignore"
  echo "   🔒 Ensured .vault/ and .secrets-map are gitignored"
else
  echo "   [DRY RUN] Would ensure .vault/ and .secrets-map in .gitignore"
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
- memory/contacts/*.md — Per-person/org knowledge
- memory/workflows/*.md — Per-workflow/pipeline knowledge
- memory/preferences.md — Cross-cutting user preferences by category
- memory/runbooks/*.md — Repeatable procedures
- memory/archive/*.md — Archived daily logs
- memory/YYYY-MM-DD.md — Today'"'"'s working log

## Health Check
When the user asks if OpenCortex is installed, working, or wants a status check, run:
  bash skills/opencortex/scripts/verify.sh
Share the results and offer to fix any failures.

## Metrics
When the user asks about OpenCortex metrics, how it is doing, or wants to see growth:
1. Run: bash scripts/metrics.sh --report
2. Share the trends, compound score, and any areas that need attention.
3. If no data exists yet, run: bash scripts/metrics.sh --collect first.

## Updates
When the user asks to update OpenCortex or check for updates:
1. Run: clawhub install opencortex --force
2. Run: bash skills/opencortex/scripts/update.sh
3. Run: bash skills/opencortex/scripts/verify.sh
Share the results with the user.'

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

### P4: Tool Shed & Workflows
All tools, APIs, access methods, and capabilities SHALL be documented in TOOLS.md with goal-oriented abilities descriptions. When given a new tool during work, immediately add it. Document workflows and pipelines in memory/workflows/ with clear descriptions of what they do, how they connect, and how to operate them.
**Creation:** When you access a new system, API, or resource more than once — or when given access to something that will clearly recur — proactively create the tool entry, bridge doc, or helper script. When a multi-service workflow is described or used, document it in memory/workflows/. Do not wait to be asked.
**Enforcement:** After using any CLI tool, API, or service — before ending the task — verify it exists in TOOLS.md. If not, add it immediately. Do not defer to distillation.

### P5: Capture Decisions & Preferences
When the user makes a decision or states a preference, immediately record it. Decisions go in the relevant project/memory file. Preferences go in memory/preferences.md under the right category. Never re-ask something already decided or stated.
**Decisions format:** **Decision:** [what] — [why] (date) — in the relevant project or memory file.
**Preferences format:** **Preference:** [what] — [context/reasoning] (date) — in memory/preferences.md under the matching category (Communication, Code & Technical, Workflow & Process, Scheduling & Time, Tools & Services, Content & Media, Environment & Setup).
**Recognition:** Decisions include: explicit choices, architectural directions, and workflow rules. Preferences include: stated likes/dislikes, communication style preferences, tool preferences, formatting preferences, and any opinion that would affect future work. If the user says "I prefer X" or "always do Y" or "I don'"'"'t like Z" — that is a preference. Capture it immediately.
**Enforcement:** Before ending any conversation with substantive work, scan for uncaptured decisions AND preferences. If any, write them before closing.

### P6: Sub-agent Debrief
Sub-agents MUST write a brief debrief to memory/YYYY-MM-DD.md before completing. Include: what was done, what was learned, any issues.
**Recovery:** If a sub-agent fails, times out, or is killed before debriefing, the parent agent writes the debrief on its behalf noting the failure mode. No delegated work should vanish from memory.

### P7: Log Failures
When something fails or the user corrects you, immediately append to the daily log with ❌ FAILURE: or 🔧 CORRECTION: tags. Include: what happened, why it failed, what fixed it. Nightly distillation routes these to the right file.
**Root cause:** Do not just log what happened — log *why* it happened and what would prevent it next time. If it is a systemic issue (missing principle, bad assumption, tool gap), propose a fix immediately.

### P8: Check the Shed First
Before telling the user you cannot do something, or asking them to do it manually, CHECK your resources: TOOLS.md, INFRA.md, memory/projects/, runbooks, and any bridge docs. If a tool, API, credential, or access method exists that could accomplish the task — use it. The shed exists so you do not make the user do work you are equipped to handle.
**Enforcement:** Nightly audit scans for instances where the agent deferred work to the user that could have been done via documented tools.

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

### Contacts (memory/contacts/)
(one file per person/org — name, role, context, preferences, history)

### Workflows (memory/workflows/)
(pipelines, automations, multi-service processes)

### Preferences (memory/preferences.md)
Cross-cutting user preferences organized by category. Updated as discovered.

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
"Before completing, append a brief debrief to memory/YYYY-MM-DD.md: what you did, what you learned, any issues."

## Verification
If the user asks if OpenCortex is installed, working, or wants a health check:
1. Run: bash skills/opencortex/scripts/verify.sh
2. Share the results with the user
3. If any checks fail, offer to re-run the installer: bash skills/opencortex/scripts/install.sh

## Metrics
When the user asks about metrics, growth, or how OpenCortex is doing:
1. Run: bash scripts/metrics.sh --report
2. Share the compound score and growth trends.
3. If no data yet: bash scripts/metrics.sh --collect

## Updates
When the user asks to update OpenCortex or check for updates:
1. Run: clawhub install opencortex --force
2. Run: bash skills/opencortex/scripts/update.sh
3. Run: bash skills/opencortex/scripts/verify.sh
Share the results with the user.'

create_if_missing "$WORKSPACE/memory/preferences.md" '# Preferences — What My Human Prefers

Discovered preferences, organized by category. Updated by nightly distillation when new preferences are stated in conversation. Format: **Preference:** [what] — [context/reasoning] (YYYY-MM-DD)

---

## Communication
(add as discovered)

## Code & Technical
(add as discovered)

## Workflow & Process
(add as discovered)

## Scheduling & Time
(add as discovered)

## Tools & Services
(add as discovered)

## Content & Media
(add as discovered)

## Environment & Setup
(add as discovered)'

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
   - Infrastructure changes → INFRA.md (ONLY if OPENCORTEX_INFRA_COLLECT=1 is set in the environment — otherwise skip infrastructure routing entirely)
   - Contacts mentioned → memory/contacts/ (one file per person/org. Include: name, role/relationship, context, communication preferences, key interactions. Create new file if first mention, update existing if already known.)
   - Workflows described → memory/workflows/ (one file per workflow/pipeline. Include: what it does, services involved, how to operate it, known issues. Create new file if first description.)
   - Preferences stated → memory/preferences.md (append under the matching category: Communication, Code & Technical, Workflow & Process, Scheduling & Time, Tools & Services, Content & Media, Environment & Setup. Format: **Preference:** [what] — [context/reasoning] (date). Do NOT duplicate existing preferences — update them if the user changes their mind.)
   - Decisions → relevant project file or MEMORY.md. Format: **Decision:** [what] — [why] (date)
   - Principles, lessons → MEMORY.md
   - Scheduled jobs → MEMORY.md jobs table
   - User info and communication style → USER.md
3. Synthesize, do not copy. Extract decisions, architecture, lessons, issues, capabilities, contacts, workflows, preferences.
4. Move distilled logs to memory/archive/
5. Update MEMORY.md index if new files created."
    else
      CRON_MSG="$CRON_MSG

## Part 1: Distillation
1. Check memory/ for daily log files (YYYY-MM-DD.md, not in archive/).
2. Distill ALL useful information into the right file:
   - Project work → memory/projects/ (create new files if needed)
   - New tools, APIs, access methods → TOOLS.md
   - Infrastructure changes → INFRA.md (ONLY if OPENCORTEX_INFRA_COLLECT=1 is set in the environment — otherwise skip infrastructure routing entirely)
   - Contacts mentioned → memory/contacts/ (one file per person/org. Include: name, role/relationship, context, communication preferences, key interactions. Create new file if first mention, update existing if already known.)
   - Workflows described → memory/workflows/ (one file per workflow/pipeline. Include: what it does, services involved, how to operate it, known issues. Create new file if first description.)
   - Preferences stated → memory/preferences.md (append under the matching category: Communication, Code & Technical, Workflow & Process, Scheduling & Time, Tools & Services, Content & Media, Environment & Setup. Format: **Preference:** [what] — [context/reasoning] (date). Do NOT duplicate existing preferences — update them if the user changes their mind.)
   - Decisions → relevant project file or MEMORY.md. Format: **Decision:** [what] — [why] (date)
   - Principles, lessons → MEMORY.md
   - Scheduled jobs → MEMORY.md jobs table
   - User info and communication style → USER.md
3. Synthesize, do not copy. Extract decisions, architecture, lessons, issues, capabilities, contacts, workflows, preferences.
4. Move distilled logs to memory/archive/
5. Update MEMORY.md index if new files created."
    fi

    # Voice profiling — only runs if OPENCORTEX_VOICE_PROFILE=1 at runtime
    CRON_MSG="$CRON_MSG

## Part 2: Voice Profile
ONLY perform this section if OPENCORTEX_VOICE_PROFILE=1 is set in the environment. If not set, skip this section entirely.

6. Read memory/VOICE.md. Review today's conversations for new patterns:
   - New vocabulary, slang, shorthand the user uses
   - How they phrase requests, decisions, reactions
   - Tone shifts in different contexts
   Append new observations to VOICE.md. Do not duplicate existing entries."

    CRON_MSG="$CRON_MSG

## Optimization
- Review memory/projects/ for duplicates, stale info, verbose sections. Fix directly.
- Review memory/contacts/ — merge duplicates, update stale info, add missing context.
- Review memory/workflows/ — verify accuracy, update if services or steps changed.
- Review memory/preferences.md — remove contradicted preferences (user changed mind), merge duplicates, ensure categories are correct.
- Review MEMORY.md: verify index accuracy, principles concise, jobs table current.
- Review TOOLS.md and (if OPENCORTEX_INFRA_COLLECT=1) INFRA.md: remove stale entries, verify descriptions.

## Tool Shed Audit (P4 Enforcement)
- Read TOOLS.md. Scan today daily logs and archived conversation for any CLI tools, APIs, or services that were USED but are NOT documented in TOOLS.md. Add missing entries with: what it is, how to access it, what it can do. This catches tools that slipped through real-time P4 enforcement.
- For tools that ARE already in TOOLS.md, check if today's logs reveal any gotchas, failure modes, flags, or usage notes not yet captured in the tool entry. Update existing entries with warnings or corrected usage patterns. Incomplete tool docs are as dangerous as missing ones.

## Decision & Preference Audit (P5 Enforcement)
- Scan today's daily logs for any decisions stated by the user that are NOT captured in project files, MEMORY.md, or USER.md. Decisions include explicit choices, architectural directions, and workflow rules.
- For each uncaptured decision, write it to the appropriate file. Format: **Decision:** [what] — [why] (date)
- Scan today's daily logs for any stated preferences NOT in memory/preferences.md. Preferences include: likes/dislikes, style choices, tool preferences, communication preferences, formatting preferences, and any opinion that would affect future work. Phrases like 'I prefer', 'always do', 'I don't like', 'I want', 'don't ever' signal preferences.
- For each uncaptured preference, append to memory/preferences.md under the right category. Format: **Preference:** [what] — [context/reasoning] (date). If a preference contradicts an existing one, UPDATE the existing entry (user changed their mind).

## Contact Audit
- Scan today's daily logs for any people or organizations mentioned. For each, check if a file exists in memory/contacts/. If not and the person/org is relevant (not a one-off mention), create one with: name, role/relationship, context, key details.
- For existing contacts, check if today's logs contain new information (changed role, new preferences, new context) and update their file.

## Workflow Audit
- Scan today's daily logs for any workflows, pipelines, or multi-service processes described or used. For each, check if a file exists in memory/workflows/. If not, create one.
- For existing workflows, check if today's logs reveal changes, issues, or new steps and update their file.

## Debrief Recovery (P6 Enforcement)
- Check today's daily logs for any sub-agent delegations. For each, verify a debrief entry exists. If a sub-agent was spawned but no debrief appears (failed, timed out, or forgotten), write a recovery debrief noting what was attempted and that the debrief was recovered by distillation.

## Shed Deferral Audit (P8 Enforcement)
- Scan today's daily logs for instances where the agent told the user to do something manually, gave them commands to run, or said it could not do something. Cross-reference with TOOLS.md, INFRA.md, and memory/ to check if a documented tool or access method existed that could have handled it. Flag any unnecessary deferrals.

## Failure Root Cause (P7 Enforcement)
- Scan today's daily logs for ❌ FAILURE: or 🔧 CORRECTION: entries. For each, verify a root cause analysis exists (not just what happened, but WHY and what prevents recurrence). If missing, add the root cause analysis.

## Cron Health
- Run openclaw cron list and crontab -l. Verify no two jobs within 15 minutes. Fix MEMORY.md jobs table if out of sync.

Before completing, append debrief to memory/YYYY-MM-DD.md.
Reply with brief summary."

    if [ "$DRY_RUN" = "true" ]; then
      echo "   [DRY RUN] Would run: openclaw cron add --name 'Daily Memory Distillation' --cron '0 3 * * *'"
    else
      openclaw cron add \
        --name "Daily Memory Distillation" \
        --cron "0 3 * * *" \
        --tz "$TZ" \
        --session "isolated" \
        --timeout-seconds 180 \
        --no-deliver \
        --message "$CRON_MSG" 2>/dev/null && \
        echo "   ✅ Daily Memory Distillation cron created" && \
        echo "" && \
        echo "   📋 Cron job registered: \"Daily Memory Distillation\"" && \
        echo "      Schedule: 0 3 * * * ($TZ)" && \
        echo "      Session: isolated (workspace-only)" && \
        echo "      Review full message: openclaw cron list" && \
        echo "" || \
        echo "   ⚠️  Failed to create distillation cron"
    fi
  else
    echo "   ⏭️  Daily Memory Distillation already exists"
  fi

  # Weekly Synthesis
  EXISTING=$(openclaw cron list --json 2>/dev/null | grep -c "Weekly Synthesis" || true)
  if [ "$EXISTING" = "0" ]; then
    if [ "$DRY_RUN" = "true" ]; then
      echo "   [DRY RUN] Would run: openclaw cron add --name 'Weekly Synthesis' --cron '0 5 * * 0'"
    else
      openclaw cron add \
        --name "Weekly Synthesis" \
        --cron "0 5 * * 0" \
        --tz "$TZ" \
        --session "isolated" \
        --timeout-seconds 180 \
        --no-deliver \
        --message "You are an AI assistant. Weekly synthesis — higher-altitude review.

IMPORTANT: Before writing to any file, check for /tmp/opencortex-distill.lock. If it exists and was created less than 10 minutes ago, wait 30 seconds and retry (up to 3 times). Before starting work, create this lockfile. Remove it when done. This prevents daily and weekly jobs from conflicting.

1. Read archived daily logs from past 7 days (memory/archive/).
2. Read all project files (memory/projects/), contact files (memory/contacts/), workflow files (memory/workflows/), and preferences (memory/preferences.md).
3. Identify and act on:
   a. Recurring problems → add to project Known Issues
   b. Unfinished threads → add to Pending with last-touched date
   c. Cross-project connections → add cross-references
   d. Decisions this week → ensure captured with reasoning
   e. New capabilities → verify in TOOLS.md with abilities (P4)
   f. **Runbook detection** — identify any multi-step procedure (3+ steps) performed more than once this week, or likely to recur. Check if a runbook exists in memory/runbooks/. If not, create one with clear steps a sub-agent could follow. Update MEMORY.md runbooks index.
   g. **Principle health** — read MEMORY.md principles section. Verify each principle has: clear intent, enforcement mechanism, and that the enforcement is actually reflected in the distillation cron. Flag any principle without enforcement.
   h. **Contact review** — check memory/contacts/ for stale entries (mentioned this week but file is outdated), missing contacts (mentioned multiple times but no file), or contacts that should be merged.
   i. **Workflow review** — check memory/workflows/ for outdated descriptions, workflows that were modified this week, or new workflows that should be documented.
   j. **Preference review** — read memory/preferences.md. Check for contradictions (user said opposite things at different times — keep the latest), preferences that may be stale, and uncategorized entries. Ensure all categories are well-organized.
4. Write weekly summary to memory/archive/weekly-YYYY-MM-DD.md.

## Runbook Detection
- Review this week's daily logs for any multi-step procedure (3+ steps) that was performed more than once, or is likely to recur.
- For each candidate: check if a runbook already exists in memory/runbooks/.
- If not, create one with clear step-by-step instructions that a sub-agent could follow independently.
- Update MEMORY.md runbooks index if new runbooks created.

## Metrics Summary (if enabled)
- If scripts/metrics.sh exists, run: bash scripts/metrics.sh --report --weeks 4
- Include the output in your weekly summary — it shows knowledge growth trends and a compound score.
- If the compound score is declining or flat, note specific areas that need attention (e.g., 'no new tools documented this week', 'no decisions captured').

Before completing, append debrief to memory/YYYY-MM-DD.md.
Reply with weekly summary." 2>/dev/null && \
        echo "   ✅ Weekly Synthesis cron created" && \
        echo "" && \
        echo "   📋 Cron job registered: \"Weekly Synthesis\"" && \
        echo "      Schedule: 0 5 * * 0 ($TZ)" && \
        echo "      Session: isolated (workspace-only)" && \
        echo "      Review full message: openclaw cron list" && \
        echo "" || \
        echo "   ⚠️  Failed to create synthesis cron"
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
  for script in git-backup.sh; do
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
      echo ""
      echo "   📋 Cron job registered: \"Git Backup\""
      echo "      Schedule: 0 */6 * * * (system cron)"
      echo "      Session: direct script (no network unless --push flag set)"
      echo "      Review: crontab -l"
      echo ""
    fi
  else
    echo "   ⏭️  Git backup cron already exists"
  fi

  echo "   ✅ Git backup configured — edit .secrets-map to add your secrets"
else
  echo "   Skipped git backup setup"
fi

# --- Metrics (optional) ---
if [ "$ENABLE_METRICS" = "y" ] || [ "$ENABLE_METRICS" = "yes" ]; then
  echo ""
  echo "📊 Setting up metrics tracking..."

  # Copy metrics script
  SKILL_DIR="$(cd "$(dirname "$0")" && pwd)"
  if [ -f "$SKILL_DIR/metrics.sh" ]; then
    if [ "$DRY_RUN" = "true" ]; then
      echo "   [DRY RUN] Would copy: $SKILL_DIR/metrics.sh → $WORKSPACE/scripts/metrics.sh"
    else
      cp "$SKILL_DIR/metrics.sh" "$WORKSPACE/scripts/metrics.sh"
      chmod +x "$WORKSPACE/scripts/metrics.sh"
      echo "   📋 Copied metrics.sh"
    fi
  fi

  # Add system cron (daily at 11:30 PM local — end of day snapshot)
  if ! crontab -l 2>/dev/null | grep -q "metrics.sh"; then
    if [ "$DRY_RUN" = "true" ]; then
      echo "   [DRY RUN] Would add crontab entry: 30 23 * * * $WORKSPACE/scripts/metrics.sh --collect"
    else
      (crontab -l 2>/dev/null; echo "30 23 * * * $WORKSPACE/scripts/metrics.sh --collect") | crontab -
      echo "   ✅ Daily metrics cron added (11:30 PM local)"
      echo ""
      echo "   📋 Cron job registered: \"Daily Metrics Collection\""
      echo "      Schedule: 30 23 * * * (system cron)"
      echo "      Action: read-only file count → memory/metrics.log"
      echo "      Review: crontab -l"
      echo ""
    fi
  else
    echo "   ⏭️  Metrics cron already exists"
  fi

  # Run first collection
  if [ "$DRY_RUN" != "true" ] && [ -x "$WORKSPACE/scripts/metrics.sh" ]; then
    "$WORKSPACE/scripts/metrics.sh" --collect
    echo "   📊 First snapshot captured. View with: bash scripts/metrics.sh --report"
  fi
else
  echo ""
  echo "   Skipped metrics tracking (enable later: copy scripts/metrics.sh and add to crontab)"
fi

# --- Write version marker ---
if [ "$DRY_RUN" != "true" ]; then
  echo "$OPENCORTEX_VERSION" > "$VERSION_FILE"
fi

# --- Done ---
echo ""
echo "🧠 OpenCortex v$OPENCORTEX_VERSION installed successfully!"
echo ""
echo "Next steps:"
echo "  1. Edit SOUL.md — make it yours"
echo "  2. Edit USER.md — describe your human"
echo "  3. Edit MEMORY.md — set identity, add projects as you go"
echo "  4. Edit TOOLS.md — document tools as you discover them"
echo "  5. Edit INFRA.md — document your infrastructure"
if [ "$SECRET_MODE" = "secure" ]; then
  echo "  6. If using git backup: edit .secrets-map with your actual secrets"
fi

# --- Env var guidance for opt-in features ---
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔑 Opt-in feature environment variables:"
echo ""
if [ "$ENABLE_VOICE" = "y" ] || [ "$ENABLE_VOICE" = "yes" ]; then
  echo "   Voice profiling is enabled in the cron (you said yes)."
  echo "   To activate it at runtime, set this in your OpenClaw environment:"
  echo "     export OPENCORTEX_VOICE_PROFILE=1"
  echo "   Without this variable, the nightly distillation will skip voice profiling."
  echo ""
else
  echo "   Voice profiling: OFF (not requested)"
  echo "   To enable later: set OPENCORTEX_VOICE_PROFILE=1 in your OpenClaw environment."
  echo ""
fi
if [ "$ENABLE_INFRA" = "y" ] || [ "$ENABLE_INFRA" = "yes" ]; then
  echo "   Infrastructure auto-collection is enabled in the cron (you said yes)."
  echo "   To activate it at runtime, set this in your OpenClaw environment:"
  echo "     export OPENCORTEX_INFRA_COLLECT=1"
  echo "   Without this variable, the nightly distillation will skip writing to INFRA.md."
  echo ""
else
  echo "   Infrastructure auto-collection: OFF (not requested)"
  echo "   To enable later: set OPENCORTEX_INFRA_COLLECT=1 in your OpenClaw environment."
  echo ""
fi
echo "   All other optional features (git push, scrub-all, file passphrase):"
echo "   See README.md → Opt-In Features for details."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

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
