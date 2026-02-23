#!/bin/bash
# OpenCortex — Auto-commit and push workspace changes
# Scrubs secrets before commit, restores after push
WORKSPACE="$(cd "$(dirname "$0")/.." && pwd)"
cd "$WORKSPACE" || exit 1

if git diff --quiet && git diff --cached --quiet && [ -z "$(git ls-files --others --exclude-standard)" ]; then
  exit 0
fi

"$WORKSPACE/scripts/git-scrub-secrets.sh"

# Verify no raw secrets remain in tracked files before pushing
if [ -f "$WORKSPACE/.secrets-map" ]; then
  LEAK_FOUND=0
  while IFS='|' read -r secret placeholder; do
    # Skip comment lines and empty lines
    case "$secret" in '#'*|'') continue ;; esac
    # Strip leading/trailing whitespace
    secret="$(echo "$secret" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    [ -z "$secret" ] && continue
    # grep -rF for this raw secret value in all tracked files
    if git ls-files | xargs grep -lF "$secret" 2>/dev/null | grep -q .; then
      echo "❌ Secret leak detected after scrub! Raw secret found in tracked files."
      echo "   Aborting backup. Running restore script."
      LEAK_FOUND=1
      break
    fi
  done < "$WORKSPACE/.secrets-map"

  if [ "$LEAK_FOUND" -eq 1 ]; then
    "$WORKSPACE/scripts/git-restore-secrets.sh"
    exit 1
  fi
fi

git add -A
git commit -m "Auto-backup: $(date '+%Y-%m-%d %H:%M')" --quiet
git push --quiet 2>/dev/null
"$WORKSPACE/scripts/git-restore-secrets.sh"
