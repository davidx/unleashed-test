# Plan: Add a README for the review-team PoC

Date: 2026-07-21
Branch: main
Status: ready for executor

## Problem

This repo is a claude-unleashed "review-team" proof of concept, but it has
zero documentation. A newcomer cannot tell what it is, how to run it, or that
`src/login.js` is intentionally vulnerable bait for the security agent. The
entrypoints (`Makefile`, `bin/review.sh`) are also currently untracked, and the
one non-obvious footgun (a `cu` binary that is shadowed on PATH by `/usr/bin/cu`)
is buried in a shell comment.

A single `README.md` at the repo root fixes all of this. It is small, safe,
self-contained, and does not touch the intentionally-flawed sample.

## Scope

In scope:
- Add `README.md` at the repo root.

Out of scope (do NOT do these here):
- Do not modify `src/login.js`. Its SQL injection and plaintext password compare
  are deliberate bait for the review agents; fixing them defeats the demo.
- Do not add a JS test framework, package.json, or `src/db.js`.
- Do not change the agent YAML or `bin/review.sh` behavior.

## TDD approach

There is no JS runtime under test here, so the "test first" gate is a set of
presence checks against the README content. Write the check first, watch it
fail (no README exists), then add the README so the check passes.

### Task 1: Red - assert the README exists and covers the essentials

Before writing any prose, define the acceptance check. Run this and confirm it
FAILS (README.md does not exist yet):

```
test -f README.md \
  && grep -q "make review" README.md \
  && grep -qi "intentionally" README.md \
  && grep -qi "prerequisite" README.md \
  && grep -q "cu" README.md \
  && echo PASS || echo FAIL
```

Expected before implementation: `FAIL`.

### Task 2: Green - write README.md

Create `README.md` at the repo root with these sections, kept short and plain
(simple, minimal, no em dashes):

1. Title and one-line description
   - What it is: a repo-scoped claude-unleashed review-team PoC (a reviewer
     agent plus a security agent) that reviews the current git changes.

2. Prerequisites
   - The `cu` CLI installed at `/opt/homebrew/bin/cu`. Note the footgun: on some
     systems `/usr/bin/cu` (UUCP) shadows it on PATH, which is why
     `bin/review.sh` calls the absolute path.
   - Node.js (present for the sample source).

3. Layout
   - `src/login.js` - a DELIBERATELY vulnerable sample (SQL injection, plaintext
     password compare) used as bait so the review agents have something to find.
     State clearly that it is intentional and must not be "fixed".
   - `bin/review.sh` - launches the review-team against the current repo diff.
   - `Makefile` - `make review` wraps the script.
   - `.claude-unleashed/agents/*.yaml` - the reviewer and security agent defs.
   - `.claude-unleashed/agent-groups/review-team.yaml` - bundles the two agents.

4. Usage
   - `make review` (or `bash bin/review.sh`) runs the review-team and prints its
     findings as commentary only.

5. Notes
   - The review is commentary-only; the agents are read-only (Read/Grep/Glob)
     and never edit files.

### Task 3: Verify - re-run the check

Re-run the Task 1 check and confirm it now prints `PASS`.

## Commit

Single commit on `main`:

```
docs: add README for review-team PoC
```

## Follow-ups (not this task)

- Consider committing the currently-untracked `Makefile` and `bin/` so the
  documented `make review` command works from a clean clone.
