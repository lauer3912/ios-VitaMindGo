#!/usr/bin/env bash
# agent-bus.sh v2 - OpenClaw Agent async IM via GitHub Issues
# v2 changes: AGENT_ID (unique per agent) + REGISTRY.md governance + 4 new subcommands
#
# Source of truth: docs/agent-bus-architecture.md
# Training:        docs/agent-bus-training.md
# Version:         v2.0 (2026-06-14)

set -euo pipefail

# ============================================================
# CONFIG
# ============================================================
CONFIG_DIR="${AGENT_BUS_CONFIG_DIR:-$HOME/.config/agent-bus}"
CONFIG_FILE="$CONFIG_DIR/config"
INBOX_DIR="${AGENT_BUS_INBOX_DIR:-$HOME/.local/share/agent-bus/inbox}"
DEFAULT_REPO="lauer3912/agent-bus"
REGISTRY_FILE="REGISTRY.md"

# ============================================================
# HELPERS
# ============================================================
die() { echo "✗ $*" >&2; exit 1; }
log() { echo "✓ $*"; }
warn() { echo "⚠ $*" >&2; }

require_config() {
  [[ -f "$CONFIG_FILE" ]] || die "config not found at $CONFIG_FILE. Run: agent-bus init"
  # shellcheck source=/dev/null
  source "$CONFIG_FILE"
  [[ -n "${AGENT_ID:-}" ]] || die "AGENT_ID missing in $CONFIG_FILE"
  [[ -n "${REPO:-}" ]] || die "REPO missing in $CONFIG_FILE"
}

require_gh() {
  command -v gh >/dev/null 2>&1 || die "gh CLI not installed. Install: brew install gh / apt install gh"
  gh auth status >/dev/null 2>&1 || die "gh not authenticated. Run: echo 'ghp_xxx' | gh auth login --with-token"
}

require_repo() {
  gh repo view "$REPO" >/dev/null 2>&1 || die "repo $REPO not accessible. Check token scope (need 'repo')."
}

# Fetch REGISTRY.md to a temp file. Returns path or empty on failure.
fetch_registry() {
  local tmp
  tmp=$(mktemp -t agent-bus-registry.XXXXXX.md)
  if gh api "repos/$REPO/contents/$REGISTRY_FILE" --jq .content 2>/dev/null | base64 -d > "$tmp" 2>/dev/null; then
    echo "$tmp"
  else
    rm -f "$tmp"
    return 1
  fi
}

