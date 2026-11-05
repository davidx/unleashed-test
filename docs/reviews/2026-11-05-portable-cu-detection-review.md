# Review: Make `bin/review.sh` portable by auto-detecting the `cu` binary

- **Date:** 2026-11-05
- **Verdict:** approve
- **Commit range:** 2b4ca69..43f5cb6
- **Plan:** docs/plans/2026-11-05-portable-cu-detection.md
- **PR:** https://github.com/davidx/unleashed-test/pull/15

## Acceptance Criteria Checks

| # | Check | Result |
|---|-------|--------|
| 1 | `bash -n bin/review.sh` exits 0 (syntax valid) | PASS |
| 2 | `src/login.js` not modified | PASS |
| 3 | Makefile not modified | PASS |
| 4 | No hardcoded `/opt/homebrew/bin/cu` as sole assignment | PASS — appears only in `for candidate` loop |
| 5 | Env var override honored when `CU` is pre-set | PASS — `if [ -z "${CU:-}" ]` guards all detection |
| 6 | "Footgun" removed from README.md | PASS |
| 7 | Hardcoded path no longer a prerequisite in README | PASS |
| 8 | `CU=` override documented in README | PASS |
| 9 | Usage section accurate, no stale path references | PASS |
| 10 | Agent YAML files unchanged | PASS |

## Code Quality

- Shell quoting correct throughout (`"$CU"`, `"$candidate"`, `"$found"`, `"$REPO"`)
- `set -euo pipefail` compatibility handled: `command -v cu 2>/dev/null || true` prevents pipefail/errexit trips
- `/usr/bin/cu` rejection uses exact string comparison — sound
- `${CU:-}` handles both unset and empty string under `set -u`
- No security issues

## Issues Found

None (critical: 0, medium: 0, low: 0)
