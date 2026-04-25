# audit-flush procedure

## 1. Parse flags

Recognize `--dry-run` and `--force`. Unknown flags: print usage to stderr and exit 2.

## 2. Resolve configuration

Read the same environment variables as `hooks/auto-flush.sh`:

- `CCAUDIT_STAGING_DIR` (default `./audit-trail-staging`)
- `CCAUDIT_PENDING_DIR` (default `./audit-trail-pending`)
- `CCAUDIT_TRAIL_REPO` (required for real flush; optional for `--dry-run`)
- `CCAUDIT_SIGN` (default `0`)
- `CCAUDIT_PRE_FLUSH_HOOK` (optional)

## 3. Enumerate entries

- Without `--force`: only `*.md` under `CCAUDIT_STAGING_DIR` (non-recursive).
- With `--force`: union of staging and `CCAUDIT_PENDING_DIR`.

If the list is empty, print `ccaudit: nothing to flush` and exit 0.

## 4. Dry-run exit point

If `--dry-run`, print the list (one path per line) with a trailing summary:

```
N entries would be flushed to <CCAUDIT_TRAIL_REPO or "(CCAUDIT_TRAIL_REPO unset)">
```

Exit 0. Do not touch files, do not scan secrets.

## 5. Secret scan

Reuse the scan logic from `hooks/auto-flush.sh`. On any hit:

- Print the offending pattern.
- Move everything to `CCAUDIT_PENDING_DIR`.
- Exit 0 (non-zero exit would be interpreted as hook failure when run from `/audit-flush`; we want the user to see the notification and decide next action).

## 6. Pre-flush hook

If `CCAUDIT_PRE_FLUSH_HOOK` is set, invoke it with the entry paths as arguments. Non-zero exit: move to pending, exit 0.

## 7. Push

Same push flow as the Stop hook (clone or reuse `$XDG_CACHE_HOME/ccaudit/trail-repo`, copy entries under `trails/YYYY/MM/`, single commit, push).

Commit message template (manual invocation should be distinguishable from hook invocation):

```
audit-trail: add N entries from <hostname> at <iso8601> [manual]
```

The `[manual]` suffix is the only divergence from the hook commit message. Auditors reading the log can see at a glance which flushes had human-in-the-loop confirmation.

## 8. Finalize

- On success: remove the source files from staging (and pending, if `--force`). Print `ccaudit: flushed N entries`.
- On push failure: move to pending, print the error summary. Exit 0.

## Error reporting

All diagnostics go to stderr so structured tooling can parse stdout. stdout carries only the summary line on success and the dry-run listing on `--dry-run`.

## Invariants

- Nothing is deleted from the remote trail repository.
- Entries are never edited in place during flush.
- The secret scan list is identical to the hook's list (single source of truth in `hooks/auto-flush.sh`). If that list is extended, this procedure inherits the extension automatically by sharing the function definition.
