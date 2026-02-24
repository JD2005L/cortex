#!/bin/bash
# OpenCortex — Restore secrets from placeholders after git push
# Reverses git-scrub-secrets.sh
set -euo pipefail
WORKSPACE="$(cd "$(dirname "$0")/.." && pwd)"
SECRETS_FILE="$WORKSPACE/.secrets-map"

[ ! -f "$SECRETS_FILE" ] && exit 0

while IFS="|" read -r secret placeholder; do
  [ -z "$secret" ] && continue
  [[ "$secret" =~ ^# ]] && continue
  # Restore tracked text files (mirrors scrub scope)
  if [ "${OPENCORTEX_SCRUB_ALL:-0}" = "1" ]; then
    git -C "$WORKSPACE" ls-files | while read -r file; do
      file -b --mime-encoding "$WORKSPACE/$file" 2>/dev/null | grep -q "binary" && continue
      grep -qF "$placeholder" "$WORKSPACE/$file" 2>/dev/null && sed -i "s|$placeholder|$secret|g" "$WORKSPACE/$file"
    done
  else
    git -C "$WORKSPACE" ls-files "*.md" "*.sh" "*.json" "*.conf" "*.py" "*.yaml" "*.yml" "*.toml" "*.env" "*.txt" "*.cfg" | while read -r file; do
      grep -qF "$placeholder" "$WORKSPACE/$file" 2>/dev/null && sed -i "s|$placeholder|$secret|g" "$WORKSPACE/$file"
    done
  fi
done < "$SECRETS_FILE"
