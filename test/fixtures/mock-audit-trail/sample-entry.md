---
prompt: |
  Update the example-org/project-a deployment runbook to reflect the new
  rollback procedure that replaces the old kill-switch flag.
referenced_knowledge:
  - path: knowledge/ops/deployment-runbook.md
    commit: 4c1f0aa3b9d8e7f62c5b1da4b89e3f0c1d7a2e55
  - path: knowledge/ops/rollback-procedure.md
    commit: 8a2d3b7c9e4f1a5d6b8c0e9f2a7b4d1c3e5f0a88
output_summary: |
  Rewrote section 3 of the runbook. The kill-switch flag is removed. The
  new procedure uses the shared rollback script with the --stage flag.
  Two cross-references to the old flag in section 5 also updated. No
  other sections touched.
model:
  id: claude-opus-4-7
  timestamp: 2026-04-23T12:00:00+09:00
approval:
  who: alice
  method: stop_hook
tags: "#ops #runbook #deployment"
related_issue: example-org/project-a#142
risk_level: low
---

## Context

The rollback procedure was changed last sprint (example-org/project-a#138).
The runbook still referenced the deprecated kill-switch flag. Alice asked
to bring the runbook into alignment before the next release window.

## Actions

- Edited `runbooks/deploy.md` sections 3 and 5.
- Verified cross-references with `grep -n kill-switch runbooks/`.
- No other files changed.

## Evidence

- Commit: `a1b2c3d4e5f6` (branch: `docs/runbook-rollback-align`)
- Issue: example-org/project-a#142
- PR: example-org/project-a!87

## Notes

- Section 7 (metrics) mentions the old flag in an archived incident report.
  Intentionally not changed — historical record should not be rewritten.
- Next cycle: consider a runbook-lint check that catches references to
  deprecated flags automatically.
