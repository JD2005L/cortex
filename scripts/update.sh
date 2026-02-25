#!/bin/bash
# OpenCortex — Non-destructive update script
# Adds missing content to your workspace. Never overwrites files you've customized.
# Cron job messages are updated to the latest templates.
# Run from your OpenClaw workspace directory: bash skills/opencortex/scripts/update.sh

set -euo pipefail

OPENCORTEX_VERSION="3.0.7"

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
5. Update MEMORY.md index if new files created.

## Optimization
- Review memory/projects/ for duplicates, stale info, verbose sections. Fix directly.
- Review memory/contacts/ — merge duplicates, update stale info, add missing context.
- Review memory/workflows/ — verify accuracy, update if services or steps changed.
- Review memory/preferences.md — remove contradicted preferences (user changed mind), merge duplicates, ensure categories are correct.
- Review MEMORY.md: verify index accuracy, principles concise, jobs table current.
- Review TOOLS.md and (if OPENCORTEX_INFRA_COLLECT=1) INFRA.md: remove stale entries, verify descriptions.

## Tool Shed Audit (P4 Enforcement)
- Read TOOLS.md. Scan today daily logs and archived conversation for any CLI tools, APIs, or services that were USED but are NOT documented in TOOLS.md. Add missing entries with: what it is, how to access it, what it can do.
- For tools that ARE already in TOOLS.md, check if today's logs reveal any gotchas, failure modes, flags, or usage notes not yet captured. Update existing entries.

## Decision & Preference Audit (P5 Enforcement)
- Scan today's daily logs for any decisions stated by the user that are NOT captured in project files, MEMORY.md, or USER.md.
- For each uncaptured decision, write it to the appropriate file. Format: **Decision:** [what] — [why] (date)
- Scan today's daily logs for any stated preferences NOT in memory/preferences.md. Phrases like "I prefer", "always do", "I don't like", "I want", "don't ever" signal preferences.
- For each uncaptured preference, append to memory/preferences.md under the right category. Format: **Preference:** [what] — [context/reasoning] (date). If contradicts existing, UPDATE existing.

## Contact Audit
- Scan today's daily logs for any people or organizations mentioned. For each, check if a file exists in memory/contacts/. If not and relevant, create one.
- For existing contacts, update with new information from today's logs.

## Workflow Audit
- Scan today's daily logs for any workflows, pipelines, or multi-service processes. For each, check if a file exists in memory/workflows/. If not, create one.
- For existing workflows, update if today's logs reveal changes or issues.

## Debrief Recovery (P6 Enforcement)
- Check today's daily logs for any sub-agent delegations. For each, verify a debrief entry exists. If missing, write a recovery debrief.

## Shed Deferral Audit (P8 Enforcement)
- Scan today's daily logs for instances where the agent deferred to the user. Cross-reference with TOOLS.md, INFRA.md, and memory/. Flag unnecessary deferrals.

## Failure Root Cause (P7 Enforcement)
- Scan today's daily logs for ❌ FAILURE: or 🔧 CORRECTION: entries. Verify root cause analysis exists. If missing, add it.

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
2. Read all project files (memory/projects/), contact files (memory/contacts/), workflow files (memory/workflows/), and preferences (memory/preferences.md).
3. Identify and act on:
   a. Recurring problems → add to project Known Issues
   b. Unfinished threads → add to Pending with last-touched date
   c. Cross-project connections → add cross-references
   d. Decisions this week → ensure captured with reasoning
   e. New capabilities → verify in TOOLS.md with abilities (P4)
   f. **Runbook detection** — identify any multi-step procedure (3+ steps) performed more than once this week, or likely to recur. Check if a runbook exists in memory/runbooks/. If not, create one with clear steps a sub-agent could follow. Update MEMORY.md runbooks index.
   g. **Principle health** — read MEMORY.md principles section. Verify each principle has: clear intent, enforcement mechanism, and that the enforcement is actually reflected in the distillation cron. Flag any principle without enforcement.
   h. **Contact review** — check memory/contacts/ for stale entries, missing contacts, or contacts that should be merged.
   i. **Workflow review** — check memory/workflows/ for outdated descriptions or new workflows.
   j. **Preference review** — read memory/preferences.md. Check for contradictions, stale preferences, and organization.
