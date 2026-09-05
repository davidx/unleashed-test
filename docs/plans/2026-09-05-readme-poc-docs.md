# Plan: Add a README for the review-team PoC

Date: 2026-09-05
Branch: main
Status: ready for executor

> AGENTIC-WORKER NOTE: Implement this plan task-by-task. Follow red-green-refactor
> for every task: run the check and see it fail, make the smallest change that
> passes it, then move on. One task, one commit. Never batch multiple tasks into
> a single commit or skip ahead.

## Problem

This repo is a claude-unleashed "review-team" proof of concept, but `main` has
no `README.md`. A newcomer cannot tell what the repo is, how to run it, or that
`src/login.js` is intentionally vulnerable bait for the security agent. The
entrypoints (`Makefile`, `bin/review.sh`) exist in the working tree but are
untracked, and the one non-obvious footgun (`/usr/bin/cu`, the UUCP binary,
shadowing the real `cu` CLI on PATH) is buried in a shell comment.

A single `README.md` at the repo root fixes this. It is small, safe,
self-contained, and does not touch the intentionally-flawed sample.

Verified against the current repo state:
- `README.md` does not exist at the repo root.
- `src/login.js` contains a deliberate SQL injection (string-concatenated query)
  and a plaintext password compare, with a comment marking it as bait.
- `Makefile` has a `review` target that runs `bash bin/review.sh`.
- `bin/review.sh` calls `/opt/homebrew/bin/cu run --repo "$REPO" --agent-group
  review-team ...` and comments that `/usr/bin/cu` (UUCP) shadows the real `cu`
  on PATH, which is why it uses the absolute path.
- `.claude-unleashed/agents/reviewer.yaml` and `.claude-unleashed/agents/security.yaml`
  define the two review agents; `.claude-unleashed/agent-groups/review-team.yaml`
  bundles them as `review-team`.
- `Makefile` and `bin/` are currently untracked (`git status --porcelain` shows
  `?? Makefile` and `?? bin/`). This plan does not track them; that is a
  follow-up, not part of this task.

## Scope

In scope:
- Add `README.md` at the repo root.

Out of scope (do NOT do these here):
- Do not modify `src/login.js`. Its SQL injection and plaintext password compare
  are deliberate bait for the review agents; fixing them defeats the demo.
- Do not add a JS test framework, `package.json`, or `src/db.js`.
- Do not change the agent YAML, `Makefile`, or `bin/review.sh`.
- Do not track the currently-untracked `Makefile`/`bin/` (leave as-is).

## TDD approach

There is no JS runtime under test here, so the "test first" gate is a set of
presence/content checks against `README.md`, run from the repo root. Red
(checks fail because the file doesn't exist) -> Green (write the file, checks
pass) -> commit.

### Task 1: Red - confirm the acceptance check fails

Run this from the repo root and confirm it prints `FAIL`:

```
test -f README.md \
  && grep -q "make review" README.md \
  && grep -qi "intentionally" README.md \
  && grep -qi "prerequisite" README.md \
  && grep -q "/opt/homebrew/bin/cu" README.md \
  && grep -q "src/login.js" README.md \
  && echo PASS || echo FAIL
```

Expected result: `FAIL` (no `README.md` exists yet). Do not write any file in
this task; just confirm the failure.

### Task 2: Green - write README.md

Create `README.md` at the repo root with exactly these sections, in this
order, kept short and plain (no em dashes):

```markdown
# unleashed-test

A repo-scoped [claude-unleashed](https://github.com) review-team proof of
concept. A `reviewer` agent and a `security` agent read the current git diff
and report findings as commentary only.

## Prerequisites

- The `cu` CLI installed at `/opt/homebrew/bin/cu`.
  Footgun: on macOS, `/usr/bin/cu` (the UUCP dial-out tool) shadows the real
  `cu` on PATH. `bin/review.sh` calls the absolute path
  `/opt/homebrew/bin/cu` for this reason. If `cu` is installed elsewhere,
  update that path.
- Node.js, present because the sample source under review is JavaScript.
  There is no `package.json` and nothing to install.

## Layout

- `src/login.js` - a DELIBERATELY vulnerable sample (SQL injection via string
  concatenation, plaintext password compare). It exists as bait so the review
  agents have something to find. It is intentional and must not be "fixed".
- `bin/review.sh` - launches the review-team against the current repo's
  uncommitted changes (`git diff HEAD`).
- `Makefile` - `make review` wraps `bin/review.sh`.
- `.claude-unleashed/agents/reviewer.yaml` - read-only code reviewer agent
  (no edits, no shell).
- `.claude-unleashed/agents/security.yaml` - read-only security-focused
  reviewer agent (OWASP-style findings).
- `.claude-unleashed/agent-groups/review-team.yaml` - bundles `reviewer` and
  `security` into the `review-team` agent group.

## Usage

```
make review
```

This runs `bin/review.sh`, which invokes `cu run --repo <repo> --agent-group
review-team` and prints the reviewer and security findings for the current
diff.

## Notes

The review-team is commentary-only: both agents are restricted to
`Read`/`Grep`/`Glob` and never edit files. Findings on `src/login.js` are
expected and by design; do not "fix" that file based on the review output.
```

After creating the file, re-run the Task 1 check.

### Task 3: Verify - confirm the check now passes

Run the same check from Task 1 again and confirm it prints `PASS`:

```
test -f README.md \
  && grep -q "make review" README.md \
  && grep -qi "intentionally" README.md \
  && grep -qi "prerequisite" README.md \
  && grep -q "/opt/homebrew/bin/cu" README.md \
  && grep -q "src/login.js" README.md \
  && echo PASS || echo FAIL
```

Expected result: `PASS`.

## Commit

Single commit on `main`, made once Task 3 passes:

```
docs: add README for review-team PoC
```

Stage only `README.md`. Do not stage `Makefile` or `bin/` (they stay
untracked; see Scope).

## Follow-ups (not this task)

- Consider committing the currently-untracked `Makefile` and `bin/` so the
  documented `make review` command works from a clean clone.
