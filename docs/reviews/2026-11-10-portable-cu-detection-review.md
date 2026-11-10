# Review: Make `bin/review.sh` portable by auto-detecting the `cu` binary

**PR:** #20
**Date:** 2026-11-10
**Verdict:** approve

## Summary

The PR replaces the hardcoded `CU=/opt/homebrew/bin/cu` in `bin/review.sh` with
portable auto-detection logic, and updates `README.md` to match. The
implementation matches the plan exactly and has no issues.

## Checklist

| Check | Result |
|-------|--------|
| `set -euo pipefail` still present | Pass (line 3) |
| Honors pre-set `CU` env var | Pass (`${CU:-}` check on line 6) |
| Checks Homebrew paths in order | Pass (lines 7-12: `/opt/homebrew/bin/cu`, `/usr/local/bin/cu`) |
| Falls back to `command -v cu` | Pass (line 16) |
| Rejects `/usr/bin/cu` | Pass (line 17: `!= "/usr/bin/cu"`) |
| Clear error + exit 1 on failure | Pass (lines 22-27) |
| Variables properly quoted | Pass (all expansions are double-quoted) |
| `bash -n` syntax check passes | Pass (exit 0, no output) |
| README removes "Footgun" | Pass (word no longer appears) |
| README documents `CU` override | Pass (Prerequisites and Usage sections) |
| Only `bin/review.sh` + `README.md` changed | Pass (git diff --stat confirms) |
| `src/login.js` untouched | Pass (git diff shows no changes) |
| Makefile untouched | Pass |
| Plan adherence | Pass (implementation matches plan verbatim) |

## Detailed Findings

No issues found. The implementation is clean and correct.

### Shell Safety

- `set -euo pipefail` is present on line 3.
- `${CU:-}` is used consistently (three occurrences on lines 6, 15, 22),
  which avoids tripping the `nounset` option when `CU` is unset.
- The `command -v` fallback uses `2>/dev/null || true` to suppress errors
  and avoid tripping `set -e`.
- The `found` variable is properly quoted in both the `-n` test and the
  string comparison.
- The `$CU` variable is quoted when used in the invocation on line 30.

### Detection Logic

The three-tier detection (env override, candidate paths, `command -v` with
`/usr/bin/cu` exclusion) covers all documented scenarios:
- Apple Silicon Homebrew (`/opt/homebrew/bin/cu`)
- Intel Homebrew or manual install (`(/usr/local/bin/cu`)
- Other PATH locations (via `command -v`, excluding macOS UUCP)
- Custom path (via `CU` env var)

### README

- The "Footgun" paragraph is replaced with a concise auto-detection note.
- The Usage section now mentions the `CU` env var override.
- No stale references to hardcoded paths remain.

## Recommendation

Approve. No changes needed.
