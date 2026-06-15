#!/usr/bin/env bash
# agent-bus-watch.sh v2.3 - Auto-track sent issues + silent upgrade alerts
# Cron: */3 * * * * (3 min interval, paired with agent-bus-poll.sh)
# Side effects:
#   1. Reads $WATCH_DIR/*.json (one per tracked issue)
#   2. For each, fetches current thread + checks for new replies
#   3. Emits stdout warnings on expected_first_reply_sec breach
#   4. Emits critical alerts on silent_alert_at_sec breach (to be picked up by main session)
#   5. Removes tracking file when issue is closed
#   6. Also updates AGENT.md last_seen (defensive: ensures poll + watch are decoupled)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${AGENT_BUS_CONFIG_DIR:-$HOME/.config/agent-bus}"
CONFIG_FILE="$CONFIG_DIR/config"
WATCH_DIR="${AGENT_BUS_WATCH_DIR:-$CONFIG_DIR/tracking}"
AGENT_MD_FILE="${AGENT_BUS_AGENT_MD:-$CONFIG_DIR/AGENT.md}"

[[ -f "$CONFIG_FILE" ]] || { echo "✗ no config: $CONFIG_FILE. Run: $SCRIPT_DIR/agent-bus-setup.sh" >&2; exit 1; }
# shellcheck source=/dev/null
source "$CONFIG_FILE"

command -v gh >/dev/null 2>&1 || {
  # cron PATH is minimal — search common gh install locations
  for p in /opt/homebrew/bin/gh /usr/local/bin/gh /usr/bin/gh; do
    [[ -x "$p" ]] && { export PATH="$(dirname "$p"):$PATH"; break; }
  done
  command -v gh >/dev/null 2>&1 || { echo "✗ gh not installed (cron PATH=$PATH)" >&2; exit 1; }
}
# v2.3.2: Use GH_TOKEN from local config (chmod 600) — keyring access fails in cron env
if [[ -f "$CONFIG_DIR/gh-token" ]]; then
  # shellcheck source=/dev/null
  source "$CONFIG_DIR/gh-token"
  export GH_TOKEN
fi
gh auth status >/dev/null 2>&1 || { echo "✗ gh not authenticated (set GH_TOKEN in $CONFIG_DIR/gh-token)" >&2; exit 1; }

[[ -d "$WATCH_DIR" ]] || { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] agent-bus-watch: no watch dir yet (no issues watched)"; exit 0; }

TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
NOW_EPOCH=$(date -u +%s)
echo "[$TIMESTAMP] agent-bus-watch v2.3: agent=$AGENT_ID watch_dir=$WATCH_DIR"

# ============================================================
# 1. Update AGENT.md last_seen (defensive — also done by poll.sh)
# ============================================================
if [[ -f "$AGENT_MD_FILE" ]]; then
  sed -i.bak "s/^Last seen:.*/Last seen:   $TIMESTAMP/" "$AGENT_MD_FILE" 2>/dev/null || true
  rm -f "$AGENT_MD_FILE.bak"
fi

# ============================================================
# 2. Walk each watched issue
# ============================================================
WARN_FILE=$(mktemp -t agent-bus-watch-warn.XXXXXX)
ALERT_FILE=$(mktemp -t agent-bus-watch-alert.XXXXXX)
trap 'rm -f "$WARN_FILE" "$ALERT_FILE"' EXIT

