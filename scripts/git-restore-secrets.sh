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
  # Restore ALL tracked text files (mirrors scrub scope)
  git -C "$WORKSPACE" ls-files | while read -r file; do
    file -b --mime-encoding "$WORKSPACE/$file" 2>/dev/null | grep -q "binary" && continue
    grep -qF "$placeholder" "$WORKSPACE/$file" 2>/dev/null && sed -i "s|$placeholder|$secret|g" "$WORKSPACE/$file"
  done
done < "$SECRETS_FILE"
