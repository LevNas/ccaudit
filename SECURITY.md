# Security Policy

ccaudit handles audit trails of AI-assisted work and ships a vendor-neutral secret scanner. A defect in either path can let sensitive content leak into a remote trail repository, so security reports take priority over feature work.

## Reporting a Vulnerability

**Use GitHub Security Advisories** — the private reporting form at:

<https://github.com/LevNas/ccaudit/security/advisories/new>

This channel keeps the report private until a fix is ready and lets us coordinate disclosure with you. Do not file a public issue for security defects.

If GitHub Security Advisories is unavailable to you for some reason, open a public issue titled `SECURITY: please contact me` (no details) and we will follow up through GitHub's messaging.

### What to include

- ccaudit version (tag or commit hash) and how it was installed
- Reproduction steps — minimal staging entry, environment variables in use, and the exact behavior you observed
- Why you consider it a security defect (which property of ccaudit was violated)
- Whether you have a suggested fix

You do not need to provide a CVE proposal or CVSS score. We will assess severity together.

## Response Targets

Solo-maintained pre-1.0 project. Targets are best-effort, not contractual:

| Step | Target |
|------|--------|
| Acknowledge receipt | Within 7 days |
| Initial severity assessment | Within 14 days |
| Fix or formal "won't fix" decision | Negotiated case-by-case |

We will tell you which release will carry the fix and coordinate the public advisory with you.

## Scope

### In scope

Defects in code shipped from this repository that compromise the audit trail's integrity or leak sensitive data:

- **Secret scanner bypass** — any input that contains a pattern in `docs/secret-patterns.md` but is not caught by `hooks/auto-flush.sh` and reaches the trail repo.
- **Wrong remote** — any path where the hook or skill pushes to a destination other than `CCAUDIT_TRAIL_REPO`.
- **Disclosure of pending entries** — pending entries leaking into log files, environment dumps, or the trail repo without the secret scan running first.
- **Trail entry corruption** — a flush that writes an entry that does not match the source content, or that overwrites an existing trail entry.
- **Privilege escalation through the hook** — anything in `hooks/auto-flush.sh` that lets a hostile staging entry execute arbitrary commands beyond `git` invocations on the trail repo.
- **Smoke-test false success** — a state where `test/smoke-test.sh` reports PASS while the asserted property is actually violated (the grep `-e` / `--` fix in `bbca869` is the canonical example).

### Out of scope

These are deliberate non-goals (also documented in [`docs/roadmap.md`](docs/roadmap.md)):

- **Authentication and authorization on the trail repository.** Push credentials and branch protection are the operator's responsibility.
- **Encryption of trail entries at rest.** Use the trail repository's own encryption (git-crypt, SOPS, server-side encryption).
- **Compliance regime mapping.** ccaudit is a primitive; conformance with any specific standard is the operator's bridge to build.
- **Vulnerabilities in operator-supplied `CCAUDIT_PRE_FLUSH_HOOK` scripts.** That is operator code, not shipped by ccaudit.
- **Vulnerabilities in environment-specific secret patterns.** Layer those with `CCAUDIT_PRE_FLUSH_HOOK`; the bundled list is generic-only by policy (see `CONTRIBUTING.md`).

If you are unsure whether your finding is in scope, file the report anyway. Boundary calls are easier to make from a concrete report.

## Supported Versions

Pre-1.0. Only the latest released minor version receives security fixes.

| Version | Supported |
|---------|-----------|
| 0.1.x   | Yes (current) |
| < 0.1.0 | No |

When 0.2.0 ships, 0.1.x will receive security fixes for 90 days, then move to unsupported.

## Coordinated Disclosure

Default flow:

1. You report via GitHub Security Advisory.
2. We acknowledge and assess.
3. We prepare a fix in a private branch, you review it if you wish, and we agree on the publication date.
4. The fix lands on `main`, a release is tagged, and the advisory is published on the same day. Credit goes to you unless you prefer to remain anonymous.

Embargo length is negotiated. We will not sit on a confirmed defect indefinitely.
