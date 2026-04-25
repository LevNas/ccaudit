# Roadmap

0.1.0 ships the smallest useful surface. Items below are candidates for subsequent versions. No guarantees about order or inclusion — listed so operators know what to expect and where to open issues.

## 0.2.x candidates

### `/audit-review` skill

Audit-side helper. Reads the trail repository, groups entries by scope, and drafts finding templates for the auditor to complete. Does not cross the independence line — still read-only against the trail repository. Unlocks once the manual process in `docs/operating-audit-side.md` has stabilized through at least one real audit cycle.

### `/audit-scope` skill

Resolves whether a given business operation is in scope for audit trailing. Reads a business catalog (operator-provided YAML) and answers yes / no / undecided. Kept out of 0.1.0 because the catalog format is operator-specific and standardizing it prematurely would force compromises.

### Secret scan as a pluggable library

Currently the pattern list lives in `hooks/auto-flush.sh` and the shared logic is duplicated between hook and skill. A small library (`lib/scan.sh`) with a single function the two call would remove the duplication.

### WORM enforcement helper

Script that enforces append-only on the trail repository: refuses to push if any existing file in `trails/` would be deleted or rewritten. Today this is the remote's responsibility (branch protection, signed commits). An in-plugin check catches mistakes earlier.

### `SessionEnd` hook alongside `Stop`

Claude Code exposes both. `Stop` fires when the current turn ends; `SessionEnd` fires when the session closes. For long-running sessions, `SessionEnd` is the more reliable fallback. Low effort to add once we see real gaps.

## Longer term / ideas

### Schema validation at flush time

Reject entries that omit any of the five required fields. 0.1.0 trusts the AI to produce valid entries because the alternative — silent staging rejections — is worse than relaxed validation. Promote to hard enforcement once we have a validated-entry test corpus.

### Entry linting for sensitive body text

Go beyond regex secret patterns: flag entries whose body looks like it contains a large base64 blob, a long hex run, or a high-entropy string. Requires careful false-positive handling.

### Multi-repo trail aggregation

A single operator may generate trails for multiple business lines. 0.1.0 assumes one trail repo per operator. A future version could route to different trail repositories based on the entry's `business_id`.

### Trail query CLI

Separate from the plugin: a small CLI that reads the trail repository and answers "show me every entry where `approval.method == stop_hook` and `risk_level == high` in Q2". Not plugin territory, but related tooling.

## Explicit non-goals

- **Compliance regime mapping.** ccaudit will not claim conformance with any specific standard. The gap between primitive audit trail and specific-regime compliance is the operator's to bridge.
- **Real-time streaming to a SIEM.** The trail is commit-based, not stream-based. Streaming is a different problem requiring different architecture.
- **Encryption of trail entries at rest.** Use the trail repository's own encryption (git-crypt, SOPS at rest, or server-side encryption on the hosting provider). Layering another encryption inside ccaudit adds key management without clear benefit.

## How to propose a candidate

File an issue describing the operator scenario — not the feature. "I run audit cycle every quarter and spend two days cross-referencing knowledge commits" tells us more than "please add a cross-reference command." Proposals grounded in a scenario tend to survive the scope filter.
