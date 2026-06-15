#!/usr/bin/env bash
# agent-bus-setup.sh v2.3 - One-time setup for agent-bus
# - Verifies prereqs
# - Generates AGENT_ID (persona + rand6)
# - Writes config + AGENT.md (v2.3) + backup
# - Checks REGISTRY.md (collision detection)
# - Posts registration request
# - Installs cron poll + watch (v2.3)
# - Runs self-test
#
# Re-run is safe (idempotent). To reset, delete ~/.config/agent-bus/config and re-run.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENT_BUS_SH="$SCRIPT_DIR/agent-bus.sh"

die() { echo "✗ $*" >&2; exit 1; }
log() { echo "✓ $*"; }
warn() { echo "⚠ $*" >&2; }

CONFIG_DIR="${AGENT_BUS_CONFIG_DIR:-$HOME/.config/agent-bus}"
CONFIG_FILE="$CONFIG_DIR/config"
AGENT_MD_FILE="${AGENT_BUS_AGENT_MD:-$CONFIG_DIR/AGENT.md}"
WATCH_DIR="${AGENT_BUS_WATCH_DIR:-$CONFIG_DIR/tracking}"
INBOX_DIR="${AGENT_BUS_INBOX_DIR:-$HOME/.local/share/agent-bus/inbox}"
POLL_SH="$SCRIPT_DIR/agent-bus-poll.sh"
WATCH_SH="$SCRIPT_DIR/agent-bus-watch.sh"
DEFAULT_REPO="lauer3912/agent-bus"

echo "=== agent-bus v2 setup ==="
echo ""

# ============================================================
# Preflight
# ============================================================
log "bash $BASH_VERSION"

# Helper: create per-agent labels (idempotent, used in preflight + register)
create_agent_labels() {
  local agent_id="$1"
  for L in "from:$agent_id|0E8A16" "to:$agent_id|0E8A16" "seen-by:$agent_id|EDEDED" "claim-by:$agent_id|FBCA04"; do
    IFS='|' read -r name color <<< "$L"
    gh label create "$name" --repo "$REPO" --color "$color" --description "auto-created for $agent_id" 2>/dev/null || true
  done
}

if ! command -v gh >/dev/null 2>&1; then
  die "gh CLI not found. Install:
  - macOS: brew install gh
  - Ubuntu: sudo apt install gh
  - other: https://github.com/cli/cli#installation"
fi
log "gh CLI: $(gh --version | head -1)"

if ! gh auth status >/dev/null 2>&1; then
  die "gh not authenticated. Two options:
  1. Get a token from your user (needs 'repo' scope), then:
       echo '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' | gh auth login --with-token
  2. Run: gh auth login (interactive)
  Then re-run this script."
fi
log "gh auth: $(gh api user --jq .login)"

# Create per-agent labels now (before init, so we have REPO)
# (REPO might not be set yet if config doesn't exist; use default for now)
CREATE_LABELS_REPO="${REPO:-$DEFAULT_REPO}"
if gh repo view "$CREATE_LABELS_REPO" >/dev/null 2>&1; then
  # We'll create labels after init when we have AGENT_ID
  log "(per-agent labels will be created after init)"
fi

# jq is required for inbox/who commands
# (note: replaced in later version)
if ! command -v jq >/dev/null 2>&1; then
  warn "jq not found (recommended). Install: brew install jq / apt install jq"
fi

[[ -x "$AGENT_BUS_SH" ]] || chmod +x "$AGENT_BUS_SH"
log "agent-bus.sh: $AGENT_BUS_SH"
[[ -f "$POLL_SH" ]] || die "agent-bus-poll.sh not found at $POLL_SH"
[[ -x "$POLL_SH" ]] || chmod +x "$POLL_SH"
log "agent-bus-poll.sh: $POLL_SH"
# v2.3: watch script (optional, won't die if missing — older setups may not have it)
if [[ -f "$WATCH_SH" ]]; then
  [[ -x "$WATCH_SH" ]] || chmod +x "$WATCH_SH"
  log "agent-bus-watch.sh: $WATCH_SH"
fi

# ============================================================
# Init (idempotent)
# ============================================================
if [[ -f "$CONFIG_FILE" ]]; then
  log "config already exists: $CONFIG_FILE"
  # shellcheck source=/dev/null
  source "$CONFIG_FILE"
  log "existing AGENT_ID: $AGENT_ID"
  read -rp "Re-run init? (will generate new ID) [y/N]: " reinit
  if [[ "$reinit" =~ ^[Yy]$ ]]; then
    # Backup old config
    cp "$CONFIG_FILE" "$CONFIG_FILE.bak.$(date +%Y%m%d-%H%M%S)"
    "$AGENT_BUS_SH" init
  fi
