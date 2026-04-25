# Trail entry format

A trail entry is a single Markdown file with a YAML frontmatter block and a free-form body. Entries live as files in `$CCAUDIT_STAGING_DIR` during a session and end up under `trails/YYYY/MM/` in the trail repository after flush.

## Required frontmatter fields (the five)

```yaml
---
prompt: |
  <the exact user prompt that triggered the recorded action>
referenced_knowledge:
  - path: knowledge/path/to/entry.md
    commit: <40-char hash of the knowledge repo at the moment of reference>
output_summary: |
  <a one-to-three paragraph summary of what the AI produced or decided>
model:
  id: claude-opus-4-7
  timestamp: 2026-04-23T10:30:12+09:00
approval:
  who: alice            # string identifier; see "approval vocabulary" below
  method: stop_hook     # stop_hook | audit_flush | pre_flush_hook | none
---
```

All five are required. Missing any of them is a schema violation; downstream tooling should reject the entry.

### Approval vocabulary

- `who` is a free-form string, conventionally the operator's handle. `unattended` means no human was in the loop.
- `method`:
  - `stop_hook` — auto-flush by the Stop hook (the common case).
  - `audit_flush` — a human invoked `/audit-flush`.
  - `pre_flush_hook` — an external hook approved the flush.
  - `none` — the entry bypassed the normal flow (retired/legacy ingest).

## Optional fields

Anything else is allowed. Recommended conventions:

| Field | Purpose |
|---|---|
| `tags` | Space-separated tags for cross-cutting search (e.g. `#infra #migration`). |
| `related_issue` | Issue tracker reference as a URL or `<tracker>#<number>` shorthand. |
| `business_id` | ID from your business catalog (if you maintain one). |
| `risk_level` | `low` / `medium` / `high`. Useful when auditors prioritize. |
| `supersedes` | Filename or commit hash of an entry this one corrects. |

Downstream tooling must tolerate unknown fields — extension fields are the primary way operators specialize the trail for their own regime.

## Body

The body is free-form Markdown. No validation beyond UTF-8. Conventional sections:

- `## Context` — why this action was taken
- `## Actions` — what files or systems were touched, with paths
- `## Evidence` — commit hashes, PR links, ticket links
- `## Notes` — follow-ups, open questions, risks deferred

## Filenames

Entries should be named `YYYYMMDD-HHMMSS-<slug>.md` (session-local time). The auto-flush hook preserves filenames verbatim when moving to `trails/YYYY/MM/` in the trail repository, so name collisions across sessions are the operator's responsibility — use a slug specific enough to avoid collision.

## Why "append-only and ungated by review" is the design

An audit trail whose review step gates what gets recorded is not an audit trail of what happened — it is a sanitized report. The ccaudit default pushes everything the session generated. Corrections are new entries, not edits. The review step that ISMS-style regimes require is satisfied by:

- the commit author on each flush (who attested),
- the timestamp (when),
- the `approval.method` field (how — hook vs. manual).

If you need a stricter attestation mode, set `CCAUDIT_MANUAL=1` to require manual `/audit-flush` invocation for every session. The trade-off is higher risk of the human forgetting to flush, which in turn becomes an audit gap.

## Sample entry

See `test/fixtures/mock-audit-trail/sample-entry.md`.
