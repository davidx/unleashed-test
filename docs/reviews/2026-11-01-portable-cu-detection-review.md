# Review: Make `bin/review.sh` portable by auto-detecting the `cu` binary

**PR:** fix: auto-detect cu binary path instead of hardcoding /opt/homebrew/bin/cu
**Plan:** docs/plans/2026-11-01-portable-cu-detection.md
**Date:** 2026-11-01

## Gate Results

| Gate | Command | Result |
|------|---------|--------|
| Syntax check | `bash -n bin/review.sh` | PASS (exit 0, no output) |
| src/login.js untouched | `git diff 2b4ca69..HEAD -- src/login.js` | PASS (empty) |
| Makefile untouched | `git diff 2b4ca69..HEAD -- Makefile` | PASS (empty) |
| YAML files untouched | `git diff 2b4ca69..HEAD -- '*.yaml' '*.yml'` | PASS (empty) |
| No "Footgun" in README | `grep -i Footgun README.md` | PASS (no matches) |
| No hardcoded sole CU assignment | `grep '/opt/homebrew/bin/cu' bin/review.sh` | PASS (appears only in candidate list) |

All 6 gates passed.

## Code Review: bin/review.sh

**No issues found.**

The detection logic correctly implements all four requirements from the plan:

1. **Env var override**: `if [ -z "${CU:-}" ]` respects a pre-set `CU` variable.
   The `:-` default prevents `set -u` from erroring on an unset variable.
2. **Candidate list**: Checks `/opt/homebrew/bin/cu` and `/usr/local/bin/cu`
   using `-x` (executable test), in the correct priority order.
3. **`command -v` fallback with `/usr/bin/cu` rejection**: Uses `|| true` to
   prevent `set -e` abort, then explicitly rejects `/usr/bin/cu`.
4. **Clear error on failure**: Prints three informative lines to stderr and
   exits 1.

`set -euo pipefail` is present on line 3. The `REPO=` assignment and
`"$CU" run` invocation are unchanged and correct.

## Code Review: README.md

**No issues found.**

- The "Footgun" caveat is removed.
- The `CU` env var override is documented in the Prerequisites section.
- The Usage section remains accurate (still describes `make review` and the
  underlying `cu run` invocation).
- No stale references to hardcoded paths as requirements.

## Files Changed

Only the expected files were modified:
- `bin/review.sh` (auto-detection logic)
- `README.md` (updated prerequisites)
- `docs/plans/2026-11-01-portable-cu-detection.md` (new plan document)

`src/login.js`, `Makefile`, and all YAML files are untouched.

## Verdict

**approve**

All gates pass. The implementation matches the plan exactly. No bugs, no
over-engineering, no security issues. The detection logic is straightforward
and handles all specified edge cases.
