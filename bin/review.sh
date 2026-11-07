#!/usr/bin/env bash
# Launch the repo-scoped review-team against the current repo's uncommitted changes.
set -euo pipefail

# Auto-detect the cu CLI. /usr/bin/cu on macOS is UUCP, not claude-unleashed.
if [ -z "${CU:-}" ]; then
  for candidate in /opt/homebrew/bin/cu /usr/local/bin/cu; do
    if [ -x "$candidate" ]; then
      CU="$candidate"
      break
    fi
  done
fi

if [ -z "${CU:-}" ]; then
  found="$(command -v cu 2>/dev/null || true)"
  if [ -n "$found" ] && [ "$found" != "/usr/bin/cu" ]; then
    CU="$found"
  fi
fi

if [ -z "${CU:-}" ]; then
  echo "Error: cu CLI not found." >&2
  echo "Install it and ensure it is on PATH, or set CU=/path/to/cu." >&2
  echo "Note: /usr/bin/cu on macOS is the UUCP tool, not the cu CLI." >&2
  exit 1
fi

REPO="$(git rev-parse --show-toplevel)"

"$CU" run --repo "$REPO" --agent-group review-team \
  --title "review-team" \
  --prompt "Review the current changes (git diff HEAD). Report findings as commentary only. Be brief."
