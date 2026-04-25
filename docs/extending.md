# Extending ccaudit

ccaudit 0.1.0 ships only the pieces that every operator needs. Environment-specific behavior is injected through a small set of extension points.

## Extension points

### `CCAUDIT_PRE_FLUSH_HOOK`

A path to an executable script. Called once per flush (hook invocation and `/audit-flush` both honor it) with the entry paths as arguments:

```
$CCAUDIT_PRE_FLUSH_HOOK entry1.md entry2.md ...
```

- Exit code `0` — flush proceeds.
- Any non-zero exit — entries move to `$CCAUDIT_PENDING_DIR`, push is skipped.

Use this for:

- **Environment-specific secret patterns** that must not ship in the public plugin (internal token prefixes, internal hostnames). Keep those patterns in an internal script under your dotfiles or operator repo, never in a PR to this plugin. The generic patterns the plugin already covers are listed in [secret-patterns.md](secret-patterns.md) — write your hook to complement, not duplicate, them.
- **Business catalog validation** — check that every entry's `business_id` resolves in your catalog before pushing.
- **Retention rules** — reject entries older than N days to force timely flushing.

### Extending the trail entry schema

The five required fields are fixed. Everything else is free. Operators commonly add:

- Organizational IDs (`project_id`, `tenant`, `cost_center`).
- Tool-specific provenance (`tmux_pane`, `claude_session_id`).
- Risk or sensitivity flags.

Downstream consumers should tolerate unknown fields. If you build your own reader, treat `prompt`, `referenced_knowledge`, `output_summary`, `model`, and `approval` as the stable surface and everything else as best-effort.

### Splitting the audit side

The plugin is installed on work machines. The audit side is typically a separate Claude Code profile or machine that only has read access to the trail repository. There is no coupling between the two sides other than the trail repository itself.

See `docs/operating-audit-side.md` for the recommended arrangement.

### Custom commit message

Not a real extension point in 0.1.0 — the message template is fixed. If you need a different message, write a local fork or ask for an extension point via an issue. (Keep the `[manual]` suffix on manual flushes, or your audit log loses the distinction.)

### Hooks beyond Stop

0.1.0 only registers a `Stop` hook. Future versions may add `SessionEnd` or `PostToolUse` hooks. If you need those behaviors today, register your own hook in your `settings.json`; the plugin will not conflict.

## What NOT to extend

- **The generic secret-pattern list in `hooks/auto-flush.sh`.** That list is the vendor-neutral baseline. Adding environment-specific patterns there leaks operational detail into the public plugin. Keep those in `CCAUDIT_PRE_FLUSH_HOOK`.
- **The flush success side effect.** The plugin deletes from `CCAUDIT_STAGING_DIR` only on successful push. Do not override this — a "keep on success" mode breaks the mental model that staging is a single-flight buffer.

## Contributing upstream

Patterns, docs, and non-trivial flow changes are welcome. Please follow the rule above: nothing in the plugin, docs, or tests should contain a real-world organization name, host name, token prefix, or business-specific pattern. Use `example-org`, `project-a`, `alice`, and the like.