WATCH_COUNT=0
for state_file in "$WATCH_DIR"/*.json; do
  [[ -f "$state_file" ]] || continue
  WATCH_COUNT=$((WATCH_COUNT + 1))

  # Parse state (simple key:value)
  num=$(grep -oE '"issue_num":[0-9]+' "$state_file" | grep -oE '[0-9]+' || echo "")
  to=$(grep -oE '"to":"[^"]+"' "$state_file" | sed 's/^"to":"//;s/"$//' || echo "")
  sent_at=$(grep -oE '"sent_at":"[^"]+"' "$state_file" | sed 's/^"sent_at":"//;s/"$//' || echo "")
  expected=$(grep -oE '"expected_first_reply_sec":[0-9]+' "$state_file" | grep -oE '[0-9]+' || echo "600")
  silent=$(grep -oE '"silent_alert_at_sec":[0-9]+' "$state_file" | grep -oE '[0-9]+' || echo "1800")

  [[ -z "$num" || -z "$to" ]] && { echo "  ✗ corrupt state file: $state_file (skip)"; continue; }

  # Compute elapsed seconds since sent_at (use python for cross-platform BSD/GNU date compat)
  sent_epoch=$(python3 -c "
from datetime import datetime, timezone
try:
    dt = datetime.strptime('$sent_at', '%Y-%m-%dT%H:%M:%SZ').replace(tzinfo=timezone.utc)
    print(int(dt.timestamp()))
except Exception as e:
    print(0)
" 2>/dev/null)
  [[ -z "$sent_epoch" || "$sent_epoch" -eq 0 ]] && sent_epoch="$NOW_EPOCH"
  elapsed=$(( NOW_EPOCH - sent_epoch ))

  # Check if issue is closed
  issue_state=$(gh issue view "$num" --repo "$REPO" --json state --jq .state 2>/dev/null || echo "UNKNOWN")
  if [[ "$issue_state" == "CLOSED" ]]; then
    echo "  ✓ issue #$num closed (was to=$to) — auto-cleanup"
    rm -f "$state_file"
    continue
  fi

  # Read owner_gh_login (GitHub user login, not agent-bus AGENT_ID) to filter self-comments
  owner_gh_login=$(grep -oE '"owner_gh_login":"[^"]+"' "$state_file" | sed 's/^"owner_gh_login":"//;s/"$//' || echo "")
  if [[ -z "$owner_gh_login" ]]; then
    # Legacy state file (v2.2 or earlier without owner_gh_login) — fall back to AGENT_ID (best effort)
    owner_gh_login="$AGENT_ID"
  fi

  # Count comments NOT from the owner (sender). Recipient reply = someone OTHER than owner commented.
  recipient_reply=$(gh issue view "$num" --repo "$REPO" --json comments --jq "
    [.comments[] | select(.author.login != \"$owner_gh_login\")] | length
  " 2>/dev/null || echo "0")

  if [[ "$recipient_reply" -gt 0 ]]; then
    # Got a reply from recipient — done watching
    echo "  ✓ issue #$num replied by recipient (replies=$recipient_reply, elapsed=${elapsed}s, owner_gh=$owner_gh_login) — auto-cleanup"
    rm -f "$state_file"
    continue
  fi

  # v2.3.1: skip silent alerts for broadcasts (to:All) — they don't need a specific reply
  if [[ "$to" == "All" ]]; then
    remaining=$(( expected - elapsed ))
    if [[ $remaining -lt 0 ]]; then remaining=0; fi
    echo "  ⏳ issue #$num (to=All broadcast) — silent ${elapsed}s, no reply required (skip alert)"
    continue
  fi

  # No reply yet — check silent thresholds
  if [[ "$elapsed" -ge "$silent" ]]; then
    echo "  🚨 CRITICAL: issue #$num SILENT ${elapsed}s (threshold=${silent}s) to=$to — UPGRADE" | tee -a "$ALERT_FILE"
  elif [[ "$elapsed" -ge "$expected" ]]; then
    echo "  ⚠️ WARNING: issue #$num silent ${elapsed}s (expected<${expected}s) to=$to" | tee -a "$WARN_FILE"
  else
    remaining=$(( expected - elapsed ))
    echo "  ⏳ issue #$num (to=$to) — silent ${elapsed}s, warn in ${remaining}s"
  fi
done

if [[ "$WATCH_COUNT" -eq 0 ]]; then
  echo "  (no active watches — use 'agent-bus watch add N TO' to start tracking)"
fi

# ============================================================
# 3. Summary for cron log
# ============================================================
if [[ -s "$ALERT_FILE" ]]; then
  echo ""
  echo "=== CRITICAL ALERTS ($(grep -c . "$ALERT_FILE")) ==="
  cat "$ALERT_FILE"
  echo ""
  echo "→ Action: ping recipient via 飞书 (老通道) or escalate to 佛老爷"
  exit 2  # Non-zero exit so cron failureAlert can fire if persistent
elif [[ -s "$WARN_FILE" ]]; then
  echo ""
  echo "=== WARNINGS ($(grep -c . "$WARN_FILE")) ==="
  cat "$WARN_FILE"
  echo ""
  echo "→ Action: main session picks up via 3 min cron check + does pre-review"
  exit 1
fi

echo "  ✓ all watched issues have replies (or still under warn threshold)"
exit 0