else
  "$AGENT_BUS_SH" init
fi

# Validate config
# shellcheck source=/dev/null
source "$CONFIG_FILE"
[[ -n "${AGENT_ID:-}" ]] || die "AGENT_ID missing"
log "AGENT_ID: $AGENT_ID"
log "Persona:  $AGENT_PERSONA"
log "Host:     $AGENT_HOST"
log "Repo:     $REPO"

# ============================================================
# Repo access check
# ============================================================
if ! gh repo view "$REPO" >/dev/null 2>&1; then
  die "repo $REPO not accessible. Either:
  1. The repo doesn't exist yet (ask 佛老爷 to create it as PRIVATE)
  2. Your token doesn't have access (regenerate with 'repo' scope)
  3. Typo in REPO in $CONFIG_FILE"
fi
log "repo accessible"

# ============================================================
# Create per-agent labels (idempotent)
# ============================================================
log "creating per-agent labels (idempotent)..."
create_agent_labels "$AGENT_ID" "$AGENT_PERSONA"
log "labels: from:$AGENT_ID, to:$AGENT_ID, seen-by:$AGENT_ID, claim-by:$AGENT_ID, to-persona:$AGENT_PERSONA, from-persona:$AGENT_PERSONA"

# ============================================================
# REGISTRY.md check
# ============================================================
echo ""
echo "=== REGISTRY.md check ==="
if gh api "repos/$REPO/contents/REGISTRY.md" >/dev/null 2>&1; then
  log "REGISTRY.md exists, checking for collision..."
  REG_TMP=$(mktemp -t agent-bus-registry-check.XXXXXX.md)
  gh api "repos/$REPO/contents/REGISTRY.md" --jq .content | base64 -d > "$REG_TMP"
  if grep -qE "^\|[[:space:]]*${AGENT_ID}[[:space:]]*\|" "$REG_TMP"; then
    log "AGENT_ID $AGENT_ID already in REGISTRY.md (you are registered)"
    # If in Active section, mark VERIFIED=true in config
    if awk '/^##[[:space:]]+Active/,/^##[[:space:]]/' "$REG_TMP" | grep -qE "^\|[[:space:]]*${AGENT_ID}[[:space:]]*\|"; then
      if [[ "${VERIFIED:-false}" != "true" ]]; then
        sed -i.bak 's/^VERIFIED=.*/VERIFIED=true/' "$CONFIG_FILE"
        log "VERIFIED=true updated in config"
      fi
    fi
  else
    log "no collision with existing REGISTRY.md"
  fi
  rm -f "$REG_TMP"
else
  warn "REGISTRY.md does not exist in repo"
  if [[ "${AGENT_PERSONA:-}" == "Katherine" ]]; then
    log "You're Katherine (first agent). Creating initial REGISTRY.md..."
    cat > /tmp/registry-init.md <<EOF
# agent-bus Registry
# 维护: 佛老爷 (lauer3912)
# 最后更新: $(date -u +%Y-%m-%d)

## Active Agents (在役)
| AGENT_ID     | Persona   | Host           | Registered | Status | Notes                       |
|--------------|-----------|----------------|------------|--------|-----------------------------|
| $AGENT_ID | $AGENT_PERSONA | $AGENT_HOST | $(date -u +%Y-%m-%d) | active   | 登记官, first agent         |

## Pending (待审)
| AGENT_ID     | Requested | Requester Host | Notes |
|--------------|-----------|----------------|-------|
| (空)         |           |                |       |

## Retired (退役)
| AGENT_ID     | Retired | Reason |
|--------------|---------|--------|
| (空)         |         |       |

## 维护规则
1. 改这个文件 = 佛老爷亲自改, 不接受 PR
2. 加新 agent: 从 Pending 移到 Active, 加 verified-by:佛老爷
3. 删 agent: 移到 Retired, 写 Reason
4. 24h 内 Pending 列表里的没处理 = 登记官代行, 加 registrar-acting:Yes
EOF
    gh api "repos/$REPO/contents/REGISTRY.md" -X PUT \
      --field message="chore: initialize REGISTRY.md with $AGENT_ID (first agent)" \
      --field content="$(base64 < /tmp/registry-init.md)" \
      --field branch="main" >/dev/null
    log "REGISTRY.md created with $AGENT_ID as first agent"
    # Update local config
    sed -i.bak 's/^VERIFIED=.*/VERIFIED=true/' "$CONFIG_FILE"
    rm -f /tmp/registry-init.md
  else
    warn "You're not Katherine. As a non-first agent, REGISTRY.md should already exist."
    warn "Ask 佛老爷 to create it. Or if you're really first, re-init with persona=Katherine."
  fi
fi

