# unleashed-test

A repo-scoped [claude-unleashed](https://github.com) review-team proof of
concept. A `reviewer` agent and a `security` agent read the current git diff
and report findings as commentary only.

## Prerequisites

- The `cu` CLI installed and available on PATH (or at a standard Homebrew
  location). The script auto-detects the binary and skips the macOS
  `/usr/bin/cu` UUCP tool. You can also set `CU=/path/to/cu` to override
  detection.
- Node.js, present because the sample source under review is JavaScript.
  There is no `package.json` and nothing to install.

## Layout

- `src/login.js` - an intentionally vulnerable sample (SQL injection via
  string concatenation, plaintext password compare). It exists as bait so
  the review agents have something to find. It is intentional and must not
  be "fixed".
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

Set `CU=/path/to/cu` before running if the auto-detection does not find your
`cu` binary.

## Notes

The review-team is commentary-only: both agents are restricted to
`Read`/`Grep`/`Glob` and never edit files. Findings on `src/login.js` are
expected and by design; do not "fix" that file based on the review output.
