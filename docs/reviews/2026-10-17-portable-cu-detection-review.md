# Review: Make `bin/review.sh` portable by auto-detecting the `cu` binary

- **Commit range reviewed:** `2b4ca69..6f617cc`
- **Plan:** `docs/plans/2026-10-17-portable-cu-detection.md`
- **PR:** https://github.com/davidx/unleashed-test/pull/1

## Checks

| # | Check | Result |
|---|-------|--------|
| 1 | `bash -n bin/review.sh` exits 0 (syntax valid) | PASS |
| 2 | `src/login.js` not modified across the range | PASS — `git diff 2b4ca69..HEAD -- src/login.js` is empty |
| 3 | Only expected files changed: `bin/review.sh`, `README.md`, `docs/plans/2026-10-17-portable-cu-detection.md` | PASS — `git diff --stat` shows exactly those 3 files |
| 4 | No hardcoded `/opt/homebrew/bin/cu` assignment (may appear in candidate list) | PASS — path appears only inside a `for candidate in ...` loop, not as a sole assignment |
| 5 | Env var override: `CU` is honored when pre-set in the environment | PASS — `if [ -z "${CU:-}" ]` guards all detection blocks |
| 6 | "Footgun" removed from README.md | PASS — `grep -c Footgun README.md` returns 0 |
| 7 | Hardcoded path no longer a prerequisite in README | PASS — Prerequisites section documents auto-detection and `CU=` override |
| 8 | Usage section accurate, no stale hardcoded path references | PASS — Usage section updated with override hint |
| 9 | codenod static-analysis gate | N/A — codenod not installed in this environment |

## Code Quality

- Shell quoting is correct throughout (`"$CU"`, `"$candidate"`, `"$found"`).
- `set -euo pipefail` is properly handled: `command -v cu 2>/dev/null || true` avoids `pipefail` tripping on missing binary.
- The `/usr/bin/cu` rejection logic is sound: exact string comparison `[ "$found" != "/usr/bin/cu" ]`.
- Edge case: `CU` set to empty string — handled correctly by `${CU:-}` which treats unset AND empty as empty.
- No security issues identified.

## Verdict

**approve** — All gates pass, all plan acceptance criteria are met, code quality is solid. The auto-detection logic correctly covers env var override, standard Homebrew paths, PATH fallback with UUCP rejection, and clear error messaging. README is updated accurately.
