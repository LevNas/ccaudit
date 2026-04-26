<!--
Thanks for contributing to ccaudit! Please fill out the sections below so review
can move quickly. See CONTRIBUTING.md for the full guidelines.
-->

## Summary

<!-- 1-3 sentences: what changes, and why. Link the issue this PR addresses. -->

## Type of change

- [ ] Bug fix
- [ ] New feature
- [ ] Documentation only
- [ ] Test / CI / governance
- [ ] Refactor (no behavior change)

## Checklist

- [ ] **Vendor neutrality preserved** — no organization-specific token prefixes, hostnames, customer names, or proprietary token formats added to `hooks/auto-flush.sh` or `docs/secret-patterns.md`. (See [CONTRIBUTING.md § Vendor neutrality](../CONTRIBUTING.md#vendor-neutrality).)
- [ ] **Secret-pattern lockstep** — if this PR edits regex in `hooks/auto-flush.sh`, `docs/secret-patterns.md` is updated in the **same commit** with rationale and example shape.
- [ ] **Smoke test passes** — `bash test/smoke-test.sh` exits 0 locally. CI will re-run it.
- [ ] **Documentation updated** — `README.md` / `docs/` / `SKILL.md` reflect any user-visible behavior change.
- [ ] **CHANGELOG updated** — an entry under `[Unreleased]` (or the target version) describes the change.
- [ ] **One logical change** — this PR addresses a single concern. Refactors are separate from behavior changes.

## Notes for reviewer

<!--
Anything reviewers should know but doesn't fit above:
- New external dependencies, with justification
- Decisions you'd like a second opinion on
- Out-of-scope items deferred to follow-up issues
-->
