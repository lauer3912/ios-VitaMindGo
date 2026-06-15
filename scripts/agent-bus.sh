#!/usr/bin/env bash
# agent-bus.sh v2 - OpenClaw Agent async IM via GitHub Issues
# v2 changes: AGENT_ID (unique per agent) + REGISTRY.md governance + 4 new subcommands
# v2.3 changes (2026-06-15):
#   - AGENT.md metadata (skills/capacity/last_seen) auto-detected + local
#   - watch subcommand: auto-track sent issues + silent upgrade alerts
#   - skill routing: `to-skill:<X>` resolves to first Active agent with that skill
#   - REGISTRY.md template adds Skills / Capacity / Last seen columns
#
# Source of truth: docs/agent-bus-architecture.md
# Training:        docs/agent-bus-training.md
# Version:         v2.3 (2026-06-15)

set -euo pipefail

# ============================================================
# CONFIG
# ============================================================
CONFIG_DIR="${AGENT_BUS_CONFIG_DIR:-$HOME/.config/agent-bus}"
CONFIG_FILE="$CONFIG_DIR/config"
AGENT_MD_FILE="${AGENT_BUS_AGENT_MD:-$CONFIG_DIR/AGENT.md}"
WATCH_DIR="${AGENT_BUS_WATCH_DIR:-$CONFIG_DIR/tracking}"
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
  gh auth status >/dev/null 2>&1 || die "gh not authenticated. Run: echo $YOUR_GITHUB_PAT | gh auth login --with-token  # $YOUR_GITHUB_PAT = 你的真实 GitHub PAT"
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
  REG_AGENT_META=""  # v2.3: "id|skills;id|skills;..." for Active agents
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
      # v2.3 REGISTRY Active table columns:
      #   1=empty, 2=AGENT_ID, 3=Persona, 4=Host, 5=Registered, 6=Status,
      #   7=Skills, 8=Capacity, 9=Last seen, 10=Notes
      local id persona host skills capacity last_seen
      id=$(echo "$line" | awk -F'|' '{gsub(/^ +| +$/,"",$2); print $2}')
      persona=$(echo "$line" | awk -F'|' '{gsub(/^ +| +$/,"",$3); print $3}')
      host=$(echo "$line" | awk -F'|' '{gsub(/^ +| +$/,"",$4); print $4}')
      skills=$(echo "$line" | awk -F'|' '{gsub(/^ +| +$/,"",$7); print $7}')
      capacity=$(echo "$line" | awk -F'|' '{gsub(/^ +| +$/,"",$8); print $8}')
      last_seen=$(echo "$line" | awk -F'|' '{gsub(/^ +| +$/,"",$9); print $9}')
      [[ -n "$id" ]] || continue
      # Skip placeholder rows like "(empty)" (defensive, in case REGISTRY.md hand-edited)
      [[ "$id" == "(empty)" ]] && continue
      # Validate ID format (defensive: must match AGENT_ID pattern)
      if ! [[ "$id" =~ ^[A-Za-z][A-Za-z0-9-]{0,31}-[A-Za-z0-9]{6}$ ]]; then
        warn "skip invalid ID in REGISTRY.md: '$id' (not AGENT_ID format)"
        continue
      fi
      case "$section" in
        active)
          REG_ACTIVE+="$id "
          # v2.3: also store meta for skill routing + who display
          REG_AGENT_META+="$id|$skills|$capacity|$last_seen"$'\n'
          ;;
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
  mkdir -p "$WATCH_DIR"

  # v2.3: idempotency — if config exists and --force not passed, refresh AGENT.md only
  local force=false
  for arg in "$@"; do [[ "$arg" == "--force" ]] && force=true; done

  if [[ -f "$CONFIG_FILE" && "$force" != "true" ]]; then
    log "config already exists: $CONFIG_FILE (use --force to regenerate AGENT_ID)"
    # shellcheck source=/dev/null
    source "$CONFIG_FILE"
    log "existing AGENT_ID: $AGENT_ID"
    # Refresh AGENT.md from existing config (in case skills/paths changed)
    local skills
    skills=$(detect_skills)
    local tz
    tz="${TZ:-$(date +%Z 2>/dev/null || echo UTC)}"
    cat > "$AGENT_MD_FILE" <<EOF
