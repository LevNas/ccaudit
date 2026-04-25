#!/usr/bin/env bash
# End-to-end smoke test for ccaudit's Stop hook.
#
# Verifies two paths:
#   1. A clean trail entry flushes through to the remote trail repo.
#   2. An entry containing a PEM private-key header is caught by the
#      secret scan and moved to the pending directory; nothing is pushed.
#
# Run with no arguments. Exits 0 on success, 1 on any assertion failure.
# Cleans up its temporary state on both success and failure.

set -euo pipefail

readonly REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
readonly REMOTE=/tmp/ccaudit-smoke-trail.git
readonly REMOTE_WORK=/tmp/ccaudit-smoke-trail-work
readonly STAGING_CLEAN=/tmp/ccaudit-smoke-staging-clean
readonly STAGING_PEM=/tmp/ccaudit-smoke-staging-pem
readonly PENDING_PEM=/tmp/ccaudit-smoke-pending-pem
readonly CACHE=/tmp/ccaudit-smoke-cache

cleanup() {
  rm -rf "$REMOTE" "$REMOTE_WORK" "$STAGING_CLEAN" "$STAGING_PEM" "$PENDING_PEM" "$CACHE"
}
trap cleanup EXIT
cleanup  # in case a previous run left state behind

fail() { printf 'FAIL: %s\n' "$*" >&2 ; exit 1 ; }
pass() { printf 'PASS: %s\n' "$*" ; }

# --- setup ---
git init --bare --initial-branch=main --quiet "$REMOTE"
git clone --quiet "$REMOTE" "$REMOTE_WORK"
cp "$REPO_ROOT/test/fixtures/mock-audit-trail/README.md" "$REMOTE_WORK/"
git -C "$REMOTE_WORK" \
    -c user.name=smoke -c user.email=smoke@example.org \
    add .
git -C "$REMOTE_WORK" \
    -c user.name=smoke -c user.email=smoke@example.org \
    commit --quiet -m "init"
git -C "$REMOTE_WORK" push --quiet origin main

export CCAUDIT_TRAIL_REPO="$REMOTE"
export XDG_CACHE_HOME="$CACHE"  # isolate hook's clone cache from the user's
export GIT_AUTHOR_NAME=smoke GIT_AUTHOR_EMAIL=smoke@example.org
export GIT_COMMITTER_NAME=smoke GIT_COMMITTER_EMAIL=smoke@example.org

# --- Test 1: clean entry should flush ---
mkdir "$STAGING_CLEAN"
cp "$REPO_ROOT/test/fixtures/mock-audit-trail/sample-entry.md" \
   "$STAGING_CLEAN/20260101-000000-clean.md"

CCAUDIT_STAGING_DIR="$STAGING_CLEAN" bash "$REPO_ROOT/hooks/auto-flush.sh" 2>/dev/null

[[ -z "$(ls -A "$STAGING_CLEAN")" ]] || fail "Test 1: staging not cleared after successful flush"
git -C "$REMOTE" log --oneline | grep -q 'audit-trail: add 1' \
  || fail "Test 1: trail repo did not receive the flush commit"
git -C "$REMOTE" ls-tree -r --name-only HEAD | grep -q '^trails/.*/20260101-000000-clean\.md$' \
  || fail "Test 1: trail repo does not contain the entry under trails/YYYY/MM/"
pass "Test 1: clean entry flushed end-to-end"

# --- Test 2: PEM-tainted entry should be blocked ---
mkdir "$STAGING_PEM"
cat > "$STAGING_PEM/20260101-000100-pem-tainted.md" <<'EOF'
---
prompt: test
referenced_knowledge: []
output_summary: pasted a key by accident
model:
  id: x
  timestamp: 2026-01-01T00:01:00+09:00
approval:
  who: alice
  method: stop_hook
---
oops:
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAA...
-----END OPENSSH PRIVATE KEY-----
EOF

CCAUDIT_STAGING_DIR="$STAGING_PEM" CCAUDIT_PENDING_DIR="$PENDING_PEM" \
  bash "$REPO_ROOT/hooks/auto-flush.sh" 2>/dev/null

[[ -z "$(ls -A "$STAGING_PEM")" ]] || fail "Test 2: staging not cleared after secret hit"
[[ -f "$PENDING_PEM/20260101-000100-pem-tainted.md" ]] \
  || fail "Test 2: tainted entry did not move to pending"
# Ensure the trail repo did NOT receive a second commit.
local_count=$(git -C "$REMOTE" log --oneline | wc -l)
[[ "$local_count" -eq 2 ]] \
  || fail "Test 2: trail repo received a commit it should not have (count=$local_count)"
pass "Test 2: PEM-tainted entry blocked, moved to pending, no remote write"

echo
echo "All smoke tests passed."