4. Write weekly summary to memory/archive/weekly-YYYY-MM-DD.md.

## Runbook Detection
- Review this week's daily logs for any multi-step procedure (3+ steps) that was performed more than once, or is likely to recur.
- For each candidate: check if a runbook already exists in memory/runbooks/.
- If not, create one with clear step-by-step instructions that a sub-agent could follow independently.
- Update MEMORY.md runbooks index if new runbooks created.

## Metrics Summary (if enabled)
- If scripts/metrics.sh exists, run: bash scripts/metrics.sh --report --weeks 4
- Include the output in your weekly summary.
- If the compound score is declining or flat, note specific areas that need attention.

Before completing, append debrief to memory/YYYY-MM-DD.md.
Reply with weekly summary.
EOMSG
)

if command -v openclaw &>/dev/null; then
  # Get JSON cron list and extract IDs
  CRON_JSON=$(openclaw cron list --json 2>/dev/null || echo "[]")

  get_cron_id() {
    local name="$1"
    local name_lower
    name_lower=$(echo "$name" | tr '[:upper:]' '[:lower:]')
    # Parse JSON with grep/awk — look for "name" field matching, then grab preceding "id" field
    echo "$CRON_JSON" | tr ',' '\n' | tr '{' '\n' | tr '}' '\n' | sed 's/^ *//' | awk -v search="$name_lower" '
      /^"id"/ || /^"_id"/ || /^"uuid"/ { gsub(/[" ]/, ""); split($0, a, ":"); last_id=a[2] }
      /^"name"/ { gsub(/["]/, ""); sub(/^name: */, ""); n=tolower($0); if (index(n, search) > 0 && last_id != "") { print last_id; exit } }
    ' 2>/dev/null || true
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
### P4: Tool Shed & Workflows
All tools, APIs, access methods, and capabilities SHALL be documented in TOOLS.md with goal-oriented abilities descriptions. When given a new tool during work, immediately add it. Document workflows and pipelines in memory/workflows/ with clear descriptions of what they do, how they connect, and how to operate them.
**Creation:** When you access a new system, API, or resource more than once — or when given access to something that will clearly recur — proactively create the tool entry, bridge doc, or helper script. When a multi-service workflow is described or used, document it in memory/workflows/. Do not wait to be asked.
**Enforcement:** After using any CLI tool, API, or service — before ending the task — verify it exists in TOOLS.md. If not, add it immediately. Do not defer to distillation.
EOPR
)

  PRINCIPLE_TEXTS["P5"]=$(cat <<'EOPR'
### P5: Capture Decisions & Preferences
When the user makes a decision or states a preference, immediately record it. Decisions go in the relevant project/memory file. Preferences go in memory/preferences.md under the right category. Never re-ask something already decided or stated.
**Decisions format:** **Decision:** [what] — [why] (date) — in the relevant project or memory file.
**Preferences format:** **Preference:** [what] — [context/reasoning] (date) — in memory/preferences.md under the matching category (Communication, Code & Technical, Workflow & Process, Scheduling & Time, Tools & Services, Content & Media, Environment & Setup).
**Recognition:** Decisions include: explicit choices, architectural directions, and workflow rules. Preferences include: stated likes/dislikes, communication style preferences, tool preferences, formatting preferences, and any opinion that would affect future work. If the user says "I prefer X" or "always do Y" or "I don't like Z" — that is a preference. Capture it immediately.
**Enforcement:** Before ending any conversation with substantive work, scan for uncaptured decisions AND preferences. If any, write them before closing.
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

  # Collect missing or outdated principles
  MISSING_PRINCIPLES=()
  OUTDATED_PRINCIPLES=()
  for pnum in P1 P2 P3 P4 P5 P6 P7 P8; do
    if grep -q "^### ${pnum}:" "$WORKSPACE/MEMORY.md" 2>/dev/null; then
      # Check if the principle title matches the latest version
      current_title=""
      current_title=$(grep "^### ${pnum}:" "$WORKSPACE/MEMORY.md" | head -1)
      expected_title=""
      expected_title=$(echo "${PRINCIPLE_TEXTS[$pnum]}" | head -1)
      if [ "$current_title" != "$expected_title" ]; then
        echo "   🔄 ${pnum} outdated — will update"
        OUTDATED_PRINCIPLES+=("$pnum")
      else
        echo "   ⏭️  ${pnum} already exists (skipped)"
        SKIPPED=$((SKIPPED + 1))
      fi
    else
      echo "   ⚠️  ${pnum} missing — will add"
      MISSING_PRINCIPLES+=("$pnum")
    fi
  done

  # Replace outdated principles in-place
  if [ ${#OUTDATED_PRINCIPLES[@]} -gt 0 ]; then
    if [ "$DRY_RUN" = "true" ]; then
      echo "   [DRY RUN] Would update principles: ${OUTDATED_PRINCIPLES[*]}"
    else
      for pnum in "${OUTDATED_PRINCIPLES[@]}"; do
        # Show what changed
        current_title=$(grep "^### ${pnum}:" "$WORKSPACE/MEMORY.md" | head -1)
        expected_title=$(echo "${PRINCIPLE_TEXTS[$pnum]}" | head -1)
        echo ""
        echo "   ${pnum} title change:"
        echo "     Current: $current_title"
        echo "     New:     $expected_title"
        echo ""
        echo "   ⚠️  Replacing will overwrite any custom additions you made to this principle."
        read -p "   Update ${pnum}? (y/N): " UPDATE_PRINCIPLE
        UPDATE_PRINCIPLE=$(echo "$UPDATE_PRINCIPLE" | tr '[:upper:]' '[:lower:]')
        if [ "$UPDATE_PRINCIPLE" = "y" ] || [ "$UPDATE_PRINCIPLE" = "yes" ]; then
          # Find the start and end line of the existing principle block
          start_line=""; end_line=""; next_section=""
          start_line=$(grep -n "^### ${pnum}:" "$WORKSPACE/MEMORY.md" | head -1 | cut -d: -f1)
          # Find the next ### or ## heading after start_line
          next_section=$(tail -n +"$((start_line + 1))" "$WORKSPACE/MEMORY.md" | grep -n "^###\|^## " | head -1 | cut -d: -f1)
          if [ -n "$next_section" ]; then
            end_line=$((start_line + next_section - 1))
          else
            end_line=$(wc -l < "$WORKSPACE/MEMORY.md")
          fi
          # Replace the block
          tmp_mem=$(mktemp)
          head -n "$((start_line - 1))" "$WORKSPACE/MEMORY.md" > "$tmp_mem"
          echo "${PRINCIPLE_TEXTS[$pnum]}" >> "$tmp_mem"
          echo "" >> "$tmp_mem"
          tail -n "+$((end_line + 1))" "$WORKSPACE/MEMORY.md" >> "$tmp_mem"
          mv "$tmp_mem" "$WORKSPACE/MEMORY.md"
          echo "   ✅ Updated ${pnum}"
          UPDATED=$((UPDATED + 1))
        else
          echo "   ⏭️  Kept existing ${pnum}"
          SKIPPED=$((SKIPPED + 1))
        fi
      done
    fi
  fi

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
      if grep -q "^## Identity" "$WORKSPACE/MEMORY.md"; then
        # Insert new principles before ## Identity line
        sed -i "/^## Identity/e cat $TEMP_P" "$WORKSPACE/MEMORY.md"
        # Add blank line before ## Identity if missing
        sed -i '/^## Identity/{x;/./{x;b};x;s/^/\n/}' "$WORKSPACE/MEMORY.md" 2>/dev/null || true
      elif grep -q "^---$" "$WORKSPACE/MEMORY.md"; then
        # Insert before first --- divider
        sed -i "0,/^---$/{ /^---$/e cat $TEMP_P
        }" "$WORKSPACE/MEMORY.md"
      else
        # Append to end
        cat "$TEMP_P" >> "$WORKSPACE/MEMORY.md"
      fi

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

copy_or_update_script() {
  local script_name="$1"
  local src="$SCRIPT_DIR/$script_name"
  local dst="$WORKSPACE/scripts/$script_name"

  if [ ! -f "$src" ]; then
    echo "   ⏭️  $script_name not found in skill package (skipped)"
    SKIPPED=$((SKIPPED + 1))
    return
  fi

  if [ -f "$dst" ]; then
    # Compare checksums — update if different
    local src_hash dst_hash
    src_hash=$(md5sum "$src" 2>/dev/null | cut -d' ' -f1)
    dst_hash=$(md5sum "$dst" 2>/dev/null | cut -d' ' -f1)
    if [ "$src_hash" = "$dst_hash" ]; then
      echo "   ⏭️  $script_name already current (skipped)"
      SKIPPED=$((SKIPPED + 1))
      return
    fi
    if [ "$DRY_RUN" = "true" ]; then
      echo "   [DRY RUN] Would update: $script_name"
    else
      cp "$src" "$dst"
      chmod +x "$dst"
      echo "   🔄 Updated $script_name"
    fi
    UPDATED=$((UPDATED + 1))
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

copy_or_update_script "verify.sh"
copy_or_update_script "vault.sh"
copy_or_update_script "metrics.sh"
copy_or_update_script "git-backup.sh"

# Create new directories if missing
for d in memory/contacts memory/workflows; do
  if [ ! -d "$WORKSPACE/$d" ]; then
    if [ "$DRY_RUN" = "true" ]; then
      echo "   [DRY RUN] Would create: $d/"
    else
      mkdir -p "$WORKSPACE/$d"
      echo "   📁 Created $d/"
      UPDATED=$((UPDATED + 1))
    fi
  fi
done

# Create preferences.md if missing
if [ ! -f "$WORKSPACE/memory/preferences.md" ]; then
  if [ "$DRY_RUN" = "true" ]; then
    echo "   [DRY RUN] Would create: memory/preferences.md"
  else
    cat > "$WORKSPACE/memory/preferences.md" <<'PREFEOF'
# Preferences — What My Human Prefers

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
(add as discovered)
PREFEOF
    echo "   📝 Created memory/preferences.md"
    UPDATED=$((UPDATED + 1))
  fi
fi

# Add missing MEMORY.md index sections
if [ -f "$WORKSPACE/MEMORY.md" ]; then
  echo "📋 Checking MEMORY.md index sections..."
  for section_name in "Contacts" "Workflows" "Preferences"; do
    if ! grep -q "### ${section_name}" "$WORKSPACE/MEMORY.md" 2>/dev/null; then
      if [ "$DRY_RUN" = "true" ]; then
        echo "   [DRY RUN] Would add: ### ${section_name} section"
      else
        case "$section_name" in
          Contacts)
            INDEX_TEXT="\n### Contacts (memory/contacts/)\n(one file per person/org — name, role, context, preferences, history)\n"
            ;;
          Workflows)
            INDEX_TEXT="\n### Workflows (memory/workflows/)\n(pipelines, automations, multi-service processes)\n"
            ;;
          Preferences)
            INDEX_TEXT="\n### Preferences (memory/preferences.md)\nCross-cutting user preferences organized by category. Updated as discovered.\n"
            ;;
        esac
        # Insert before ### Runbooks or ### Daily Logs
        if grep -q "### Runbooks" "$WORKSPACE/MEMORY.md"; then
          sed -i "/### Runbooks/i\\${INDEX_TEXT}" "$WORKSPACE/MEMORY.md"
        elif grep -q "### Daily Logs" "$WORKSPACE/MEMORY.md"; then
          sed -i "/### Daily Logs/i\\${INDEX_TEXT}" "$WORKSPACE/MEMORY.md"
        else
          echo -e "$INDEX_TEXT" >> "$WORKSPACE/MEMORY.md"
        fi
        echo "   ✅ Added ### ${section_name} to MEMORY.md index"
        UPDATED=$((UPDATED + 1))
      fi
    else
      echo "   ⏭️  ### ${section_name} already in index (skipped)"
      SKIPPED=$((SKIPPED + 1))
    fi
  done
fi

# Check AGENTS.md for metrics/contacts/workflows awareness
if [ -f "$WORKSPACE/AGENTS.md" ]; then
  if ! grep -q "contacts\|Contacts" "$WORKSPACE/AGENTS.md" 2>/dev/null; then
    echo "   ℹ️  AGENTS.md may need updating — new memory categories (contacts, workflows, preferences)"
    echo "      Consider re-running install with option 2 (Full reinstall) to regenerate AGENTS.md"
  fi
fi

echo ""

# ─────────────────────────────────────────────────────────────────────────────
# New optional features (offer if not already set up)
# ─────────────────────────────────────────────────────────────────────────────
WORKSPACE="${CLAWD_WORKSPACE:-$(pwd)}"
SKILL_DIR="$(cd "$(dirname "$0")" && pwd)"

# Metrics
if ! crontab -l 2>/dev/null | grep -q "metrics.sh"; then
  echo ""
  read -p "📊 New feature: daily metrics tracking (knowledge growth over time). Enable? (y/N): " ENABLE_METRICS
  ENABLE_METRICS=$(echo "$ENABLE_METRICS" | tr '[:upper:]' '[:lower:]')
  if [ "$ENABLE_METRICS" = "y" ] || [ "$ENABLE_METRICS" = "yes" ]; then
    if [ -f "$SKILL_DIR/metrics.sh" ]; then
      if [ "$DRY_RUN" != "true" ]; then
        cp "$SKILL_DIR/metrics.sh" "$WORKSPACE/scripts/metrics.sh"
        chmod +x "$WORKSPACE/scripts/metrics.sh"
        (crontab -l 2>/dev/null; echo "30 23 * * * $WORKSPACE/scripts/metrics.sh --collect") | crontab -
        "$WORKSPACE/scripts/metrics.sh" --collect
        echo "   ✅ Metrics enabled — daily snapshots at 11:30 PM"
        echo "   📊 First snapshot captured. View with: bash scripts/metrics.sh --report"
        UPDATED=$((UPDATED + 1))
      else
        echo "   [DRY RUN] Would enable metrics tracking"
      fi
    fi
  fi
else
  # Update metrics script if it exists
  if [ -f "$SKILL_DIR/metrics.sh" ] && [ -f "$WORKSPACE/scripts/metrics.sh" ]; then
    if [ "$DRY_RUN" != "true" ]; then
      cp "$SKILL_DIR/metrics.sh" "$WORKSPACE/scripts/metrics.sh"
      chmod +x "$WORKSPACE/scripts/metrics.sh"
      echo "   📊 Metrics script updated to latest version"
    fi
  fi
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "   ✅ Updated: $UPDATED"
echo "   ⏭️  Skipped (already current): $SKIPPED"
echo ""

if [ "$DRY_RUN" = "true" ]; then
  echo "   Dry run complete. Re-run without --dry-run to apply changes."
else
  # Update version marker
  WORKSPACE="${CLAWD_WORKSPACE:-$(pwd)}"
  echo "$OPENCORTEX_VERSION" > "$WORKSPACE/.opencortex-version"
  echo "   Update complete (v$OPENCORTEX_VERSION). Run verify.sh to confirm everything is healthy:"
  echo "   bash skills/opencortex/scripts/verify.sh"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
