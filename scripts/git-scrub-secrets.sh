#!/bin/bash
# OpenCortex — Replace secrets with placeholders before git commit
# Reads .secrets-map (SECRET|PLACEHOLDER per line), applies sed to ALL tracked text files
set -euo pipefail
WORKSPACE="$(cd "$(dirname "$0")/.." && pwd)"
SECRETS_FILE="$WORKSPACE/.secrets-map"

[ ! -f "$SECRETS_FILE" ] && exit 0

while IFS="|" read -r secret placeholder; do
  [ -z "$secret" ] && continue
  [[ "$secret" =~ ^# ]] && continue
  # Scrub tracked text files matching known safe extensions
  # To scrub ALL tracked files, set OPENCORTEX_SCRUB_ALL=1
  if [ "${OPENCORTEX_SCRUB_ALL:-0}" = "1" ]; then
    git -C "$WORKSPACE" ls-files | while read -r file; do
      file -b --mime-encoding "$WORKSPACE/$file" 2>/dev/null | grep -q "binary" && continue
      grep -qF "$secret" "$WORKSPACE/$file" 2>/dev/null && sed -i "s|$secret|$placeholder|g" "$WORKSPACE/$file"
    done
  else
    git -C "$WORKSPACE" ls-files "*.md" "*.sh" "*.json" "*.conf" "*.py" "*.yaml" "*.yml" "*.toml" "*.env" "*.txt" "*.cfg" | while read -r file; do
      grep -qF "$secret" "$WORKSPACE/$file" 2>/dev/null && sed -i "s|$secret|$placeholder|g" "$WORKSPACE/$file"
    done
  fi
done < "$SECRETS_FILE"
