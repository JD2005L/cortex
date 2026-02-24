#!/bin/bash
# OpenCortex — Non-destructive update script
# Adds missing content to your workspace. Never overwrites files you've customized.
# Cron job messages are updated to the latest templates.
# Run from your OpenClaw workspace directory: bash skills/opencortex/scripts/update.sh

set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────────
# Flags
# ─────────────────────────────────────────────────────────────────────────────
DRY_RUN=false
for arg in "$@"; do
  [[ "$arg" == "--dry-run" ]] && DRY_RUN=true
done

if [ "$DRY_RUN" = "true" ]; then
  echo "⚠️  DRY RUN MODE — nothing will be changed."
  echo ""
fi

WORKSPACE="${CLAWD_WORKSPACE:-$(pwd)}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "🔄 OpenCortex Update"
echo "   Workspace: $WORKSPACE"
echo "   Script:    $SCRIPT_DIR"
echo ""

UPDATED=0
SKIPPED=0

# ─────────────────────────────────────────────────────────────────────────────
# Part 1: Cron job messages — update to latest templates
# ─────────────────────────────────────────────────────────────────────────────
echo "⏰ Checking cron job messages..."

DAILY_MSG=$(cat <<'EOMSG'
You are an AI assistant. Daily memory maintenance task.

IMPORTANT: Before writing to any file, check for /tmp/opencortex-distill.lock. If it exists and was created less than 10 minutes ago, wait 30 seconds and retry (up to 3 times). Before starting work, create this lockfile. Remove it when done. This prevents daily and weekly jobs from conflicting.

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
5. Update MEMORY.md index if new files created.

## Optimization
- Review memory/projects/ for duplicates, stale info, verbose sections. Fix directly.
- Review MEMORY.md: verify index accuracy, principles concise, jobs table current.
- Review TOOLS.md and INFRA.md: remove stale entries, verify descriptions.

## Tool Shed Audit (P4 Enforcement)
- Read TOOLS.md. Scan today daily logs and archived conversation for any CLI tools, APIs, or services that were USED but are NOT documented in TOOLS.md. Add missing entries with: what it is, how to access it, what it can do. This catches tools that slipped through real-time P4 enforcement.
- For tools that ARE already in TOOLS.md, check if today's logs reveal any gotchas, failure modes, flags, or usage notes not yet captured in the tool entry. Update existing entries with warnings or corrected usage patterns. Incomplete tool docs are as dangerous as missing ones.

## Decision Audit (P5 Enforcement)
- Scan today's daily logs for any decisions, preferences, or architectural directions stated by the user that are NOT captured in project files, MEMORY.md, or USER.md. Decisions include explicit choices, stated preferences, architectural directions, and workflow rules.
- For each uncaptured decision, write it to the appropriate file. Format: **Decision:** [what] — [why] (date)

## Debrief Recovery (P6 Enforcement)
- Check today's daily logs for any sub-agent delegations. For each, verify a debrief entry exists. If a sub-agent was spawned but no debrief appears (failed, timed out, or forgotten), write a recovery debrief noting what was attempted and that the debrief was recovered by distillation.

## Shed Deferral Audit (P8 Enforcement)
- Scan today's daily logs for instances where the agent told the user to do something manually, gave them commands to run, or said it could not do something. Cross-reference with TOOLS.md, INFRA.md, and memory/ to check if a documented tool or access method existed that could have handled it. Flag any unnecessary deferrals.

## Failure Root Cause (P7 Enforcement)
- Scan today's daily logs for ❌ FAILURE: or 🔧 CORRECTION: entries. For each, verify a root cause analysis exists (not just what happened, but WHY and what prevents recurrence). If missing, add the root cause analysis.

## Cron Health
- Run openclaw cron list and crontab -l. Verify no two jobs within 15 minutes. Fix MEMORY.md jobs table if out of sync.

Before completing, append debrief to memory/YYYY-MM-DD.md.
Reply with brief summary.
EOMSG
)

