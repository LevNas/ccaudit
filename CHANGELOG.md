# Changelog

All notable changes to ccaudit are documented here. Format is loosely Keep-a-Changelog; dates in ISO-8601.

## [0.1.3] — 2026-06-24

Compatibility fix — no change to the hook's behavior or the secret-pattern list.

### Fixed

- Hook declaration moved out of `plugin.json` into a structured `hooks/hooks.json`. The previous inline shorthand `"hooks": { "Stop": "hooks/auto-flush.sh" }` (a bare-string value) is not accepted by current Claude Code plugin validation, which caused the plugin to fail to load ("error during load") and to silently fail on install — leaving it enabled-but-never-installed. The `Stop` hook now runs via `bash "${CLAUDE_PLUGIN_ROOT}/hooks/auto-flush.sh"` with a 30s timeout, matching the convention used by the other plugins in this marketplace. No change to `auto-flush.sh` or its flush/secret-scan logic.

## [0.1.2] — 2026-04-26

Governance hardening — no code changes to the hook, skill, or secret-pattern list.

### Added

- `SECURITY.md` — vulnerability disclosure policy. Reports go through [GitHub Security Advisories](https://github.com/LevNas/ccaudit/security/advisories/new); explicit in-scope and out-of-scope lists keep operator-side concerns (trail repo authentication, encryption at rest, compliance regime mapping) separate from defects in shipped code. Pre-1.0 support window: latest minor only.
- `.github/workflows/ci.yml` — runs `bash test/smoke-test.sh` on every pull request and push to `main`. The smoke test asserts both clean-flush and secret-blocked paths against a throwaway local bare repo, no external network or credentials. This makes regressions like the `bbca869` grep `-e` / `--` pitfall blockable at PR time rather than relying on memory of a manual `bash test/smoke-test.sh`.
- `.github/PULL_REQUEST_TEMPLATE.md` — checklist mirroring the contract in `CONTRIBUTING.md`: vendor-neutrality preserved, secret-pattern lockstep update, smoke test passed, docs and CHANGELOG updated, one logical change per PR.
- `README.md` Security section pointing at `SECURITY.md`.

## [0.1.1] — 2026-04-25

Documentation and governance only — no code changes.

### Added

- `CONTRIBUTING.md` documenting project scope, the **vendor-neutrality rule** for the bundled secret-pattern list (organization-specific patterns must use `CCAUDIT_PRE_FLUSH_HOOK`, not the bundled list), plugin conventions, smoke-test expectation for PRs, and pull request guidelines.
- Three issue templates under `.github/ISSUE_TEMPLATE/` (bug, feature, question) with a `config.yml` linking contributors to the contributing guide and the vendor-neutrality rule before they file.
- `README.md` License section expanded with MIT terms summary and an attribution request for forks (not a license condition); a new `Contributing` section points at `CONTRIBUTING.md`.

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