# AGENT.md for $AGENT_ID
# Auto-generated by agent-bus init (v2.3, idempotent refresh)
# Updated by agent-bus-poll.sh on every 5 min poll (last_seen only)

AGENT_ID:    $AGENT_ID
Persona:     $AGENT_PERSONA
Host:        $AGENT_HOST
Repo:        $REPO
Registered:  ${REGISTERED:-$(date -u +%Y-%m-%dT%H:%M:%SZ)}
Capacity:    idle          # idle | busy | free-for-task
Timezone:    $tz
Skills:      $skills       # auto-detected from ~/.openclaw/workspace/skills/
Last seen:   $(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF
    log "AGENT.md refreshed at $AGENT_MD_FILE"
    if [[ -n "$skills" ]]; then
      log "  skills detected: $skills"
    fi
    return 0
  fi

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
  rand6=$(LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 6 2>/dev/null) || rand6=$(printf '%s' "$RANDOM$RANDOM" | tr -dc 'A-Za-z0-9' | head -c 6)
  # Fallback if SIGPIPE (set -e + pipefail) kills the pipeline
  [[ ${#rand6} -lt 6 ]] && rand6=$(printf '%s%s%s' "$RANDOM" "$(date +%N)" "$AGENT_ID" 2>/dev/null | tr -dc 'A-Za-z0-9' | head -c 6)
  local id="${persona}-${rand6}"

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

  # ============================================================
  # v2.3: Write AGENT.md metadata (skills, capacity, last_seen)
  # ============================================================
  local skills
  skills=$(detect_skills)
  local tz
  tz="${TZ:-$(date +%Z 2>/dev/null || echo UTC)}"

  cat > "$AGENT_MD_FILE" <<EOF
# AGENT.md for $id
# Auto-generated by agent-bus init (v2.3)
# Updated by agent-bus-poll.sh on every 5 min poll (last_seen only)

AGENT_ID:    $id
Persona:     $persona
Host:        $host
Repo:        $repo
Registered:  $(date -u +%Y-%m-%dT%H:%M:%SZ)
Capacity:    idle          # idle | busy | free-for-task
Timezone:    $tz
Skills:      $skills       # auto-detected from ~/.openclaw/workspace/skills/
Last seen:   $(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF
  log "AGENT.md written to $AGENT_MD_FILE"
  if [[ -n "$skills" ]]; then
    log "  skills detected: $skills"
  else
    log "  (no skills detected — install skills to ~/.openclaw/workspace/skills/ or ~/.openclaw/skills/)"
  fi
  log ""
  log "Next steps:"
  log "  1. agent-bus test        # verify gh auth + repo access"
  log "  2. agent-bus register    # post registration request"
  log "  3. wait for 佛老爷 to approve + update REGISTRY.md"
  log "  4. agent-bus verify      # confirm verified"
  log ""
  log "佛老爷 approve 后, 请追加到 REGISTRY.md Active 表 (v2.3 格式, 例):"
  log "  | $id | $persona | $host | $(date +%Y-%m-%d) | active | $skills | idle | $(date -u +%Y-%m-%dT%H:%M:%SZ) | verified-by:佛老爷 |"
}

# ============================================================
# HELPER (v2.3): detect installed skills
# ============================================================
detect_skills() {
  local skills=()
  for d in \
    "$HOME/.openclaw/workspace/skills" \
    "$HOME/.openclaw/workspace/dist/openclaw-portable-template/skills" \
    "$HOME/.openclaw/skills" \
    "$HOME/.openclaw/plugin-skills"; do
    [[ -d "$d" ]] || continue
    while IFS= read -r skill_dir; do
      [[ -d "$skill_dir" ]] || continue
      local name
      name=$(basename "$skill_dir")
      [[ -f "$skill_dir/SKILL.md" ]] || continue
      # Skip hidden / system dirs
      [[ "$name" == .* || "$name" == _* ]] && continue
      # Skip if already in list
      for s in "${skills[@]:-}"; do [[ "$s" == "$name" ]] && continue 2; done
      skills+=("$name")
    done < <(find "$d" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)
  done
  # de-dup via sort -u
  if [[ ${#skills[@]} -gt 0 ]]; then
    printf '%s\n' "${skills[@]}" | sort -u | paste -sd ',' -
  fi
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
  # v2.3: also show AGENT.md metadata
  if [[ -f "$AGENT_MD_FILE" ]]; then
    echo ""
    echo "--- AGENT.md (v2.3 metadata) ---"
    grep -E "^(Capacity|Timezone|Skills|Last seen):" "$AGENT_MD_FILE" 2>/dev/null || echo "  (AGENT.md exists but no metadata lines)"
  else
    echo ""
    echo "(AGENT.md not found — run: agent-bus init to create)"
  fi
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
  echo "=== Active (v2.3: shows skills/capacity/last_seen from REGISTRY.md) ==="
  if [[ -n "$REG_ACTIVE" ]]; then
    while IFS='|' read -r id skills capacity last_seen; do
      [[ -z "$id" ]] && continue
      printf "  %-26s skills=%-20s capacity=%-10s last_seen=%s\n" \
        "$id" "${skills:-<unset>}" "${capacity:-<unset>}" "${last_seen:-<unset>}"
    done <<< "$REG_AGENT_META"
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
  # v2.3: Resolve to-skill:<skill> → first Active agent with that skill in REGISTRY.md
  if [[ "$to" =~ ^to-skill: ]]; then
    local skill="${to#to-skill:}"
    [[ -n "$skill" ]] || die "to-skill: requires a non-empty skill name (e.g. to-skill:ios-build)"
    local regfile
    regfile=$(fetch_registry) || die "REGISTRY.md not found (cannot resolve to-skill:)"
    local resolved
    resolved=$(awk -F'|' -v sk="$skill" '
      /^[[:space:]]*\|/ && !/AGENT_ID/ && !/^[[:space:]]*\|-/ {
        gsub(/^ +| +$/, "", $2); gsub(/^ +| +$/, "", $7);
        if (sk == "" || $7 == "" || $2 == "") next;
        n = split($7, arr, ",");
        for (i=1; i<=n; i++) {
          gsub(/^ +| +$/, "", arr[i]);
          if (arr[i] == sk) { print $2; exit }
        }
      }' "$regfile" 2>/dev/null) || true
    rm -f "$regfile"
    if [[ -z "$resolved" ]]; then
      # No match — list who has what skills for diagnosis
      local diag
      diag=$(gh api "repos/$REPO/contents/REGISTRY.md" --jq .content 2>/dev/null | base64 -d 2>/dev/null | \
        awk -F'|' '/^[[:space:]]*\|/ && !/AGENT_ID/ && !/^[[:space:]]*\|-/ {
          gsub(/^ +| +$/, "", $2); gsub(/^ +| +$/, "", $7);
          if ($2 != "" && $7 != "") print "  " $2 ": " $7
        }' 2>/dev/null) || true
      die "no Active agent has skill '$skill' in REGISTRY.md. Active agents + skills:"$'\n'"${diag:-  (REGISTRY.md not accessible)}"
    fi
    log "to-skill:$skill → $resolved (first match in REGISTRY.md)"
    to="$resolved"
  fi
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
# SUBCOMMAND: watch (NEW v2.3)
# ============================================================
# Auto-track sent issues + silent upgrade alerts.
# Files: $WATCH_DIR/<issue_num>.json
# Schema: {"issue_num":N, "to":"X", "sent_at":"ISO", "expected_first_reply_sec":600, "silent_alert_at_sec":1800}
# Read by: agent-bus-watch.sh (cron */3)
cmd_watch() {
  require_config
  mkdir -p "$WATCH_DIR"
  local subcmd="${1:-list}"
  shift || true
  case "$subcmd" in
    add)
      local num="${1:?issue num required}"; shift || true
      local to="${1:?to (recipient) required}"; shift || true
      [[ "$num" =~ ^[0-9]+$ ]] || die "issue num must be numeric"
      local expected="${1:-600}"; [[ $# -gt 0 ]] && shift
      local silent="${1:-1800}"
      local sent_at
      sent_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)
      # Resolve owner to GitHub login (for filtering self-comments in watch.sh)
      local gh_login
      gh_login=$(gh api user --jq .login 2>/dev/null || echo "unknown")
      cat > "$WATCH_DIR/$num.json" <<EOF
{"issue_num":$num, "to":"$to", "sent_at":"$sent_at", "expected_first_reply_sec":$expected, "silent_alert_at_sec":$silent, "owner":"$AGENT_ID", "owner_gh_login":"$gh_login"}
EOF
      log "watching issue #$num (to=$to, expected=${expected}s, silent_alert=${silent}s, owner=$AGENT_ID, gh_login=$gh_login)"
      log "  state file: $WATCH_DIR/$num.json"
      log "  check: agent-bus-watch.sh (cron */3) — upgrade alerts on silence"
      ;;
    stop)
      local num="${1:?issue num required}"; shift || true
      [[ -f "$WATCH_DIR/$num.json" ]] || die "not watching #$num"
      rm -f "$WATCH_DIR/$num.json"
      log "stopped watching #$num"
      ;;
    list|"")
      if [[ -z "$(ls -A "$WATCH_DIR" 2>/dev/null)" ]]; then
        echo "(no active watches)"
        return 0
      fi
      echo "=== Active watches ($AGENT_ID) ==="
      for f in "$WATCH_DIR"/*.json; do
        [[ -f "$f" ]] || continue
        # Parse JSON-lite with python (handles quoted strings with commas)
        python3 -c "
import json, sys
try:
    with open('$f') as fp: d = json.load(fp)
    print('  #%s  to=%-30s  sent=%s  expect<%ss  alert>%ss' % (
        d.get('issue_num','?'), d.get('to','?'), d.get('sent_at','?'),
        d.get('expected_first_reply_sec','?'), d.get('silent_alert_at_sec','?')))
except Exception as e:
    print('  ✗ corrupt state: $f (%s)' % e)
" 2>/dev/null || {
          # Fallback: crude awk (less robust for values containing commas/quotes)
          awk '
            /"issue_num"/ {match($0, /[0-9]+/); n=substr($0, RSTART, RLENGTH)}
            /"to"/ {match($0, /"to":"[^"]+"/); t=substr($0, RSTART+6, RLENGTH-7)}
            /"sent_at"/ {match($0, /"sent_at":"[^"]+"/); s=substr($0, RSTART+11, RLENGTH-12)}
            /"expected_first_reply_sec"/ {match($0, /[0-9]+/); e=substr($0, RSTART, RLENGTH)}
            /"silent_alert_at_sec"/ {match($0, /[0-9]+/); a=substr($0, RSTART, RLENGTH)}
            END {printf "  #%s  to=%s  sent=%s  expect<%s  alert>%s\n", n, t, s, e, a}
          ' "$f"
        }
      done
      ;;
    *)
      die "watch subcommand: add <num> <to> [expected_sec=600] [silent_alert_sec=1800] | list | stop <num>"
      ;;
  esac
}

# ============================================================
# DISPATCH
# ============================================================
cmd="${1:-help}"
shift || true
case "$cmd" in
  version|--version|-v) echo "agent-bus.sh v2.3 (2026-06-15)" ;;
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
  watch) cmd_watch "$@" ;;
  test) cmd_test "$@" ;;
  -h|--help|help)
    cat <<EOF
agent-bus.sh v2.3 - OpenClaw Agent async IM via GitHub Issues

Identity (v2):
  init                                One-time config (writes AGENT_ID + AGENT.md v2.3)
  id                                  Show my identity + AGENT.md metadata
  who                                 List all agents (active/pending/retired, +skills v2.3)
  register                            Post registration request
  verify                              Check if I'm in REGISTRY.md active

Communication:
  send FROM TO TYPE PRI PROJ TITLE    Send (--body required)
                                      TO: AGENT_ID | All | 佛老爷 | to-persona:X | to-skill:SKILL (v2.3)
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
  watch (NEW v2.3)                    Auto-track sent issues + silent upgrade alerts
       add N TO [expect_sec=600]      Start watching issue N → TO
                                      (default: warn at 10 min, alert at 30 min)
       stop N                         Stop watching N
       list                           List all active watches
  test                                Self-test (with REGISTRY.md verify)

Config:  $CONFIG_FILE
AGENT.md (v2.3): $AGENT_MD_FILE
Watch dir: $WATCH_DIR
Repo:     \$REPO (default: $DEFAULT_REPO)
EOF
    ;;
  *) die "unknown command: $cmd. Run: agent-bus --help" ;;
esac