WEEKLY_MSG=$(cat <<'EOMSG'
You are an AI assistant. Weekly synthesis — higher-altitude review.

IMPORTANT: Before writing to any file, check for /tmp/opencortex-distill.lock. If it exists and was created less than 10 minutes ago, wait 30 seconds and retry (up to 3 times). Before starting work, create this lockfile. Remove it when done. This prevents daily and weekly jobs from conflicting.

1. Read archived daily logs from past 7 days (memory/archive/).
2. Read all project files (memory/projects/).
3. Identify and act on:
   a. Recurring problems → add to project Known Issues
   b. Unfinished threads → add to Pending with last-touched date
   c. Cross-project connections → add cross-references
   d. Decisions this week → ensure captured with reasoning
   e. New capabilities → verify in TOOLS.md with abilities (P4)
   f. **Runbook detection** — identify any multi-step procedure (3+ steps) performed more than once this week, or likely to recur. Check if a runbook exists in memory/runbooks/. If not, create one with clear steps a sub-agent could follow. Update MEMORY.md runbooks index.
   g. **Principle health** — read MEMORY.md principles section. Verify each principle has: clear intent, enforcement mechanism, and that the enforcement is actually reflected in the distillation cron. Flag any principle without enforcement.
4. Write weekly summary to memory/archive/weekly-YYYY-MM-DD.md.

## Runbook Detection
- Review this week's daily logs for any multi-step procedure (3+ steps) that was performed more than once, or is likely to recur.
- For each candidate: check if a runbook already exists in memory/runbooks/.
- If not, create one with clear step-by-step instructions that a sub-agent could follow independently.
- Update MEMORY.md runbooks index if new runbooks created.

Before completing, append debrief to memory/YYYY-MM-DD.md.
Reply with weekly summary.
EOMSG
)

if command -v openclaw &>/dev/null; then
  # Get JSON cron list and extract IDs using python3
  CRON_JSON=$(openclaw cron list --json 2>/dev/null || echo "[]")

  get_cron_id() {
    local name="$1"
    echo "$CRON_JSON" | python3 -c "
import sys, json
raw = sys.stdin.read().strip()
try:
    data = json.loads(raw)
except Exception:
    sys.exit(0)
items = data if isinstance(data, list) else data.get('crons', data.get('jobs', data.get('data', [])))
if not isinstance(items, list):
    sys.exit(0)
search = sys.argv[1].lower()
for item in items:
    if isinstance(item, dict):
        n = str(item.get('name', '')).lower()
        if search in n:
            cid = item.get('id', item.get('_id', item.get('uuid', '')))
            if cid:
                print(cid)
            break
" "$name" 2>/dev/null || true
  }

  DAILY_ID=$(get_cron_id "Daily Memory Distillation")
  WEEKLY_ID=$(get_cron_id "Weekly Synthesis")

  if [ -n "$DAILY_ID" ]; then
    if [ "$DRY_RUN" = "true" ]; then
      echo "   [DRY RUN] Would update 'Daily Memory Distillation' (id: $DAILY_ID) message"
      UPDATED=$((UPDATED + 1))
    else
      openclaw cron edit "$DAILY_ID" --message "$DAILY_MSG" 2>/dev/null \
        && echo "   ✅ Updated 'Daily Memory Distillation' cron message" \
        && UPDATED=$((UPDATED + 1)) \
        || echo "   ⚠️  Could not update 'Daily Memory Distillation' — run manually: openclaw cron edit $DAILY_ID --message '...'"
    fi
  else
    echo "   ⏭️  'Daily Memory Distillation' cron not found — run install.sh to create it"
    SKIPPED=$((SKIPPED + 1))
  fi

  if [ -n "$WEEKLY_ID" ]; then
    if [ "$DRY_RUN" = "true" ]; then
      echo "   [DRY RUN] Would update 'Weekly Synthesis' (id: $WEEKLY_ID) message"
      UPDATED=$((UPDATED + 1))
    else
      openclaw cron edit "$WEEKLY_ID" --message "$WEEKLY_MSG" 2>/dev/null \
        && echo "   ✅ Updated 'Weekly Synthesis' cron message" \
        && UPDATED=$((UPDATED + 1)) \
        || echo "   ⚠️  Could not update 'Weekly Synthesis' — run manually: openclaw cron edit $WEEKLY_ID --message '...'"
    fi
  else
    echo "   ⏭️  'Weekly Synthesis' cron not found — run install.sh to create it"
    SKIPPED=$((SKIPPED + 1))
  fi
