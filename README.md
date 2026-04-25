# ccaudit

Record and preserve audit trails of AI-assisted work so humans can verify and attest.

`ccaudit` is a Claude Code plugin that captures what the AI did during a session (prompts, referenced knowledge, outputs, model identity, approval record), stages those entries locally, and automatically pushes them to a dedicated trail repository when the session ends. Humans inspect the trail later to verify or attest; the plugin never lets the AI or the user cherry-pick which entries make it into the archive.

## Why this exists

If AI agents do work on your behalf in regulated environments, you need to show *what the agent did and why*. Existing git history only records what was committed to the product repository — it does not record the reasoning chain, the knowledge the agent relied on, or who approved the result. `ccaudit` fills that gap.

The plugin is intentionally agnostic to any specific compliance regime. It provides the primitive (append-only trail with structured metadata); mapping to a particular regulation is the operator's responsibility.

## What it does

- **Stage entries during work.** The AI writes trail entries as Markdown files with a 5-field frontmatter (see [docs/trail-format.md](docs/trail-format.md)) into a staging directory.
- **Auto-flush on session end.** A `Stop` hook scans the staging directory, runs a secret scan, and pushes all entries as a single commit to a remote trail repository. No human intervention required for routine flushing.
- **Fail safe, not silent.** If the secret scan finds a match or the push fails, entries are moved to a pending directory and the next session re-announces them.
- **Inspectable by hand.** `/audit-flush` lets you preview, dry-run, force-retry, or manually approve flushes when you need a paper trail of human decision.

## Install

Via Claude Code plugin system:

```bash
# once a marketplace registration exists — for now, clone locally
git clone https://github.com/LevNas/ccaudit ~/.claude/plugins/ccaudit
```

Then set the trail repository:

```bash
export CCAUDIT_TRAIL_REPO="git@example.org:example-org/ops-audit-trail.git"
```

The plugin is knowingly ignorant of where your trail repo lives — you point it at one, ccaudit pushes there.

## Configuration

All settings are environment variables. Only `CCAUDIT_TRAIL_REPO` is required.

| Variable | Default | Purpose |
|---|---|---|
| `CCAUDIT_TRAIL_REPO` | *(required)* | Remote URL of the trail repository. |
| `CCAUDIT_STAGING_DIR` | `./audit-trail-staging` | Where the AI writes entries during a session. |
| `CCAUDIT_PENDING_DIR` | `./audit-trail-pending` | Where entries go if flush is aborted (secret hit or push fail). |
| `CCAUDIT_SIGN` | `0` | Set to `1` to require signed commits. |
| `CCAUDIT_MANUAL` | `0` | Set to `1` to disable auto-flush; use `/audit-flush` only. |
| `CCAUDIT_HOOK_DISABLE` | `0` | Set to `1` to silence the Stop hook without disabling `/audit-flush`. |
| `CCAUDIT_PRE_FLUSH_HOOK` | *(unset)* | Path to an extra script run before flush; non-zero exit aborts flush. |

## How the flow looks

```
[session starts]
  AI works, writes entries to $CCAUDIT_STAGING_DIR/
      20260423-103012-<slug>.md
      20260423-103415-<slug>.md
      ...

[session ends — Stop hook fires]
  1. Count staged entries (0 → exit silently)
  2. Run secret scan
       hit → move all to $CCAUDIT_PENDING_DIR, notify, do NOT push
  3. Run optional $CCAUDIT_PRE_FLUSH_HOOK
       non-zero → move to pending, notify
  4. git commit + push to $CCAUDIT_TRAIL_REPO in one commit
       fail → move to pending, notify
  5. Clear $CCAUDIT_STAGING_DIR on success
```

No review gate in the routine path. The *absence* of a gate is the design — see [docs/trail-format.md](docs/trail-format.md) for why the record's integrity comes from append-only capture, not from a review step.

## Bundled secret patterns

The Stop hook and `/audit-flush` share a vendor-neutral pattern list. Hits move the offending entries to `$CCAUDIT_PENDING_DIR` instead of pushing them.

| Family | Pattern shape |
|---|---|
| GitHub PAT (classic) | `ghp_` + 36 alphanumeric |
| GitHub PAT (fine-grained) | `github_pat_` + 82 alphanumeric/underscore |
| GitLab PAT | `glpat-` + 20 alphanumeric/underscore/hyphen |
| AWS Access Key ID | `AKIA` or `ASIA` + 16 uppercase alphanumeric |
| OpenAI API key (classic) | `sk-` + 48 alphanumeric |
| OpenAI API key (project) | `sk-proj-` + 40+ alphanumeric/underscore/hyphen |
| PEM private key header | `-----BEGIN [variant ]PRIVATE KEY-----` |
| JWT (signed) | `eyJ...` `.` `eyJ...` `.` signature, base64url segments |

Full regexes, rationale, and false-positive notes are in [docs/secret-patterns.md](docs/secret-patterns.md). For environment-specific patterns, layer them on with `CCAUDIT_PRE_FLUSH_HOOK` rather than editing the bundled list — see [docs/extending.md](docs/extending.md).

## Smoke test

```bash
bash test/smoke-test.sh
```

Sets up a throwaway local bare repo, runs the hook against a clean entry and a PEM-tainted entry, and asserts that the clean one flushes through while the tainted one is blocked. No external network or credentials required.

## `/audit-flush`

Use when you want to act on the staging directory manually:

```
/audit-flush               # same behavior as Stop hook, run on demand
/audit-flush --dry-run     # show what would be flushed, do nothing
/audit-flush --force       # retry pending/ even if still failing
```

## Extending

`ccaudit` is designed to be the thin minimum. Extensions you can bolt on without forking:

- Custom secret patterns — set `CCAUDIT_PRE_FLUSH_HOOK` to a script that greps your specifics (see [docs/extending.md](docs/extending.md)). The bundled generic patterns are catalogued in [docs/secret-patterns.md](docs/secret-patterns.md).
- Custom entry fields — trail entries accept arbitrary frontmatter fields beyond the required five (see [docs/trail-format.md](docs/trail-format.md)).
- Separate auditor inspection — point a second Claude Code session at a clone of the trail repo only; the audit side never reads the working repos (see [docs/operating-audit-side.md](docs/operating-audit-side.md)).

## What's not in 0.1.0

- `/audit-review` (audit-side AI helper) — use the pattern in `docs/operating-audit-side.md` instead.
- `/audit-scope` (business catalog check) — scope belongs to your catalog repository, not to ccaudit.
- Built-in WORM/append-only enforcement beyond git — use a bare repo with write protection on the remote.

See [docs/roadmap.md](docs/roadmap.md) for candidates.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for the project's scope, the vendor-neutrality rule for the bundled secret-pattern list, plugin conventions, the smoke test, and pull request guidelines.

## License

This project is licensed under the [MIT License](LICENSE) — see the `LICENSE` file for the full text.

In short: you're free to use, modify, and redistribute ccaudit, including for commercial purposes, as long as you keep the copyright notice and license text.

If you build something based on ccaudit, a credit line is appreciated (not required):

> Based on [ccaudit](https://github.com/LevNas/ccaudit) by LevNas.
