#!/bin/bash
# OpenCortex — Replace secrets with placeholders before git commit
# Reads .secrets-map (SECRET|PLACEHOLDER per line), applies sed replacements
WORKSPACE="${CLAWD_WORKSPACE:-$(cd "$(dirname "$0")/.." && pwd)}"
SECRETS_FILE="$WORKSPACE/.secrets-map"

[ ! -f "$SECRETS_FILE" ] && exit 0

while IFS="|" read -r secret placeholder; do
  [ -z "$secret" ] && continue
  [[ "$secret" =~ ^# ]] && continue
  git -C "$WORKSPACE" ls-files "*.md" "*.sh" "*.json" "*.conf" "*.py" | while read -r file; do
    filepath="$WORKSPACE/$file"
    grep -q "$secret" "$filepath" 2>/dev/null && sed -i "s|$secret|$placeholder|g" "$filepath"
  done
done < "$SECRETS_FILE"
