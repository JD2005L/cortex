#!/bin/bash
# OpenCortex — Restore secrets from placeholders after git push
# Reverses git-scrub-secrets.sh
WORKSPACE="${CLAWD_WORKSPACE:-$(cd "$(dirname "$0")/.." && pwd)}"
SECRETS_FILE="$WORKSPACE/.secrets-map"

[ ! -f "$SECRETS_FILE" ] && exit 0

while IFS="|" read -r secret placeholder; do
  [ -z "$secret" ] && continue
  [[ "$secret" =~ ^# ]] && continue
  git -C "$WORKSPACE" ls-files "*.md" "*.sh" "*.json" "*.conf" "*.py" | while read -r file; do
    filepath="$WORKSPACE/$file"
    grep -q "$placeholder" "$filepath" 2>/dev/null && sed -i "s|$placeholder|$secret|g" "$filepath"
  done
done < "$SECRETS_FILE"
