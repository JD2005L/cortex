#!/bin/bash
# OpenCortex — Non-destructive update script
# Adds missing content to your workspace. Never overwrites files you've customized.
# Cron job messages are updated to the latest templates.
# Run from your OpenClaw workspace directory: bash skills/opencortex/scripts/update.sh

set -euo pipefail

OPENCORTEX_VERSION="3.4.4"

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

echo "🔄 OpenCortex Update v${OPENCORTEX_VERSION}"
echo "   Workspace: $WORKSPACE"
echo "   Script:    $SCRIPT_DIR"
echo ""

UPDATED=0
SKIPPED=0

# ─────────────────────────────────────────────────────────────────────────────
# Part 1: Cron job messages — update to latest templates
# ─────────────────────────────────────────────────────────────────────────────
echo "⏰ Checking cron job messages..."


WORKSPACE="${CLAWD_WORKSPACE:-$(pwd)}"
DAILY_MSG="Daily memory maintenance. Read skills/opencortex/references/distillation.md for full instructions and follow them. Workspace: $WORKSPACE"
WEEKLY_MSG="Weekly synthesis. Read skills/opencortex/references/weekly-synthesis.md for full instructions and follow them. Workspace: $WORKSPACE"


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
      openclaw cron edit "$DAILY_ID" --message "$DAILY_MSG" --model default 2>/dev/null \
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
      openclaw cron edit "$WEEKLY_ID" --message "$WEEKLY_MSG" --model default 2>/dev/null \
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
Assess every task for sub-agent delegation before starting. Stay available. Assign sub-agents by complexity using whatever models are configured:
- **Light:** File ops, searches, data extraction, simple scripts, monitoring, lookups
- **Medium:** Multi-step work, code writing, debugging, research, moderate complexity
- **Heavy:** Complex reasoning, architecture decisions, sensitive or destructive operations
- **Keep main thread for:** Conversation, decisions, confirmations, quick answers
EOPR
)

  PRINCIPLE_TEXTS["P2"]=$(cat <<'EOPR'
### P2: Write It Down
Do not mentally note — commit to memory files. Update indexes after significant work.
Write before responding: when a user states a preference, makes a decision, gives a deadline, or corrects you, write it to the relevant memory file before composing your response. If the session ends or compacts before you save, the context is lost. Writing first ensures durability.
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

  # Ensure P0 exists (needed for migration from older versions)
  if ! grep -q "^### P0:" "$WORKSPACE/MEMORY.md" 2>/dev/null; then
    echo "   ℹ️  Adding P0 (Custom Principles) section for your own additions..."
    if [ "$DRY_RUN" != "true" ]; then
      # Insert P0 right after the PRINCIPLES header
      p_header=$(grep -n "^## .*PRINCIPLES" "$WORKSPACE/MEMORY.md" | head -1 | cut -d: -f1)
      if [ -n "$p_header" ]; then
        p0_text="\n### P0: Custom Principles\nYour custom principles go here as P0-A, P0-B, P0-C, etc. All custom principles belong in P0 regardless of how they are requested. These are never modified by OpenCortex updates.\n"
        sed -i "${p_header}a\\${p0_text}" "$WORKSPACE/MEMORY.md"
        echo "   ✅ Added P0 section"
        UPDATED=$((UPDATED + 1))
      fi
    fi
  fi

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
        echo "   🔄 ${pnum} title changed — will update"
        OUTDATED_PRINCIPLES+=("$pnum")
      else
        # Title matches — check if body content has changed
        # Extract current principle block including header (from ### Px: to line before next ### P or ---)
        current_body=$(awk "/^### ${pnum}:/{found=1} found{if(/^### P[0-9]/ && !/^### ${pnum}:/)exit; if(/^---$/)exit; if(/^## /)exit; print}" "$WORKSPACE/MEMORY.md" 2>/dev/null)
        expected_body="${PRINCIPLE_TEXTS[$pnum]}"
        current_hash=$(printf '%s' "$current_body" | tr -d '[:space:]' | md5sum | cut -d' ' -f1)
        expected_hash=$(printf '%s' "$expected_body" | tr -d '[:space:]' | md5sum | cut -d' ' -f1)
        if [ "$current_hash" != "$expected_hash" ]; then
          echo "   🔄 ${pnum} content changed — will update"
          OUTDATED_PRINCIPLES+=("$pnum")
        else
          echo "   ⏭️  ${pnum} already exists (skipped)"
          SKIPPED=$((SKIPPED + 1))
        fi
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
        # Extract current principle block for display (including header)
        current_full=$(awk "/^### ${pnum}:/{found=1} found{if(/^### P[0-9]/ && !/^### ${pnum}:/)exit; if(/^---$/)exit; if(/^## /)exit; print}" "$WORKSPACE/MEMORY.md" 2>/dev/null)
        expected_full="${PRINCIPLE_TEXTS[$pnum]}"

        if [ "$current_title" != "$expected_title" ]; then
          echo "   ${pnum} title changed:"
          echo "     Current: $current_title"
          echo "     New:     $expected_title"
        else
          echo "   ${pnum} content updated (title unchanged)"
        fi
        echo ""
        echo "   ┌─ Current ──────────────────────────────"
        echo "$current_full" | sed 's/^/   │ /'
        echo "   └─────────────────────────────────────────"
        echo ""
        echo "   ┌─ New ─────────────────────────────────"
        echo "$expected_full" | sed 's/^/   │ /'
        echo "   └─────────────────────────────────────────"
        echo ""
        # Detect custom additions: lines in current that aren't in the expected version
        custom_lines=""
        if [ -n "$current_full" ] && [ -n "$expected_full" ]; then
          custom_lines=$(diff <(echo "$expected_full") <(echo "$current_full") 2>/dev/null | grep "^> " | sed 's/^> //' | sed '/^$/d' || true)
        fi

        if [ -n "$custom_lines" ]; then
          echo "   📋 Custom content detected beyond the standard ${pnum}:"
          echo "$custom_lines" | sed 's/^/      /'
          echo ""
          read -p "   Migrate custom content to P0 before updating? (Y/n): " MIGRATE
          MIGRATE=$(echo "$MIGRATE" | tr '[:upper:]' '[:lower:]')
          if [ "$MIGRATE" != "n" ] && [ "$MIGRATE" != "no" ]; then
            # Find or create P0 section
            if grep -q "^### P0:" "$WORKSPACE/MEMORY.md" 2>/dev/null; then
              # Count existing P0 sub-principles to determine next letter
              existing_count=$(grep -c "^#### P0-" "$WORKSPACE/MEMORY.md" 2>/dev/null || true)
              existing_count=$(printf '%s' "$existing_count" | tr -dc '0-9')
              existing_count=${existing_count:-0}
              next_letter=$(printf "\\$(printf '%03o' $((65 + existing_count)))")
              # Insert after the P0 description line
              p0_line=$(grep -n "^### P0:" "$WORKSPACE/MEMORY.md" | head -1 | cut -d: -f1)
              # Find the next ### heading after P0
              p0_end=$(tail -n "+$((p0_line + 1))" "$WORKSPACE/MEMORY.md" | grep -n "^### P[0-9]" | head -1 | cut -d: -f1)
              if [ -n "$p0_end" ]; then
                insert_at=$((p0_line + p0_end - 1))
              else
                insert_at=$((p0_line + 1))
              fi
              # Build the sub-principle
              sub_principle="\n#### P0-${next_letter}: Custom from ${pnum}\n${custom_lines}\n"
              sed -i "${insert_at}a\\${sub_principle}" "$WORKSPACE/MEMORY.md"
              echo "   ✅ Migrated to P0-${next_letter}"
            else
              echo "   ⚠️  P0 section not found — custom content preserved in current ${pnum}"
              echo "      Skipping update to avoid data loss."
              SKIPPED=$((SKIPPED + 1))
              continue
            fi
          fi
        fi

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
echo ""

# ─────────────────────────────────────────────────────────────────────────────
# Part 3b: Reference docs — update to latest versions
# ─────────────────────────────────────────────────────────────────────────────
echo "📚 Checking reference documents..."

copy_or_update_ref() {
  local ref_name="$1"
  local src="$SCRIPT_DIR/../references/$ref_name"
  local dst="$WORKSPACE/skills/opencortex/references/$ref_name"

  if [ ! -f "$src" ]; then
    # Try alternate skill path
    src="$SCRIPT_DIR/../references/$ref_name"
    [ ! -f "$src" ] && return
  fi

  mkdir -p "$(dirname "$dst")"

  if [ -f "$dst" ]; then
    local src_hash dst_hash
    src_hash=$(md5sum "$src" 2>/dev/null | cut -d' ' -f1)
    dst_hash=$(md5sum "$dst" 2>/dev/null | cut -d' ' -f1)
    if [ "$src_hash" = "$dst_hash" ]; then
      echo "   ⏭️  references/$ref_name already current (skipped)"
      SKIPPED=$((SKIPPED + 1))
      return
    fi
    if [ "$DRY_RUN" = "true" ]; then
      echo "   [DRY RUN] Would update: references/$ref_name"
    else
      cp "$src" "$dst"
      echo "   🔄 Updated references/$ref_name"
    fi
    UPDATED=$((UPDATED + 1))
  else
    if [ "$DRY_RUN" = "true" ]; then
      echo "   [DRY RUN] Would copy: references/$ref_name"
    else
      cp "$src" "$dst"
      echo "   ✅ Copied references/$ref_name"
    fi
    UPDATED=$((UPDATED + 1))
  fi
}

copy_or_update_ref "distillation.md"
copy_or_update_ref "weekly-synthesis.md"
copy_or_update_ref "architecture.md"

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
  # Check core structure sections (## level)
  for core_section in "Identity" "Memory Index"; do
    if ! grep -q "^## ${core_section}" "$WORKSPACE/MEMORY.md" 2>/dev/null; then
      if [ "$DRY_RUN" = "true" ]; then
        echo "   [DRY RUN] Would add: ## ${core_section}"
      else
        case "$core_section" in
          Identity)
            echo -e "\n## Identity\n- **Name:** (your agent name)\n- **Human:** (your name)\n" >> "$WORKSPACE/MEMORY.md"
            ;;
          "Memory Index")
            echo -e "\n## Memory Index\n" >> "$WORKSPACE/MEMORY.md"
            ;;
        esac
        echo "   ✅ Added ## ${core_section}"
        UPDATED=$((UPDATED + 1))
      fi
    else
      echo "   ⏭️  ## ${core_section} exists (skipped)"
      SKIPPED=$((SKIPPED + 1))
    fi
  done

  # Check index sub-sections (### level)
  declare -A INDEX_TEMPLATES
  INDEX_TEMPLATES["Infrastructure"]="\n### Infrastructure\n- \`TOOLS.md\` — APIs, credentials, scripts, access methods\n"
  INDEX_TEMPLATES["Projects"]="\n### Projects (memory/projects/)\n| Project | Status | File |\n|---------|--------|------|\n| (your projects) | | |\n"
  INDEX_TEMPLATES["Scheduled Jobs"]="\n### Scheduled Jobs\n(document cron jobs and scheduled tasks here)\n"
  INDEX_TEMPLATES["Contacts"]="\n### Contacts (memory/contacts/)\n(one file per person/org — name, role, context, preferences, history)\n"
  INDEX_TEMPLATES["Workflows"]="\n### Workflows (memory/workflows/)\n(pipelines, automations, multi-service processes)\n"
  INDEX_TEMPLATES["Preferences"]="\n### Preferences (memory/preferences.md)\nCross-cutting user preferences organized by category. Updated as discovered.\n"
  INDEX_TEMPLATES["Runbooks"]="\n### Runbooks (memory/runbooks/)\nStep-by-step procedures for repeatable tasks. Sub-agents can follow these directly.\n"
  INDEX_TEMPLATES["Daily Logs"]="\n### Daily Logs\n\`memory/YYYY-MM-DD.md\` — Working daily logs. Distilled into project files periodically.\n"

  for section_name in "Infrastructure" "Projects" "Scheduled Jobs" "Contacts" "Workflows" "Preferences" "Runbooks" "Daily Logs"; do
    if ! grep -q "### ${section_name}" "$WORKSPACE/MEMORY.md" 2>/dev/null; then
      if [ "$DRY_RUN" = "true" ]; then
        echo "   [DRY RUN] Would add: ### ${section_name} section"
      else
        INDEX_TEXT="${INDEX_TEMPLATES[$section_name]}"
        # Try to insert in a sensible position
        if [ "$section_name" = "Daily Logs" ]; then
          # Always append at end
          echo -e "$INDEX_TEXT" >> "$WORKSPACE/MEMORY.md"
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