else
  echo "   ⚠️  openclaw CLI not found — skipping cron updates"
  SKIPPED=$((SKIPPED + 1))
fi
echo ""

# ─────────────────────────────────────────────────────────────────────────────
# Part 2: Principles — add any missing P1–P8 to MEMORY.md
# ─────────────────────────────────────────────────────────────────────────────
echo "📜 Checking principles in MEMORY.md..."

if [ ! -f "$WORKSPACE/MEMORY.md" ]; then
  echo "   ⚠️  MEMORY.md not found — skipping principles check (run install.sh first)"
  SKIPPED=$((SKIPPED + 1))
else
  # Build associative array: principle number → full block text
  declare -A PRINCIPLE_TEXTS

  PRINCIPLE_TEXTS["P1"]=$(cat <<'EOPR'
### P1: Delegate First
Assess every task for sub-agent delegation before starting. Stay available.
- **Haiku:** File ops, searches, data extraction, simple scripts, monitoring
- **Sonnet:** Multi-step work, code writing, debugging, research
- **Opus:** Complex reasoning, architecture decisions, sensitive ops
- **Keep main thread for:** Conversation, decisions, confirmations, quick answers
EOPR
)

  PRINCIPLE_TEXTS["P2"]=$(cat <<'EOPR'
### P2: Write It Down
Do not mentally note — commit to memory files. Update indexes after significant work.
EOPR
)

  PRINCIPLE_TEXTS["P3"]=$(cat <<'EOPR'
### P3: Ask Before External Actions
Emails, public posts, destructive ops — get confirmation first.
EOPR
)

  PRINCIPLE_TEXTS["P4"]=$(cat <<'EOPR'
### P4: Tool Shed
All tools, APIs, access methods, and capabilities SHALL be documented in TOOLS.md with goal-oriented abilities descriptions. When given a new tool during work, immediately add it.
**Creation:** When you access a new system, API, or resource more than once — or when given access to something that will clearly recur — proactively create the tool entry, bridge doc, or helper script. Do not wait to be asked. The bar is: if future-me would need to figure this out again, build the tool now.
**Enforcement:** After using any CLI tool, API, or service — before ending the task — verify it exists in TOOLS.md. If not, add it immediately. Do not defer to distillation.
EOPR
)

  PRINCIPLE_TEXTS["P5"]=$(cat <<'EOPR'
### P5: Capture Decisions
When the user makes a decision or states a preference, immediately record it in the relevant file with reasoning. Never re-ask something already decided. Format: **Decision:** [what] — [why] (date)
**Recognition:** Decisions include: explicit choices, stated preferences, architectural directions, and workflow rules. If the user expresses an opinion that would affect future work, that is a decision — capture it.
**Enforcement:** Before ending any conversation with substantive work, scan for uncaptured decisions. If any, write them before closing.
EOPR
)

  PRINCIPLE_TEXTS["P6"]=$(cat <<'EOPR'
### P6: Sub-agent Debrief
Sub-agents MUST write a brief debrief to memory/YYYY-MM-DD.md before completing. Include: what was done, what was learned, any issues.
**Recovery:** If a sub-agent fails, times out, or is killed before debriefing, the parent agent writes the debrief on its behalf noting the failure mode. No delegated work should vanish from memory.
EOPR
)

  PRINCIPLE_TEXTS["P7"]=$(cat <<'EOPR'
### P7: Log Failures
When something fails or the user corrects you, immediately append to the daily log with ❌ FAILURE: or 🔧 CORRECTION: tags. Include: what happened, why it failed, what fixed it. Nightly distillation routes these to the right file.
**Root cause:** Do not just log what happened — log *why* it happened and what would prevent it next time. If it is a systemic issue (missing principle, bad assumption, tool gap), propose a fix immediately.
EOPR
)

  PRINCIPLE_TEXTS["P8"]=$(cat <<'EOPR'
### P8: Check the Shed First
Before telling the user you cannot do something, or asking them to do it manually, CHECK your resources: TOOLS.md, INFRA.md, memory/projects/, runbooks, and any bridge docs. If a tool, API, credential, or access method exists that could accomplish the task — use it. The shed exists so you do not make the user do work you are equipped to handle.
**Enforcement:** Nightly audit scans for instances where the agent deferred work to the user that could have been done via documented tools.
EOPR
)

  # Collect missing principles
  MISSING_PRINCIPLES=()
  for pnum in P1 P2 P3 P4 P5 P6 P7 P8; do
    if grep -q "^### ${pnum}:" "$WORKSPACE/MEMORY.md" 2>/dev/null; then
      echo "   ⏭️  ${pnum} already exists (skipped)"
      SKIPPED=$((SKIPPED + 1))
    else
      echo "   ⚠️  ${pnum} missing — will add"
      MISSING_PRINCIPLES+=("$pnum")
    fi
  done

  if [ ${#MISSING_PRINCIPLES[@]} -gt 0 ]; then
    if [ "$DRY_RUN" = "true" ]; then
      echo "   [DRY RUN] Would add missing principles: ${MISSING_PRINCIPLES[*]}"
      UPDATED=$((UPDATED + ${#MISSING_PRINCIPLES[@]}))
    else
      # Write all missing principles to a temp file
      TEMP_P=$(mktemp)
      for pnum in "${MISSING_PRINCIPLES[@]}"; do
        printf '\n%s\n' "${PRINCIPLE_TEXTS[$pnum]}" >> "$TEMP_P"
      done

      # Insert before "## Identity" if it exists, otherwise append
      python3 - "$WORKSPACE/MEMORY.md" "$TEMP_P" <<'PYEOF'
import sys

mem_path = sys.argv[1]
new_content_path = sys.argv[2]

with open(mem_path, 'r') as f:
    content = f.read()

with open(new_content_path, 'r') as f:
    new_content = f.read()

# Try to insert before ## Identity
if '\n## Identity' in content:
    content = content.replace('\n## Identity', new_content + '\n\n## Identity', 1)
elif '\n---\n' in content:
    # Insert before the first --- divider after PRINCIPLES header
    idx = content.find('\n---\n')
    content = content[:idx] + new_content + content[idx:]
else:
    content = content.rstrip('\n') + '\n' + new_content

with open(mem_path, 'w') as f:
    f.write(content)
PYEOF

      rm -f "$TEMP_P"
      for pnum in "${MISSING_PRINCIPLES[@]}"; do
        echo "   ✅ Added principle ${pnum}"
        UPDATED=$((UPDATED + 1))
      done
    fi
  fi
fi
echo ""

# ─────────────────────────────────────────────────────────────────────────────
# Part 3: Scripts — copy any missing helper scripts to workspace
# ─────────────────────────────────────────────────────────────────────────────
echo "📋 Checking helper scripts..."

copy_script_if_missing() {
  local script_name="$1"
  local src="$SCRIPT_DIR/$script_name"
  local dst="$WORKSPACE/scripts/$script_name"

  if [ ! -f "$src" ]; then
    echo "   ⏭️  $script_name not found in skill package (skipped)"
    SKIPPED=$((SKIPPED + 1))
    return
  fi

  if [ -f "$dst" ]; then
    echo "   ⏭️  $script_name already in workspace scripts/ (skipped)"
    SKIPPED=$((SKIPPED + 1))
    return
  fi

  if [ "$DRY_RUN" = "true" ]; then
    echo "   [DRY RUN] Would copy: $src → $dst"
    UPDATED=$((UPDATED + 1))
  else
    mkdir -p "$WORKSPACE/scripts"
    cp "$src" "$dst"
    chmod +x "$dst"
    echo "   ✅ Copied $script_name to workspace scripts/"
    UPDATED=$((UPDATED + 1))
  fi
}

copy_script_if_missing "verify.sh"
copy_script_if_missing "vault.sh"

echo ""

# ─────────────────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────────────────
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "   ✅ Updated: $UPDATED"
echo "   ⏭️  Skipped (already current): $SKIPPED"
echo ""

if [ "$DRY_RUN" = "true" ]; then
  echo "   Dry run complete. Re-run without --dry-run to apply changes."
else
  echo "   Update complete. Run verify.sh to confirm everything is healthy:"
  echo "   bash skills/opencortex/scripts/verify.sh"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
