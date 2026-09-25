# Plan: Track the Makefile and review script so `make review` works from a clean clone

> For agentic workers: implement this plan task-by-task with red-green-refactor discipline. One task, one commit. Never batch.

Date: 2026-09-25
Branch: main
Status: ready for executor

## Problem

This repo is a claude-unleashed "review-team" proof of concept. Its
`README.md` is committed on `main` and documents a `make review` workflow
(see `README.md` lines 33-41: "## Usage ... `make review` ... This runs
`bin/review.sh`, which invokes `cu run ...`"). But the two files that make
that command work are **untracked** in git:

```
$ git status --porcelain
?? Makefile
?? bin/
?? briefing_gather_gmail.py
?? memory/
```

Because `Makefile` and `bin/review.sh` are untracked, a fresh clone of
`main` gets a README that promises `make review` but ships neither the
Makefile nor the script behind it. The documented entrypoint is therefore
broken from a clean clone: `make review` would fail with
`make: *** No rule to make target 'review'`, and even a hand-run of the
target would fail because `bin/review.sh` would not exist.

This is exactly the "Follow-ups (not this task)" item at the bottom of
`docs/plans/2026-09-16-readme-poc-docs.md`:

> Consider committing the currently-untracked `Makefile` and `bin/` so the
> documented `make review` command works from a clean clone.

The fix is to bring the two existing files under version control unchanged.
Nothing in either file needs to change; the only defect is that they are not
tracked.

Verified against the repo on 2026-09-25:

- `git status --porcelain` shows `?? Makefile`, `?? bin/`,
  `?? briefing_gather_gmail.py`, and `?? memory/` as untracked.
- `git ls-files` does not list `Makefile` or `bin/review.sh` (they are
  untracked); it does list the committed `README.md`, `src/login.js`, the
  three `.claude-unleashed/**` yaml files, and the `docs/plans/**` +
  `docs/reviews/**` files.
- `bin/` contains exactly one file, `bin/review.sh` (mode `-rwxr-xr-x`,
  i.e. executable). `git add -n Makefile bin/` stages exactly two paths:
  `Makefile` and `bin/review.sh` — nothing else.
- Neither file is gitignored: `git check-ignore Makefile bin/review.sh`
  exits non-zero (no match). `.gitignore` only lists `node_modules/` and
  `.DS_Store`.
- `core.fileMode` is `true`, so staging `bin/review.sh` records it as mode
  `100755` (executable) in git.
- `Makefile` (unchanged) is:
  ```
  .PHONY: review

  # Launch the repo-scoped review-team against the sample file and print the verdict.
  review:
  	@bash bin/review.sh
  ```
  Its `review` target runs `@bash bin/review.sh` — it invokes the script via
  `bash`, so `make review` does not strictly depend on the script's
  executable bit, but the exec bit should still be preserved (it is the
  file's real mode and callers may run `./bin/review.sh` directly).
- `bin/review.sh` (unchanged) is a `set -euo pipefail` bash script that sets
  `CU=/opt/homebrew/bin/cu` (with the comment that `/usr/bin/cu` UUCP shadows
  it on PATH), computes `REPO="$(git rev-parse --show-toplevel)"`, and runs
  `"$CU" run --repo "$REPO" --agent-group review-team ...`.
- `git remote get-url origin` returns no remote. There is no push/PR step in
  this plan; it is out of scope.

## Scope

In scope:
- Track (git-add + commit) the existing `Makefile` and `bin/review.sh`
  **unchanged**, so `make review` resolves from a clean clone.

Out of scope (do NOT do these here):
- Do not modify, "fix", or track `src/login.js`. Its SQL injection and
  plaintext password compare are deliberate bait for the review agents;
  fixing them defeats the demo. It is already tracked and stays untouched.
- Do not change the **content** of `Makefile` or `bin/review.sh`. The goal
  is only to bring the existing files under version control as-is. Preserve
  `bin/review.sh`'s executable bit (do not chmod it).
- Do not track `briefing_gather_gmail.py` or `memory/`. Those are unrelated
  personal artifacts, out of scope. Only `Makefile` and `bin/review.sh`
  (i.e. the `bin/` directory, which contains only `review.sh`) get staged.
- Do not add a JS test framework, `package.json`, or edit the README or the
  agent YAML.
- Do not push to a remote or open a PR (no functional remote exists).

## TDD approach

There is no runtime under test here; the change is purely "make these two
files version-controlled." So the "test" is a presence check run from the
repo root: it asserts that `git ls-files` includes both `Makefile` and
`bin/review.sh`, and that from that tracked set a clean-clone `make review`
would find its script (`make` sees the `review` target and `bin/review.sh`
exists on disk). Red (files untracked -> check fails) -> Green (stage +
commit -> check passes) -> verify.

### Task 1: Red - confirm the acceptance check fails

Run this from the repo root and confirm it prints `FAIL`. The `grep`
patterns are anchored to whole `git ls-files` lines so they match the tracked
paths exactly and cannot be satisfied by an untracked working-tree file:

```
git ls-files | grep -qx 'Makefile' \
  && git ls-files | grep -qx 'bin/review.sh' \
  && echo PASS || echo FAIL
```

Expected result: `FAIL` (both paths are currently untracked, so `git
ls-files` lists neither). Do not stage or commit anything in this task; just
confirm the failure.

### Task 2: Green - stage the two files

Stage exactly the two in-scope paths, unchanged:

```
git add Makefile bin/review.sh
```

Then confirm the staged set is exactly those two paths and nothing else —
in particular that `briefing_gather_gmail.py` and `memory/` are NOT staged:

```
git diff --cached --name-only
```

Expected output (exactly these two lines, in any order):

```
Makefile
bin/review.sh
```

Also confirm `bin/review.sh` is staged as an executable (mode `100755`),
i.e. its exec bit is preserved:

```
git ls-files -s bin/review.sh
```

Expected: the mode field is `100755` (a line like
`100755 <hash> 0	bin/review.sh`). Do not `git add` any other path; do not
edit either file. Do not commit yet.

### Task 3: Verify - confirm the check passes after commit

Commit (see Commit section for the message), then re-run the Task 1 check
from the repo root and confirm it prints `PASS`:

```
git ls-files | grep -qx 'Makefile' \
  && git ls-files | grep -qx 'bin/review.sh' \
  && echo PASS || echo FAIL
```

Expected result: `PASS` (both paths are now tracked). The `grep -qx`
patterns (`'Makefile'` and `'bin/review.sh'`) match the exact whole lines
`git ls-files` prints for those tracked paths, so the check's wording matches
what it actually asserts.

Then confirm a clean-clone `make review` would resolve — the `review` target
is defined and the script it calls is now tracked:

```
make -n review
git ls-files | grep -qx 'bin/review.sh' && echo SCRIPT_TRACKED || echo SCRIPT_MISSING
```

Expected: `make -n review` prints the recipe (`bash bin/review.sh`) and exits
0 (proving the `review` target resolves), and the second line prints
`SCRIPT_TRACKED`. Together these show that a fresh `git clone` of `main`
would contain both the `Makefile` (so `make review` finds the target) and
`bin/review.sh` (so the recipe finds its script). Note: `make -n` only
dry-runs the recipe; it does not execute `cu`, so it does not require the
`cu` CLI to be installed.

Finally, confirm the out-of-scope untracked artifacts were left alone:

```
git status --porcelain
```

Expected: still shows `?? briefing_gather_gmail.py` and `?? memory/` as
untracked, and shows no staged/modified/untracked entry for `Makefile` or
`bin/review.sh` (both are now committed).

## Commit

Single commit on `main`, made in Task 3 once staging (Task 2) is confirmed:

```
build: track Makefile and bin/review.sh so `make review` works from a clean clone
```

Stage exactly these two paths and nothing else:
- `Makefile`
- `bin/review.sh`

Use `git add Makefile bin/review.sh` (equivalently `git add Makefile bin/`,
since `bin/` contains only `review.sh`). Do NOT stage
`briefing_gather_gmail.py`, `memory/`, `src/login.js`, or any other path.
After committing, verify with `git status --porcelain` that `Makefile` and
`bin/review.sh` no longer appear (they are committed) while
`briefing_gather_gmail.py` and `memory/` remain untracked.

## Follow-ups (not this task)

- Optional correctness nit (do NOT change it in this task): `bin/review.sh`
  hardcodes `CU=/opt/homebrew/bin/cu`. This is intentional (the README
  documents the `/usr/bin/cu` UUCP footgun), but a future change could make
  it overridable, e.g. `CU="${CU:-/opt/homebrew/bin/cu}"`, so callers on
  non-Homebrew paths can point at their own `cu` without editing the script.
- Consider whether `briefing_gather_gmail.py` and `memory/` should be
  gitignored (they are unrelated personal artifacts that keep showing up in
  `git status`). Out of scope here; only note it.
