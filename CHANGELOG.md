# Changelog

All notable changes to ccaudit are documented here. Format is loosely Keep-a-Changelog; dates in ISO-8601.

## [0.1.0] — 2026-04-25

First release. Intentionally minimal.

### Added

- `Stop` hook (`hooks/auto-flush.sh`) that scans the staging directory on session end, runs a vendor-neutral secret scan, and pushes all entries as a single commit to the configured trail repository.
- `/audit-flush` skill for manual inspection (`--dry-run`) and retry (`--force`) — same flow as the hook, invoked on demand, emits a `[manual]` suffix on the commit message so auditors can distinguish unattended from attended flushes.
- Trail entry format defined in `docs/trail-format.md`: five required frontmatter fields, operator-extensible with arbitrary additional fields.
- Secret-pattern catalog in `docs/secret-patterns.md` documenting every regex shipped with the plugin. Updated in lockstep with `hooks/auto-flush.sh` so the rationale stays auditable.
- Eight bundled secret patterns covering GitHub PATs (classic and fine-grained), GitLab PATs, AWS access key IDs (permanent and STS), OpenAI API keys (classic and project), PEM private key headers (any variant), and signed JWTs.
- Extension points via environment variables (see `README.md` and `docs/extending.md`): `CCAUDIT_TRAIL_REPO`, `CCAUDIT_STAGING_DIR`, `CCAUDIT_PENDING_DIR`, `CCAUDIT_SIGN`, `CCAUDIT_MANUAL`, `CCAUDIT_HOOK_DISABLE`, `CCAUDIT_PRE_FLUSH_HOOK`.
- Audit-side operating guide in `docs/operating-audit-side.md` for running a separate Claude Code profile that reads the trail repository read-only.
- Mock trail fixture under `test/fixtures/mock-audit-trail/` and an automated end-to-end check at `test/smoke-test.sh` that exercises both the clean-flush and secret-blocked paths against a throwaway local bare repo.

### Known limitations

- The bundled secret-pattern list does not yet cover OpenAI service-account or admin keys (`sk-svcacct-`, `sk-admin-`) or non-AWS cloud provider keys (GCP service accounts, Azure SAS, etc.). Layer environment-specific patterns on with `CCAUDIT_PRE_FLUSH_HOOK` until they are added; see `docs/secret-patterns.md` for the open list.
- No schema validation at flush time. Entries with missing required fields are pushed as-is.
- No recovery tool for orphaned pending entries beyond `/audit-flush --force`.
- No built-in WORM enforcement. Relies on the remote's branch protection / signed commits.

### Not shipped (see `docs/roadmap.md`)

- `/audit-review` skill for the audit side.
- `/audit-scope` skill for business catalog checks.
- Schema validation, WORM helper, multi-repo routing, entry linting.
