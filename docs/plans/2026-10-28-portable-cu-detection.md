# Plan: Make `bin/review.sh` portable by auto-detecting the `cu` binary

> For agentic workers: implement this plan task-by-task. One task, one commit where applicable. Never batch.

Date: 2026-10-28
Branch: claude-unleashed/3005572f-c1a5-47d0-a3ac-74febd5778ba (base: claude-unleashed/49d8fd8a-e83c-44ed-a708-0916035e40de)
Status: ready for executor

## Problem

`bin/review.sh` hardcodes the `cu` CLI path as `/opt/homebrew/bin/cu` (line 5).
This only works when `cu` was installed via Homebrew on an Apple-Silicon Mac.
Users who installed `cu` via other means (Intel Homebrew at `/usr/local/bin/cu`,
a manual install, Linux package manager, etc.) must hand-edit the script.

The README (`README.md` lines 9-13) documents this as a "Footgun" and tells
users to manually update the path, which is fragile and unnecessary.

On macOS, `/usr/bin/cu` is the UUCP dial-out tool (part of the base system),
not the claude-unleashed CLI. A naive `which cu` will resolve to `/usr/bin/cu`
on a default macOS PATH, so the detection logic must explicitly skip that path.

## Scope

In scope:
- Replace the hardcoded `CU=` line in `bin/review.sh` with portable
  auto-detection logic that finds the correct `cu` binary.
- Update `README.md` Prerequisites section to remove the "Footgun" caveat.
- Update `README.md` Usage section if needed.
- Verify syntax correctness of the modified script.

Out of scope (do NOT do these here):
- Do not modify `src/login.js`. It is intentionally vulnerable bait for the
  review agents.
- Do not change agent YAML files or the Makefile.
- Do not add tests, `package.json`, or any new dependencies.
- Do not push to a remote or open a PR.

## Tasks

### Task 1: Replace hardcoded path in `bin/review.sh` with auto-detection

**File:** `bin/review.sh`

**What to change:** Replace line 5:

```bash
CU=/opt/homebrew/bin/cu          # /usr/bin/cu (UUCP) shadows it on PATH
```

With portable detection logic. The new code should:

1. Allow an environment variable override: if `CU` is already set in the
   environment, use that value without further detection. This lets power users
   do `CU=/custom/path/cu make review`.
2. Otherwise, check a list of common install locations in order:
   - `/opt/homebrew/bin/cu` (Homebrew on Apple Silicon)
   - `/usr/local/bin/cu` (Homebrew on Intel, or manual install)
3. If neither candidate exists, fall back to `which cu` but reject
   `/usr/bin/cu` (the macOS UUCP tool, not the claude-unleashed CLI).
   Specifically: run `command -v cu`, check whether the result is
   `/usr/bin/cu`, and only accept it if it is NOT `/usr/bin/cu`.
4. If no valid `cu` binary is found after all checks, print a clear error
   message to stderr and exit 1. The error should say something like:
   ```
   Error: cu CLI not found. Install it and ensure it is on PATH,
   or set CU=/path/to/cu before running this script.
   Note: /usr/bin/cu on macOS is the UUCP tool, not the cu CLI.
   ```

The replacement block should look approximately like this (executor may adjust
style, but the logic must cover all four points above):

```bash
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
```

The rest of the script (`REPO=...` and the `"$CU" run ...` invocation) stays
unchanged.

**Acceptance criteria:**
- `bin/review.sh` no longer contains a hardcoded `/opt/homebrew/bin/cu`
  assignment (it may appear in a candidate list, but not as the sole source).
- Running `CU=/usr/bin/true bash bin/review.sh` uses the override (proves the
  env-var override works; it will fail at the `cu run` step but that is fine).
- `bash -n bin/review.sh` exits 0 (syntax is valid).

### Task 2: Update README.md Prerequisites section

**File:** `README.md`

**What to change:** Replace lines 9-13:

```markdown
- The `cu` CLI installed at `/opt/homebrew/bin/cu`.
  Footgun: on macOS, `/usr/bin/cu` (the UUCP dial-out tool) shadows the real
  `cu` on PATH. `bin/review.sh` calls the absolute path
  `/opt/homebrew/bin/cu` for this reason. If `cu` is installed elsewhere,
  update that path.
```

With a simpler prerequisite that reflects the auto-detection:

```markdown
- The `cu` CLI installed and available on PATH (or at a standard Homebrew
  location). The script auto-detects the binary and skips the macOS
  `/usr/bin/cu` UUCP tool. You can also set `CU=/path/to/cu` to override
  detection.
```

**Acceptance criteria:**
- The word "Footgun" no longer appears in README.md.
- The hardcoded path `/opt/homebrew/bin/cu` no longer appears as a
  requirement in the Prerequisites section (it may be mentioned in passing
  but should not be a prerequisite the user must satisfy).
- The `CU` environment variable override is documented.

### Task 3: Update README.md Usage section (if needed)

**File:** `README.md`

**What to change:** Review lines 33-41 (the Usage section). The current text
says:

```markdown
This runs `bin/review.sh`, which invokes `cu run --repo <repo> --agent-group
review-team` and prints the reviewer and security findings for the current
diff.
```

This is still accurate after the change (the script still invokes `cu run`),
so it likely needs no modification. However, if the executor judges it helpful,
add a one-liner noting the override option, e.g.:

```markdown
Set `CU=/path/to/cu` before running if the auto-detection does not find your
`cu` binary.
```

**Acceptance criteria:**
- The Usage section remains accurate with respect to the updated script.
- No stale references to hardcoded paths.

### Task 4: Verify the script syntax

**File:** `bin/review.sh`

**What to do:** Run `bash -n bin/review.sh` from the repo root. This performs
a syntax check without executing the script.

**Acceptance criteria:**
- `bash -n bin/review.sh` exits with code 0 and produces no output.

### Task 5: Commit all changes

**What to do:** Stage `bin/review.sh` and `README.md` (and only those two
files). Commit with:

```
fix: auto-detect cu binary path instead of hardcoding /opt/homebrew/bin/cu
```

Then verify with `git diff HEAD~1 --stat` that only `bin/review.sh` and
`README.md` were changed.

**Acceptance criteria:**
- Exactly two files changed in the commit: `bin/review.sh` and `README.md`.
- `git status --porcelain` shows no uncommitted changes to those files.
- `src/login.js` was not modified.

## Follow-ups (not this task)

- Consider adding `briefing_gather_gmail.py` and `memory/` to `.gitignore`
  so they stop showing up in `git status`.
- Consider adding a `--dry-run` flag to `bin/review.sh` for testing the
  detection logic without invoking `cu run`.