# ─────────────────────────────────────────────────────────────────────────────
# Part 5: Template files — check existence and offer to regenerate
# ─────────────────────────────────────────────────────────────────────────────
echo "📄 Checking template files..."

# SOUL.md
if [ ! -f "$WORKSPACE/SOUL.md" ]; then
  echo "   ⚠️  SOUL.md is missing"
  read -p "   Create default SOUL.md? (Y/n): " CREATE_SOUL
  CREATE_SOUL=$(echo "$CREATE_SOUL" | tr '[:upper:]' '[:lower:]')
  if [ "$CREATE_SOUL" != "n" ] && [ "$CREATE_SOUL" != "no" ]; then
    if [ "$DRY_RUN" != "true" ]; then
      cat > "$WORKSPACE/SOUL.md" << 'SOULEOF'
# SOUL.md — Who You Are

*Customize this to define your agent's personality and boundaries.*

## Core Truths

**Be genuinely helpful, not performatively helpful.** Skip filler words and just help. Actions over ceremony.

**Have opinions.** You're allowed to disagree, prefer things, find stuff amusing or boring.

**Be resourceful before asking.** Try to figure it out first. Read the file. Check the context. Search for it. Then ask if stuck.

**Earn trust through competence.** Be careful with external actions. Be bold with internal ones.