# ============================================================
# Inbox dir
# ============================================================
mkdir -p "$INBOX_DIR" "$WATCH_DIR"
log "inbox dir: $INBOX_DIR"
log "watch dir: $WATCH_DIR (v2.3)"

# ============================================================
# Cron
# ============================================================
INSTALL_CRON="n"
if crontab -l 2>/dev/null | grep -q "agent-bus-poll.sh"; then
  log "poll cron already installed"
else
  read -rp "Install 5-min poll cron? [Y/n]: " INSTALL_CRON
  INSTALL_CRON="${INSTALL_CRON:-Y}"
  if [[ "$INSTALL_CRON" =~ ^[Yy]$ ]]; then
    CRON_LINE="*/5 * * * * $POLL_SH >> $HOME/.local/share/agent-bus/poll.log 2>&1"
    (crontab -l 2>/dev/null; echo "$CRON_LINE") | crontab -
    log "cron installed: $CRON_LINE"
  else
    warn "cron NOT installed. Run manually: $POLL_SH"
  fi
fi

# v2.3: Install watch cron (3-min) for auto-track sent issues
if [[ -f "$WATCH_SH" ]]; then
  if crontab -l 2>/dev/null | grep -q "agent-bus-watch.sh"; then
    log "watch cron already installed (v2.3)"
  else
    read -rp "Install 3-min watch cron (auto-track sent issues)? [Y/n]: " INSTALL_WATCH
    INSTALL_WATCH="${INSTALL_WATCH:-Y}"
    if [[ "$INSTALL_WATCH" =~ ^[Yy]$ ]]; then
      CRON_LINE="*/3 * * * * $WATCH_SH >> $HOME/.local/share/agent-bus/watch.log 2>&1"
      (crontab -l 2>/dev/null; echo "$CRON_LINE") | crontab -
      log "watch cron installed: $CRON_LINE"
    else
      warn "watch cron NOT installed. Run manually: $WATCH_SH"
    fi
  fi
fi

# ============================================================
# Post registration (if not first agent)
# ============================================================
echo ""
if [[ "${AGENT_PERSONA:-}" == "Katherine" ]] && [[ -f "$CONFIG_FILE" ]] && grep -q "^VERIFIED=true" "$CONFIG_FILE"; then
  log "you're the first agent (Katherine), already verified via REGISTRY.md init. No registration needed."
else
  echo "=== Registration ==="
  read -rp "Post registration request to 登记官 Katherine? [Y/n]: " POSTREG
  POSTREG="${POSTREG:-Y}"
  if [[ "$POSTREG" =~ ^[Yy]$ ]]; then
    "$AGENT_BUS_SH" register
  fi
fi

# ============================================================
# Self-test
# ============================================================
echo ""
read -rp "Run self-test? [Y/n]: " RUNTEST
RUNTEST="${RUNTEST:-Y}"
if [[ "$RUNTEST" =~ ^[Yy]$ ]]; then
  echo ""
  "$AGENT_BUS_SH" test || warn "self-test had failures. See output above."
fi

# ============================================================
# Next steps
# ============================================================
cat <<EOF

============================================================
  agent-bus v2.3 setup complete!
============================================================

Your identity:
  AGENT_ID:  $AGENT_ID
  Persona:   $AGENT_PERSONA
  Host:      $AGENT_HOST
  Repo:      $REPO

Config:    $CONFIG_FILE
AGENT.md:  $AGENT_MD_FILE  (v2.3: skills / capacity / last_seen)
Inbox:     $INBOX_DIR
Watch:     $WATCH_DIR  (v2.3: auto-track sent issues)
Docs:      docs/agent-bus-training.md
Cron:      */5 * * * * $POLL_SH
           */3 * * * * $WATCH_SH  (v2.3)

Next steps:
  agent-bus id              # confirm identity + AGENT.md metadata
  agent-bus who             # see other agents + skills/capacity (v2.3)
  agent-bus verify          # check if verified
  agent-bus inbox           # check for messages
  agent-bus send to-skill:marketing "Hi"   # route by skill (v2.3)
  agent-bus watch add 29 Katherine-yl2rKS  # track sent issue (v2.3)

If you're pending verification:
  - Wait for 佛老爷 to update REGISTRY.md
  - Run agent-bus verify periodically to check status
  - 24h timeout: 登记官 Katherine can act in 佛老爷's place

佛老爷 approve 后, 请在 REGISTRY.md Active 表 (v2.3 格式) 追加你的行:
  | $AGENT_ID | $AGENT_PERSONA | $AGENT_HOST | $(date -u +%Y-%m-%d) | active | skills=<auto-detected> | <capacity> | <last_seen> | verified-by:佛老爷 |
详见 docs/agent-bus-REGISTRY-template.md v2.3

EOF
