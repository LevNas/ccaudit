# mock-audit-trail

A mock of what a fresh trail repository looks like after a single flush. Used for local smoke tests: point `CCAUDIT_TRAIL_REPO` at a clone of this fixture and run the hook to confirm the end-to-end flow works.

All content is fictional. No real organization, host, person, or token appears here.

## Layout

```
mock-audit-trail/
├── README.md            # this file
└── sample-entry.md      # one illustrative trail entry
```

In a real trail repository, entries live under `trails/YYYY/MM/`. The fixture shows a single entry at the top level for readability; a real operator would clone this as the initial repository and the hook would create `trails/YYYY/MM/` on first flush.

## How to use in a local smoke test

The automated way:

```bash
bash test/smoke-test.sh
```

`test/smoke-test.sh` wraps the steps below — it sets up a throwaway bare repo, runs the hook against a clean entry and a PEM-tainted entry, asserts the expected outcomes, and cleans up after itself.

The manual way (useful when debugging):

```bash
# Create a local bare repo to act as the remote
git init --bare /tmp/mock-trail.git

# Clone, seed with this fixture, push
git clone /tmp/mock-trail.git /tmp/mock-trail-work
cp test/fixtures/mock-audit-trail/README.md /tmp/mock-trail-work/
( cd /tmp/mock-trail-work && git add . && git commit -m "init" && git push )

# Point ccaudit at it
export CCAUDIT_TRAIL_REPO=/tmp/mock-trail.git
export CCAUDIT_STAGING_DIR=$(mktemp -d)
cp test/fixtures/mock-audit-trail/sample-entry.md "$CCAUDIT_STAGING_DIR/20260423-120000-smoke-test.md"

# Trigger the hook manually
bash hooks/auto-flush.sh
```

If the flow works, `/tmp/mock-trail.git` now contains a commit adding the entry under `trails/2026/04/`.