**Remember you're a guest.** You have access to someone's life. Treat it with respect.

## Boundaries

- Private things stay private. Period.
- When in doubt, ask before acting externally.
- Never send half-baked replies to messaging surfaces.

## Continuity

Each session, you wake up fresh. Your files are your memory. Read them. Update them.

---

*This file is yours to evolve. As you learn who you are, update it.*
SOULEOF
      echo "   ✅ Created SOUL.md"
      UPDATED=$((UPDATED + 1))
    fi
  fi
else
  echo "   ⏭️  SOUL.md exists (skipped)"
  SKIPPED=$((SKIPPED + 1))
fi

# USER.md
if [ ! -f "$WORKSPACE/USER.md" ]; then
  echo "   ⚠️  USER.md is missing"
  read -p "   Create default USER.md? (Y/n): " CREATE_USER
  CREATE_USER=$(echo "$CREATE_USER" | tr '[:upper:]' '[:lower:]')
  if [ "$CREATE_USER" != "n" ] && [ "$CREATE_USER" != "no" ]; then
    if [ "$DRY_RUN" != "true" ]; then
      cat > "$WORKSPACE/USER.md" << 'USEREOF'
# USER.md — About Your Human

- **Name:** (your name)
- **Location:** (city, country)
- **Timezone:** (timezone)

