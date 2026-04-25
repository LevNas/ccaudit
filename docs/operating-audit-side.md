# Operating the audit side

ccaudit is installed on working machines. Auditors — or the operator wearing an auditor hat — work from a separate profile that reads the trail repository and nothing else.

This document describes the recommended arrangement for 0.1.0. A future `/audit-review` skill may automate parts of it.

## The split

```
Working machine (subject-of-audit)         Audit machine / profile (auditor)
-------------------------------------      --------------------------------
Claude Code + ccaudit installed            Claude Code, ccaudit NOT installed
Reads: work repositories                   Reads: trail repository only
Writes: trail repository (via flush)       Writes: audit reports (separate repo)
```

The auditor side *never* has credentials for the work repositories. This is not a plugin mechanism — it is an operational invariant. If the auditor needs to see the work itself, they read the commits referenced in trail entries, not the live repository.

## Minimum setup on the audit side

1. Clone the trail repository read-only:

   ```bash
   git clone --depth=1 git@example.org:example-org/ops-audit-trail.git ~/audit/trail
   ```

2. Start a dedicated Claude Code session in that directory. Do not install the ccaudit plugin on this side — the auditor does not need the Stop hook or `/audit-flush`; the auditor consumes entries, never produces them.

3. Maintain a separate output directory for audit reports:

   ```bash
   mkdir -p ~/audit/reports
   ```

## What the auditor does

- Reads `trails/YYYY/MM/*.md`, grouped by date or by `business_id`.
- Cross-references the `referenced_knowledge.commit` hashes by cloning the referenced knowledge repository *read-only* and checking out each hash as needed.
- Samples — not exhaustively reviews — entries. A full-coverage review is rarely the goal.
- Writes findings to `~/audit/reports/<date>-<scope>.md`, committed in its own repository.

## What the auditor does NOT do

- Does not rewrite or delete trail entries. Corrections enter the trail as new entries with `supersedes:` pointing at the mistaken one.
- Does not ask the work-side AI for clarification mid-audit. If context is missing, the trail entry is incomplete — that's a finding.
- Does not run `/audit-flush --force`. That would mean the auditor is closing the gap for the operator, which confuses responsibility.

## When to migrate to `/audit-review`

If this process stabilizes and repeats across multiple audit cycles, the repetitive parts (sampling, cross-referencing, finding templates) are candidates for a future `/audit-review` skill. Until then, operating by hand keeps the role boundary crisp.

## Independence check

Before each audit cycle, answer:

- Does the auditor's machine have any token that could write to the trail repository? If yes, revoke it before starting.
- Does the auditor share a Claude Code profile with the operator? If yes, switch to a separate profile so the skill set and knowledge base do not contaminate each other.
- Is the business catalog (what's in scope) reachable to the auditor without going through the operator? If no, that's a process gap to fix before auditing.

If any answer is uncomfortable, fix it before starting the audit — not during.