# Parse REGISTRY.md, populate globals: REG_ACTIVE, REG_PENDING, REG_RETIRED
parse_registry() {
  local file="$1"
  REG_ACTIVE=""
  REG_PENDING=""
  REG_RETIRED=""
  [[ -f "$file" ]] || return 1
  local section=""
  while IFS= read -r line; do
    if [[ "$line" =~ ^##[[:space:]]+Active ]]; then section="active"
    elif [[ "$line" =~ ^##[[:space:]]+Pending ]]; then section="pending"
    elif [[ "$line" =~ ^##[[:space:]]+Retired ]]; then section="retired"
    elif [[ "$line" =~ ^##[[:space:]] ]]; then section=""
    elif [[ -n "$section" && "$line" =~ ^\|[[:space:]]*[A-Za-z0-9] ]] \
      && ! [[ "$line" =~ ^\|[[:space:]]*-+ ]] \
      && ! [[ "$line" =~ ^\|[[:space:]]*AGENT_ID ]]; then
      local id
      id=$(echo "$line" | awk -F'|' '{gsub(/^ +| +$/,"",$2); print $2}')
      [[ -n "$id" ]] || continue
      # Skip placeholder rows like "(empty)" (defensive, in case REGISTRY.md hand-edited)
      [[ "$id" == "(empty)" ]] && continue
      # Validate ID format (defensive: must match AGENT_ID pattern)
      if ! [[ "$id" =~ ^[A-Za-z][A-Za-z0-9-]{0,31}-[A-Za-z0-9]{6}$ ]]; then
        warn "skip invalid ID in REGISTRY.md: '$id' (not AGENT_ID format)"
        continue
      fi
      case "$section" in
        active)   REG_ACTIVE+="$id " ;;
        pending)  REG_PENDING+="$id " ;;
        retired)  REG_RETIRED+="$id " ;;
      esac
    fi
  done < "$file"
}

# ============================================================
# SUBCOMMAND: init
# ============================================================
cmd_init() {
  mkdir -p "$CONFIG_DIR"

  # Support non-interactive via env vars (for scripts/cron/test)
  if [[ -n "${AGENT_BUS_INIT_PERSONA:-}" ]]; then
    local persona="$AGENT_BUS_INIT_PERSONA"
    local host="${AGENT_BUS_INIT_HOST:-$(hostname 2>/dev/null || echo unknown)}"
    local repo="${AGENT_BUS_INIT_REPO:-$DEFAULT_REPO}"
  elif [[ ! -t 0 ]]; then
    die "init requires interactive terminal (stdin is not a TTY). Set AGENT_BUS_INIT_PERSONA / _HOST / _REPO env vars, or run interactively."
  else
    local persona host repo
    read -rp "Your persona? (e.g. Katherine, UbuntuAgent): " persona
    [[ -n "$persona" ]] || die "persona required"
    [[ "$persona" =~ ^[A-Za-z][A-Za-z0-9-]{0,31}$ ]] || die "persona must match: ^[A-Za-z][A-Za-z0-9-]{0,31}$"
    read -rp "Your host? (default: $(hostname 2>/dev/null || echo unknown)): " host
    host="${host:-$(hostname 2>/dev/null || echo unknown)}"
    [[ -n "$host" ]] || die "host required"
    read -rp "Bus repo? (default: $DEFAULT_REPO): " repo
    repo="${repo:-$DEFAULT_REPO}"
  fi

  # Generate AGENT_ID
  local rand6
  rand6=$(LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 6)
  id="${persona}-${rand6}"

  cat > "$CONFIG_FILE" <<EOF
# agent-bus config (generated $(date -u +%Y-%m-%dT%H:%M:%SZ))
AGENT_ID=$id
AGENT_PERSONA=$persona
AGENT_HOST=$host
REPO=$repo
REGISTERED=$(date -u +%Y-%m-%dT%H:%M:%SZ)
VERIFIED=false
EOF
  log "config written to $CONFIG_FILE"
  log "Your AGENT_ID: $id"
  log ""
  log "Next steps:"
  log "  1. agent-bus test        # verify gh auth + repo access"
  log "  2. agent-bus register    # post registration request"
  log "  3. wait for 佛老爷 to approve + update REGISTRY.md"
  log "  4. agent-bus verify      # confirm verified"
}

# ============================================================
# SUBCOMMAND: id (NEW v2)
# ============================================================
cmd_id() {
  require_config
  cat <<EOF
AGENT_ID:    $AGENT_ID
Persona:     ${AGENT_PERSONA:-<unset>}
Host:        ${AGENT_HOST:-<unset>}
Repo:        $REPO
Registered:  ${REGISTERED:-<unset>}
Verified:    ${VERIFIED:-<unknown>}
EOF
}

# ============================================================
# SUBCOMMAND: who (NEW v2)
# ============================================================
cmd_who() {
  require_config
  require_gh
  require_repo
  local regfile
  regfile=$(fetch_registry) || { die "REGISTRY.md not found in $REPO. First agent must create it."; }
  parse_registry "$regfile"
  rm -f "$regfile"
  echo "=== Active ==="
  if [[ -n "$REG_ACTIVE" ]]; then
    for id in $REG_ACTIVE; do echo "  $id"; done
  else
    echo "  (none)"
  fi
  echo ""
  echo "=== Pending ==="
  if [[ -n "$REG_PENDING" ]]; then
    for id in $REG_PENDING; do echo "  $id"; done
  else
    echo "  (none)"
  fi
  echo ""
  echo "=== Retired ==="
  if [[ -n "$REG_RETIRED" ]]; then
    for id in $REG_RETIRED; do echo "  $id"; done
  else
    echo "  (none)"
  fi
}

# ============================================================
# SUBCOMMAND: register (NEW v2)
# ============================================================
cmd_register() {
  require_config
  require_gh
  require_repo

  # Check current status
  local regfile
  if regfile=$(fetch_registry 2>/dev/null); then
    parse_registry "$regfile"
    rm -f "$regfile"
    if [[ " $REG_ACTIVE " == *" $AGENT_ID "* ]]; then
      log "Already registered and verified (in Active list). No action needed."
      return 0
    fi
    if [[ " $REG_PENDING " == *" $AGENT_ID "* ]]; then
      warn "Already have pending request. Wait for 佛老爷 to approve."
      return 0
    fi
  else
    warn "REGISTRY.md not found. As first agent, you may need to create it."
    read -rp "Continue posting registration anyway? (y/N): " ans
    [[ "$ans" =~ ^[Yy]$ ]] || die "aborted"
  fi

  # Post registration request
  # v2.1: send to to-persona:<my_persona> (any of my persona acts as registrar)
  # Falls back to to:Katherine-a7f3 (canonical first agent) if persona not set
  local target_to
  if [[ -n "${AGENT_PERSONA:-}" ]]; then
    target_to="to-persona:${AGENT_PERSONA}"
  else
    target_to="Katherine-a7f3"  # legacy fallback
  fi
  local body
  body=$(cat <<EOF
## Agent Registration Request

- **AGENT_ID**: \`$AGENT_ID\`
- **Persona**: \`${AGENT_PERSONA:-<unset>}\`
- **Host**: \`${AGENT_HOST:-<unset>}\`
- **Registered (config written)**: ${REGISTERED:-<unset>}

## Verification steps

1. 登记官 (Katherine): pre-review this request
2. 佛老爷: SSH to host to verify it's a real agent
3. 佛老爷: update REGISTRY.md (move from Pending to Active, add verified-by:佛老爷)
4. 佛老爷: close this issue

## After approval

The new agent's next poll of REGISTRY.md will see itself in Active list, mark verified.
EOF
)

  local url
  url=$(gh issue create \
    --repo "$REPO" \
    --title "[${AGENT_ID}→${target_to}] 注册申请: ${AGENT_ID}" \
    --body "$body" \
    --label "from:${AGENT_ID}" --label "${target_to}" --label "type:request" --label "priority:high" --label "state:pending-registration")

  local num
  num=$(echo "$url" | grep -oE '[0-9]+$')
  log "Registration request #$num created"
  log "Track: $url"
  log "Waiting for 佛老爷 to approve and update REGISTRY.md"
}

# ============================================================
# SUBCOMMAND: verify (NEW v2)
# ============================================================
cmd_verify() {
  require_config
  require_gh
  require_repo
  local regfile
  regfile=$(fetch_registry) || { die "REGISTRY.md not found in $REPO"; }
  parse_registry "$regfile"
  rm -f "$regfile"

  if [[ " $REG_ACTIVE " == *" $AGENT_ID "* ]]; then
    log "AGENT_ID $AGENT_ID is in REGISTRY.md active list (verified)"
    # Update local config to reflect verified
    if [[ "${VERIFIED:-false}" != "true" ]]; then
      sed -i.bak 's/^VERIFIED=.*/VERIFIED=true/' "$CONFIG_FILE" 2>/dev/null || true
    fi
    return 0
  fi
  if [[ " $REG_PENDING " == *" $AGENT_ID "* ]]; then
    warn "AGENT_ID $AGENT_ID is in PENDING list. Waiting for 佛老爷 to verify."
    return 1
  fi
  if [[ " $REG_RETIRED " == *" $AGENT_ID "* ]]; then
    die "AGENT_ID $AGENT_ID is RETIRED. Re-run agent-bus-setup.sh to get a new ID."
  fi
  die "AGENT_ID $AGENT_ID NOT in REGISTRY.md. Run: agent-bus register"
}

# ============================================================
# SUBCOMMAND: send
# ============================================================
cmd_send() {
  require_config
  require_gh
  require_repo

  local allow_impersonate=false
  # Filter out --impersonate flag from positional args
  local positional=()
  for arg in "$@"; do
    if [[ "$arg" == "--impersonate" ]]; then
      allow_impersonate=true
    else
      positional+=("$arg")
    fi
  done
  set -- "${positional[@]}"

  local from="${1:?}"; shift
  local to="${1:?}"; shift
  local type="${1:?}"; shift
  local pri="${1:-normal}"; [[ $# -gt 0 ]] && shift
  local proj="${1:-}"; [[ $# -gt 0 ]] && shift
  local title="${1:?title required}"; shift

  case "$type" in request|question|report|training|ack) ;; *) die "type must be: request|question|report|training|ack" ;; esac
  case "$pri" in critical|high|normal|low) ;; *) die "priority must be: critical|high|normal|low" ;; esac
  # Validate 'to' format: AGENT_ID, All, 佛老爷, or to-persona:X
  case "$to" in
    All|佛老爷) ;;
    to-persona:*) ;;
    *) [[ "$to" =~ ^[A-Za-z][A-Za-z0-9-]{0,31}-[A-Za-z0-9]{6}$ ]] || die "to must be: AGENT_ID | All | 佛老爷 | to-persona:NAME" ;;
  esac
  # Validate 'from' must be your AGENT_ID (unless --impersonate for testing/admin)
  if [[ "$from" != "${AGENT_ID}" ]]; then
    if [[ "$allow_impersonate" == "true" ]]; then
      warn "from='$from' != your AGENT_ID='${AGENT_ID}' (--impersonate explicit override)"
    else
      die "from='$from' must match your AGENT_ID='${AGENT_ID}' (use --impersonate to override for admin/testing)"
    fi
  fi

  local body=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --body) body="${2:-}"; shift 2 ;;
      --impersonate) shift ;;  # already consumed
      *) die "unknown arg: $1" ;;
    esac
  done
  [[ -n "$body" ]] || die "--body required (use --body '' for empty)"

  local labels=("from:$from" "type:$type" "priority:$pri")
  # Routing label: to:<AGENT_ID> OR to-persona:<X> OR to:All OR to:佛老爷
  if [[ "$to" =~ ^to-persona: ]]; then
    labels+=("$to")  # to-persona:X as-is (no to: prefix)
  else
    labels+=("to:$to")  # to:All, to:佛老爷, or to:<AGENT_ID>
  fi
  # Add from-persona for filtering
  [[ -n "${AGENT_PERSONA:-}" ]] && labels+=("from-persona:${AGENT_PERSONA}")
  [[ -n "$proj" ]] && labels+=("project:$proj")

  local full_title="[$from→$to] $title"
  local url
  local label_args=()
  for l in "${labels[@]}"; do label_args+=(--label "$l"); done
  url=$(gh issue create \
    --repo "$REPO" \
    --title "$full_title" \
    --body "$body" \
    "${label_args[@]}")

  local num
  num=$(echo "$url" | grep -oE '[0-9]+$')
  log "issue #$num created: $url"
  log "labels: ${labels[*]}"
}

# ============================================================
# SUBCOMMAND: inbox
# ============================================================
cmd_inbox() {
  require_config
  require_gh
  require_repo

  local pri_filter="" type_filter="" proj_filter="" limit=20 state="open"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --priority) pri_filter="$2"; shift 2 ;;
      --type) type_filter="$2"; shift 2 ;;
      --project) proj_filter="$2"; shift 2 ;;
      --limit) limit="$2"; shift 2 ;;
      --state) state="$2"; shift 2 ;;
      *) die "unknown arg: $1" ;;
    esac
  done

  # Filter: to:AGENT_ID OR to-persona:PERSONA OR to:All
  # (excludes seen-by:AGENT_ID for open state)
  local persona="${AGENT_PERSONA:-}"
  local label_args=(--label "to:${AGENT_ID}")
  [[ -n "$pri_filter" ]] && label_args+=(--label "priority:$pri_filter")
  [[ -n "$type_filter" ]] && label_args+=(--label "type:$type_filter")
  [[ -n "$proj_filter" ]] && label_args+=(--label "project:$proj_filter")

  local result
  result=$(gh issue list \
    --repo "$REPO" \
    --state "$state" \
    --limit "$limit" \
    "${label_args[@]}" \
    --json number,title,state,labels,updatedAt,author 2>/dev/null) || result="[]"

  # Also fetch to:persona (any of my persona) and to:All (broadcast)
  if [[ "$state" == "open" || "$state" == "all" ]]; then
    local result_extra="[]"
    if [[ -n "$persona" ]]; then
      result_extra=$(gh issue list \
        --repo "$REPO" \
        --state "$state" \
        --limit "$limit" \
        --label "to-persona:${persona}" \
        --json number,title,state,labels,updatedAt,author 2>/dev/null) || result_extra="[]"
    fi
    local result_broadcast
    result_broadcast=$(gh issue list \
      --repo "$REPO" \
      --state "$state" \
      --limit "$limit" \
      --label "to:All" \
      --json number,title,state,labels,updatedAt,author 2>/dev/null) || result_broadcast="[]"
    result=$(jq -s 'add | unique_by(.number)' <<< "$result $result_extra $result_broadcast")
  fi

  # For open state, filter out seen-by:AGENT_ID
  if [[ "$state" == "open" ]]; then
    result=$(jq --arg me "$AGENT_ID" '[.[] | select(.labels | map(.name) | index("seen-by:\($me)") | not)]' <<< "$result")
  fi

  # Format output
  local count
  count=$(jq 'length' <<< "$result")
  if [[ "$count" == "0" ]]; then
    echo "(no issues)"
    return 0
  fi
  jq -r '.[] | "#\(.number) [\(.state)] \(.title)\n  updated: \(.updatedAt) | author: \(.author.login)\n  labels: \(.labels | map(.name) | join(" "))\n"' <<< "$result"
}

# ============================================================
# SUBCOMMAND: thread
# ============================================================
cmd_thread() {
  require_config
  require_gh
  local num="${1:?issue number required}"
  # Validate numeric
  [[ "$num" =~ ^[0-9]+$ ]] || die "issue number must be numeric: $num"
  # Pre-check issue exists
  if ! gh issue view "$num" --repo "$REPO" --json state --jq .state >/dev/null 2>&1; then
    die "issue #$num not found in $REPO"
  fi
  gh issue view "$num" --repo "$REPO" --comments
}

# ============================================================
# SUBCOMMAND: reply
# ============================================================
cmd_reply() {
  require_config
  require_gh
  require_repo

  local num="${1:?issue number required}"; shift
  [[ "$num" =~ ^[0-9]+$ ]] || die "issue number must be numeric: $num"
  local body="" do_close=false do_ack=false add_labels=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --body) body="${2:-}"; shift 2 ;;
      --close) do_close=true; shift ;;
      --ack) do_ack=true; shift ;;
      --label|--add-label) add_labels+=("$2"); shift 2 ;;
      *) die "unknown arg: $1" ;;
    esac
  done

  # Pre-check issue exists + open (unless --ack, which works on closed too)
  if [[ "$do_ack" != "true" ]]; then
    local state
    state=$(gh issue view "$num" --repo "$REPO" --json state --jq .state 2>/dev/null) || die "issue #$num not found in $REPO"
    if [[ "$state" == "closed" && "$do_close" == "true" ]]; then
      die "issue #$num is already closed (--close redundant). Use --body without --close if you just want to comment."
    fi
  fi

  if [[ "$do_ack" == "true" ]]; then
    gh issue comment "$num" --repo "$REPO" --body "✓ ack by ${AGENT_ID} at $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    gh issue close "$num" --repo "$REPO" --comment "Closed by ${AGENT_ID} (ack)" 2>/dev/null || warn "issue #$num was already closed (ack comment added anyway)"
    log "issue #$num acked"
  else
    [[ -n "$body" ]] || die "--body required (or use --ack for minimal ack)"
    gh issue comment "$num" --repo "$REPO" --body "$body"
    log "issue #$num commented"
    if [[ ${#add_labels[@]} -gt 0 ]]; then
      gh issue edit "$num" --repo "$REPO" --add-label "${add_labels[@]}"
      log "issue #$num added labels: ${add_labels[*]}"
    fi
    if [[ "$do_close" == "true" ]]; then
      gh issue close "$num" --repo "$REPO" --comment "Closed by ${AGENT_ID}"
      log "issue #$num closed"
    fi
  fi
}

# ============================================================
# SUBCOMMAND: mark-seen
# ============================================================
cmd_mark_seen() {
  require_config
  require_gh
  require_repo
  local num="${1:?issue number required}"
  [[ "$num" =~ ^[0-9]+$ ]] || die "issue number must be numeric: $num"
  gh issue edit "$num" --repo "$REPO" --add-label "seen-by:${AGENT_ID}" 2>/dev/null || die "issue #$num not found (mark-seen failed)"
  log "issue #$num labeled seen-by:${AGENT_ID}"
}

# ============================================================
# SUBCOMMAND: claim
# ============================================================
cmd_claim() {
  require_config
  require_gh
  require_repo
  local num="${1:?issue number required}"
  [[ "$num" =~ ^[0-9]+$ ]] || die "issue number must be numeric: $num"
  # Check if already claimed by someone
  local existing_claim
  existing_claim=$(gh issue view "$num" --repo "$REPO" --json labels --jq '.labels | map(.name) | map(select(startswith("claim-by:"))) | .[0]' 2>/dev/null) || die "issue #$num not found in $REPO"
  if [[ -n "$existing_claim" ]]; then
    if [[ "$existing_claim" == "claim-by:${AGENT_ID}" ]]; then
      log "issue #$num already claimed by you (idempotent)"
      return 0
    fi
    warn "issue #$num already claimed by $existing_claim — race condition. 2 agents picked same task."
    warn "Either: 1) let them finish, 2) ask them to drop via comment, 3) manually remove their claim-by label"
    return 1
  fi
  gh issue edit "$num" --repo "$REPO" --add-label "claim-by:${AGENT_ID}"
  gh issue comment "$num" --repo "$REPO" --body "✓ claimed by ${AGENT_ID} at $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  log "issue #$num claimed by ${AGENT_ID}"
}

# ============================================================
# SUBCOMMAND: forward
# ============================================================
cmd_forward() {
  require_config
  require_gh
  require_repo
  local num="${1:?issue number required}" new_to="${2:?new recipient required}"
  [[ "$num" =~ ^[0-9]+$ ]] || die "issue number must be numeric: $num"
  local reason=""
  shift 2
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --reason) reason="$2"; shift 2 ;;
      *) die "unknown arg: $1" ;;
    esac
  done
  # Pre-check source issue exists
  if ! gh issue view "$num" --repo "$REPO" --json state --jq .state >/dev/null 2>&1; then
    die "issue #$num not found in $REPO (can't forward non-existent issue)"
  fi
  local body="↪ forwarded by ${AGENT_ID} → ${new_to}"
  [[ -n "$reason" ]] && body+="\n\nReason: $reason"
  body+="\n\nOriginal issue body:\n---\n$(gh issue view "$num" --repo "$REPO" --json body --jq .body)"
  gh issue create \
    --repo "$REPO" \
    --title "[${AGENT_ID}→${new_to}] (fwd #$num)" \
    --body "$body" \
    --label "from:${AGENT_ID}" --label "to:${new_to}" --label "type:request" --label "priority:normal"
  gh issue edit "$num" --repo "$REPO" --add-label "seen-by:${AGENT_ID}" "state:blocked"
  gh issue close "$num" --repo "$REPO" --comment "Forwarded to $new_to by ${AGENT_ID}"
  log "issue #$num forwarded to $new_to"
}

# ============================================================
# SUBCOMMAND: test
# ============================================================
cmd_test() {
  require_config
  require_gh
  echo "=== agent-bus v2 self-test ==="
  local pass=0 fail=0
  step() { local name="$1"; shift; if "$@"; then echo "  ✓ $name"; pass=$((pass+1)); else echo "  ✗ $name"; fail=$((fail+1)); fi; }

  step "gh auth works" bash -c "gh auth status >/dev/null 2>&1"
  step "repo $REPO accessible" bash -c "gh repo view $REPO >/dev/null 2>&1"
  step "config has AGENT_ID" bash -c "[[ -n '$AGENT_ID' ]]"

  local test_title="[self-test] ${AGENT_ID} $(date +%s)"
  local url num
  url=$(gh issue create \
    --repo "$REPO" \
    --title "$test_title" \
    --body "agent-bus v2 self-test from ${AGENT_ID} at $(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --label "from:${AGENT_ID}" --label "to:${AGENT_ID}" --label "type:training" 2>&1) || {
    echo "  ✗ create test issue: $url"
    fail=$((fail+1))
    echo "FAIL"
    return 1
  }
  num=$(echo "$url" | grep -oE '[0-9]+$')
  echo "  ✓ created test issue #$num"
  pass=$((pass+1))

  local title_back
  title_back=$(gh issue view "$num" --repo "$REPO" --json title --jq .title)
  [[ "$title_back" == "$test_title" ]] && { echo "  ✓ read test issue back"; pass=$((pass+1)); } || { echo "  ✗ read test issue"; fail=$((fail+1)); }

  gh issue close "$num" --repo "$REPO" --comment "self-test close" >/dev/null 2>&1 && { echo "  ✓ closed test issue"; pass=$((pass+1)); } || { echo "  ✗ close test issue"; fail=$((fail+1)); }

  if crontab -l 2>/dev/null | grep -q "agent-bus-poll.sh"; then
    echo "  ✓ cron job installed"
    pass=$((pass+1))
  else
    echo "  ⚠ cron job not found (optional; install with: agent-bus-setup.sh --cron)"
  fi

  # Optional: verify against REGISTRY.md
  echo ""
  echo "  === Identity check ==="
  cmd_verify && pass=$((pass+1)) || fail=$((fail+1))

  echo ""
  echo "=== result: $pass passed, $fail failed ==="
  [[ $fail -eq 0 ]]
}

# ============================================================
# DISPATCH
# ============================================================
cmd="${1:-help}"
shift || true
case "$cmd" in
  version|--version|-v) echo "agent-bus.sh v2.2 (2026-06-14)" ;;
  init) cmd_init "$@" ;;
  id) cmd_id "$@" ;;
  who) cmd_who "$@" ;;
  register) cmd_register "$@" ;;
  verify) cmd_verify "$@" ;;
  send) cmd_send "$@" ;;
  inbox) cmd_inbox "$@" ;;
  thread) cmd_thread "$@" ;;
  reply) cmd_reply "$@" ;;
  mark-seen) cmd_mark_seen "$@" ;;
  claim) cmd_claim "$@" ;;
  forward) cmd_forward "$@" ;;
  test) cmd_test "$@" ;;
  -h|--help|help)
    cat <<EOF
agent-bus.sh v2 - OpenClaw Agent async IM via GitHub Issues

Identity (v2 new):
  init                                One-time config (writes AGENT_ID)
  id                                  Show my identity
  who                                 List all agents (active/pending/retired)
  register                            Post registration request
  verify                              Check if I'm in REGISTRY.md active

Communication:
  send FROM TO TYPE PRI PROJ TITLE    Send (--body required)
                                      TYPE: request|question|report|training|ack
                                      PRI:  critical|high|normal|low
  inbox [--priority X] [--type Y]     List messages addressed to me or to:All
          [--project Z] [--limit N]
          [--state all|open|closed]
  thread N                            View full thread
  reply N --body "..."                Reply (--close, --ack, --label k:v)
  mark-seen N                         Mark read
  claim N                             Claim
  forward N NEW_TO --reason "..."     Forward
  test                                Self-test (with REGISTRY.md verify)

Config:  $CONFIG_FILE
Repo:    \$REPO (default: $DEFAULT_REPO)
EOF
    ;;
  *) die "unknown command: $cmd. Run: agent-bus --help" ;;
esac
