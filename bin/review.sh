#!/usr/bin/env bash
# Launch the repo-scoped review-team against the current repo's uncommitted changes.
set -euo pipefail

CU=/opt/homebrew/bin/cu          # /usr/bin/cu (UUCP) shadows it on PATH
REPO="$(git rev-parse --show-toplevel)"

"$CU" run --repo "$REPO" --agent-group review-team \
  --title "review-team" \
  --prompt "Review the current changes (git diff HEAD). Report findings as commentary only. Be brief."
