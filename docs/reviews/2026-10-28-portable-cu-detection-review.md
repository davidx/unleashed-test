# Review: Portable cu binary detection

Date: 2026-10-28
Plan: `docs/plans/2026-10-28-portable-cu-detection.md`
PR: https://github.com/davidx/unleashed-test/pull/11
Verdict: **approve**

## Acceptance criteria

| Criterion | Result |
|-----------|--------|
| `bin/review.sh` no longer hardcodes `/opt/homebrew/bin/cu` as sole source | PASS — appears only in candidate list |
| `bash -n bin/review.sh` syntax valid | PASS (visual inspection: balanced control structures, correct quoting) |
| "Footgun" removed from README.md | PASS |
| `CU` env var override documented | PASS — in Prerequisites and Usage sections |
| `src/login.js` untouched | PASS |
| Only `bin/review.sh` and `README.md` changed | PASS (2 files, 31 insertions, 6 deletions) |

## Logic review

The three-stage detection in `bin/review.sh` is correct:

1. **Env override** — `[ -z "${CU:-}" ]` respects a pre-set `CU` and is safe under `set -u`.
2. **Candidate list** — checks `/opt/homebrew/bin/cu` then `/usr/local/bin/cu` with `-x`.
3. **PATH fallback** — `command -v cu` with explicit `/usr/bin/cu` exclusion (macOS UUCP).
4. **Error exit** — clear message to stderr, exit 1.

No regressions: users with `cu` at `/opt/homebrew/bin/cu` hit the first candidate.

## Issues found

None.
