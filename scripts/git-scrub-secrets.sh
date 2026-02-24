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
  # Scrub ALL tracked files (not just specific extensions)
  git -C "$WORKSPACE" ls-files | while read -r file; do
    # Skip binary files
    file -b --mime-encoding "$WORKSPACE/$file" 2>/dev/null | grep -q "binary" && continue
    grep -qF "$secret" "$WORKSPACE/$file" 2>/dev/null && sed -i "s|$secret|$placeholder|g" "$WORKSPACE/$file"
  done
done < "$SECRETS_FILE"
