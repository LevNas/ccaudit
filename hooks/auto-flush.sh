#!/usr/bin/env bash
# Stop hook: auto-flush staged audit trail entries to the remote trail repository.
# Exits 0 in all cases so it never blocks session end. Emits status to stderr.

set -euo pipefail

: "${CCAUDIT_STAGING_DIR:=./audit-trail-staging}"
: "${CCAUDIT_PENDING_DIR:=./audit-trail-pending}"
: "${CCAUDIT_TRAIL_REPO:=}"
: "${CCAUDIT_SIGN:=0}"
: "${CCAUDIT_MANUAL:=0}"
: "${CCAUDIT_HOOK_DISABLE:=0}"
: "${CCAUDIT_PRE_FLUSH_HOOK:=}"

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/ccaudit/trail-repo"

[[ "$CCAUDIT_HOOK_DISABLE" == "1" ]] && exit 0
[[ "$CCAUDIT_MANUAL" == "1" ]] && exit 0
[[ -d "$CCAUDIT_STAGING_DIR" ]] || exit 0

mapfile -t STAGED < <(find "$CCAUDIT_STAGING_DIR" -maxdepth 1 -type f -name '*.md' 2>/dev/null || true)
(( ${#STAGED[@]} == 0 )) && exit 0

notify() { printf 'ccaudit: %s\n' "$*" >&2 ; }

move_to_pending() {
  mkdir -p "$CCAUDIT_PENDING_DIR"
  for f in "${STAGED[@]}"; do mv "$f" "$CCAUDIT_PENDING_DIR/" ; done
}

scan_secrets() {
  # Generic patterns shipped with the plugin. Environment-specific patterns
  # belong in CCAUDIT_PRE_FLUSH_HOOK, not here — this list must stay vendor-
  # neutral so the plugin remains safe to ship publicly.
  # Returns 0 = clean, 1 = at least one match.
  # See docs/secret-patterns.md for the rationale and example data of each line.
  local patterns=(
    'ghp_[A-Za-z0-9]{36}'                       # GitHub PAT (classic)
    'glpat-[A-Za-z0-9_-]{20}'                   # GitLab PAT
    'AKIA[A-Z0-9]{16}|ASIA[A-Z0-9]{16}'         # AWS Access Key ID (permanent / STS)
    'sk-[A-Za-z0-9]{48}'                        # OpenAI API key (classic)
    'sk-proj-[A-Za-z0-9_-]{40,}'                # OpenAI API key (project, 2024+)
    '-----BEGIN [A-Z ]*PRIVATE KEY-----'        # PEM private key header (any variant)
    'github_pat_[A-Za-z0-9_]{82}'               # GitHub PAT (fine-grained, 2022+)
    'eyJ[A-Za-z0-9_-]{10,}\.eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}'  # JWT (signed)
    # All initial-roadmap categories covered. Open items below are deferred
    # pending authoritative format confirmation; layer them on top via
    # CCAUDIT_PRE_FLUSH_HOOK if you need coverage today.
    #   - OpenAI service account / admin keys (sk-svcacct-, sk-admin-)
    #   - Cloud provider keys (GCP service account, Azure SAS, etc.)
    # Use extended regex syntax (grep -E). Keep patterns conservative to avoid
    # false positives on quoted example strings. Do NOT include any company-
    # specific tokens, hostnames, or URLs. Update docs/secret-patterns.md in
    # the same change so the rationale stays in lockstep with the code.
  )
  if (( ${#patterns[@]} == 0 )); then
    notify 'WARNING: secret-pattern list is empty; scan skipped (see hooks/auto-flush.sh TODO)'
    return 0
  fi
  for p in "${patterns[@]}"; do
    # `-e "$p"` protects patterns whose first char is `-` (e.g. PEM headers
    # that start with -----BEGIN). `-- "${STAGED[@]}"` protects filenames
    # that might start with `-`. Without both, grep silently treats the
    # pattern as an unknown flag and returns exit 2, which the surrounding
    # `if` evaluates as no-match — a false negative.
    if grep -E -q -e "$p" -- "${STAGED[@]}"; then
      notify "secret pattern matched: $p"
      return 1
    fi
  done
  return 0
}

if ! scan_secrets; then
  notify "moved ${#STAGED[@]} staged entries to $CCAUDIT_PENDING_DIR (secret hit)"
  move_to_pending
  exit 0
fi

if [[ -n "$CCAUDIT_PRE_FLUSH_HOOK" ]]; then
  if ! "$CCAUDIT_PRE_FLUSH_HOOK" "${STAGED[@]}"; then
    notify 'pre-flush hook rejected flush'
    move_to_pending
    exit 0
  fi
fi

if [[ -z "$CCAUDIT_TRAIL_REPO" ]]; then
  notify "CCAUDIT_TRAIL_REPO is unset; ${#STAGED[@]} entries left in staging"
  exit 0
fi

mkdir -p "$(dirname "$CACHE_DIR")"
if [[ ! -d "$CACHE_DIR/.git" ]]; then
  rm -rf "$CACHE_DIR"
  if ! git clone --quiet "$CCAUDIT_TRAIL_REPO" "$CACHE_DIR" 2>/dev/null; then
    notify "clone of trail repo failed; ${#STAGED[@]} entries left in staging"
    exit 0
  fi
fi

if ! ( cd "$CACHE_DIR" && git fetch --quiet origin && git reset --hard --quiet origin/HEAD ); then
  notify "fetch/reset failed; ${#STAGED[@]} entries left in staging"
  exit 0
fi

YM=$(date +%Y/%m)
DEST="$CACHE_DIR/trails/$YM"
mkdir -p "$DEST"
for f in "${STAGED[@]}"; do cp "$f" "$DEST/" ; done

COMMIT_ARGS=(-m "audit-trail: add ${#STAGED[@]} entries from $(hostname -s) at $(date -Iseconds)")
[[ "$CCAUDIT_SIGN" == "1" ]] && COMMIT_ARGS+=(-S)

if ! ( cd "$CACHE_DIR" && git add -A && git commit --quiet "${COMMIT_ARGS[@]}" && git push --quiet origin HEAD ); then
  notify 'push failed; moving to pending'
  move_to_pending
  exit 0
fi

rm -f "${STAGED[@]}"
notify "flushed ${#STAGED[@]} entries to remote trail repository"
exit 0
