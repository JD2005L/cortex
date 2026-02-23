#!/bin/bash
# OpenCortex — Auto-commit and push workspace changes
# Scrubs secrets before commit, restores after push
WORKSPACE="$(cd "$(dirname "$0")/.." && pwd)"
cd "$WORKSPACE" || exit 1

if git diff --quiet && git diff --cached --quiet && [ -z "$(git ls-files --others --exclude-standard)" ]; then
  exit 0
fi

"$WORKSPACE/scripts/git-scrub-secrets.sh"
git add -A
git commit -m "Auto-backup: $(date '+%Y-%m-%d %H:%M')" --quiet
git push --quiet 2>/dev/null
"$WORKSPACE/scripts/git-restore-secrets.sh"