## Communication Style

- **Prefers:** (direct? detailed? casual?)
- **Values:** (what matters to them?)

## Projects

(list active projects here as the agent learns about them)

## Preferences

(agent will fill this in over time from conversations)
USEREOF
      echo "   ✅ Created USER.md"
      UPDATED=$((UPDATED + 1))
    fi
  fi
else
  echo "   ⏭️  USER.md exists (skipped)"
  SKIPPED=$((SKIPPED + 1))
fi

# .gitignore — ensure sensitive entries
if [ -f "$WORKSPACE/.gitignore" ]; then
  GITIGNORE_ADDS=()
  for entry in ".vault/" ".secrets-map" ".env" "*.key" "*.pem"; do
    if ! grep -qF "$entry" "$WORKSPACE/.gitignore" 2>/dev/null; then
      GITIGNORE_ADDS+=("$entry")
    fi
  done
  if [ ${#GITIGNORE_ADDS[@]} -gt 0 ]; then
    if [ "$DRY_RUN" != "true" ]; then
      for entry in "${GITIGNORE_ADDS[@]}"; do
        echo "$entry" >> "$WORKSPACE/.gitignore"
      done
      echo "   ✅ Added missing .gitignore entries: ${GITIGNORE_ADDS[*]}"
      UPDATED=$((UPDATED + 1))
    else
      echo "   [DRY RUN] Would add .gitignore entries: ${GITIGNORE_ADDS[*]}"
    fi
  else
    echo "   ⏭️  .gitignore already has sensitive entries (skipped)"
    SKIPPED=$((SKIPPED + 1))
  fi
elif [ ! -f "$WORKSPACE/.gitignore" ]; then
  if [ "$DRY_RUN" != "true" ]; then
    printf '.vault/\n.secrets-map\n.env\n*.key\n*.pem\n' > "$WORKSPACE/.gitignore"
    echo "   ✅ Created .gitignore with sensitive entries"
    UPDATED=$((UPDATED + 1))
  fi
fi

# AGENTS.md — check for key sections, offer regeneration
if [ -f "$WORKSPACE/AGENTS.md" ]; then
  AGENTS_WARNINGS=()
  if ! grep -q "contacts\|Contacts" "$WORKSPACE/AGENTS.md" 2>/dev/null; then
    AGENTS_WARNINGS+=("contacts/workflows/preferences")
  fi
  if ! grep -q "Write Before Responding\|write-ahead\|Write before responding" "$WORKSPACE/AGENTS.md" 2>/dev/null; then
    AGENTS_WARNINGS+=("Write Before Responding (P2)")
  fi
  if ! grep -q "Custom Principles\|P0" "$WORKSPACE/AGENTS.md" 2>/dev/null; then
    AGENTS_WARNINGS+=("Custom Principles (P0) guidance")
  fi
  if [ ${#AGENTS_WARNINGS[@]} -gt 0 ]; then
    echo "   ⚠️  AGENTS.md is missing: ${AGENTS_WARNINGS[*]}"
    read -p "   Back up current AGENTS.md and regenerate? (y/N): " REGEN_AGENTS
    REGEN_AGENTS=$(echo "$REGEN_AGENTS" | tr '[:upper:]' '[:lower:]')
    if [ "$REGEN_AGENTS" = "y" ] || [ "$REGEN_AGENTS" = "yes" ]; then
      if [ "$DRY_RUN" != "true" ]; then
        cp "$WORKSPACE/AGENTS.md" "$WORKSPACE/AGENTS.md.bak.$(date +%Y%m%d%H%M%S)"
        echo "   📦 Backed up to AGENTS.md.bak.*"
        echo "   ℹ️  Run install.sh (option 2: Full reinstall) to regenerate AGENTS.md"
      fi
    else
      echo "   ⏭️  Kept existing AGENTS.md"
    fi
  else
    echo "   ⏭️  AGENTS.md looks current (skipped)"
    SKIPPED=$((SKIPPED + 1))
  fi
else
  echo "   ⚠️  AGENTS.md missing — run install.sh to create it"
fi

# BOOTSTRAP.md — check for key content, offer regeneration
if [ -f "$WORKSPACE/BOOTSTRAP.md" ]; then
  BOOTSTRAP_WARNINGS=()
  if ! grep -q "Sub-Agent Protocol\|sub-agent\|debrief" "$WORKSPACE/BOOTSTRAP.md" 2>/dev/null; then
    BOOTSTRAP_WARNINGS+=("sub-agent debrief protocol")
  fi
  if ! grep -q "HEARTBEAT\|heartbeat" "$WORKSPACE/BOOTSTRAP.md" 2>/dev/null; then
    BOOTSTRAP_WARNINGS+=("heartbeat handling")
  fi
  if [ ${#BOOTSTRAP_WARNINGS[@]} -gt 0 ]; then
    echo "   ⚠️  BOOTSTRAP.md is missing: ${BOOTSTRAP_WARNINGS[*]}"
    read -p "   Back up current BOOTSTRAP.md and regenerate? (y/N): " REGEN_BOOT
    REGEN_BOOT=$(echo "$REGEN_BOOT" | tr '[:upper:]' '[:lower:]')
    if [ "$REGEN_BOOT" = "y" ] || [ "$REGEN_BOOT" = "yes" ]; then
      if [ "$DRY_RUN" != "true" ]; then
        cp "$WORKSPACE/BOOTSTRAP.md" "$WORKSPACE/BOOTSTRAP.md.bak.$(date +%Y%m%d%H%M%S)"
        echo "   📦 Backed up to BOOTSTRAP.md.bak.*"
        echo "   ℹ️  Run install.sh (option 2: Full reinstall) to regenerate BOOTSTRAP.md"
      fi
    else
      echo "   ⏭️  Kept existing BOOTSTRAP.md"
    fi
  else
    echo "   ⏭️  BOOTSTRAP.md looks current (skipped)"
    SKIPPED=$((SKIPPED + 1))
  fi
else
  echo "   ⚠️  BOOTSTRAP.md missing — run install.sh to create it"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Part 6: Cron jobs — verify they exist
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "⏰ Verifying cron jobs exist..."
if command -v openclaw >/dev/null 2>&1; then
  CRON_LIST=$(openclaw cron list 2>/dev/null || true)
  if echo "$CRON_LIST" | grep -qi "Daily Memory Distillation"; then
    echo "   ⏭️  Daily Memory Distillation cron exists"
    SKIPPED=$((SKIPPED + 1))
  else
    echo "   ⚠️  Daily Memory Distillation cron not found"
    echo "      Run install.sh to create it, or manually add with: openclaw cron add"
  fi
  if echo "$CRON_LIST" | grep -qi "Weekly Synthesis"; then
    echo "   ⏭️  Weekly Synthesis cron exists"
    SKIPPED=$((SKIPPED + 1))
  else
    echo "   ⚠️  Weekly Synthesis cron not found"
    echo "      Run install.sh to create it, or manually add with: openclaw cron add"
  fi
else
  echo "   ⏭️  openclaw not in PATH — skipping cron existence check"
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
