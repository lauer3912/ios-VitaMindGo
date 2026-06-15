#!/usr/bin/env bash
# agent-bus-poll.sh v2.3 - Poll for new issues addressed to me
# Designed for cron (*/5 * * * *)
# Side effects:
#   1. Writes each new issue to INBOX_DIR/<num>.json
#   2. Marks them seen-by:<AGENT_ID> (idempotent)
#   3. Checks REGISTRY.md for my verification status
#   4. v2.3: Updates AGENT.md last_seen (paired with watch.sh)
#   5. Logs to stdout (cron will capture to log file)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${AGENT_BUS_CONFIG_DIR:-$HOME/.config/agent-bus}"
CONFIG_FILE="$CONFIG_DIR/config"
AGENT_MD_FILE="${AGENT_BUS_AGENT_MD:-$CONFIG_DIR/AGENT.md}"
INBOX_DIR="${AGENT_BUS_INBOX_DIR:-$HOME/.local/share/agent-bus/inbox}"

[[ -f "$CONFIG_FILE" ]] || { echo "✗ no config: $CONFIG_FILE. Run: $SCRIPT_DIR/agent-bus-setup.sh" >&2; exit 1; }
# shellcheck source=/dev/null
source "$CONFIG_FILE"

# Ensure gh is reachable — cron PATH often strips /opt/homebrew/bin
if ! command -v gh >/dev/null 2>&1; then
  for gh_candidate in /opt/homebrew/bin/gh /usr/local/bin/gh /usr/bin/gh; do
    [[ -x "$gh_candidate" ]] && { export PATH="$(dirname "$gh_candidate"):$PATH"; break; }
  done
fi
command -v gh >/dev/null 2>&1 || { echo "✗ gh not installed (PATH=$PATH)" >&2; exit 1; }
# v2.3.2: Use GH_TOKEN from local config (chmod 600) — keyring access fails in cron env
if [[ -f "$CONFIG_DIR/gh-token" ]]; then
  # shellcheck source=/dev/null
  source "$CONFIG_DIR/gh-token"
  export GH_TOKEN
fi
gh auth status >/dev/null 2>&1 || { echo "✗ gh not authenticated (set GH_TOKEN in $CONFIG_DIR/gh-token)" >&2; exit 1; }

mkdir -p "$INBOX_DIR"

TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
echo "[$TIMESTAMP] agent-bus-poll v2: agent=$AGENT_ID repo=$REPO"

# ============================================================
# 1. Verify against REGISTRY.md
# ============================================================
REG_TMP=$(mktemp -t agent-bus-registry-poll.XXXXXX.md)
if gh api "repos/$REPO/contents/REGISTRY.md" --jq .content 2>/dev/null | base64 -d > "$REG_TMP" 2>/dev/null; then
  if grep -qE "^\|[[:space:]]*${AGENT_ID}[[:space:]]*\|" "$REG_TMP" \
     && awk '/^##[[:space:]]+Active/,/^##[[:space:]]/' "$REG_TMP" | grep -qE "^\|[[:space:]]*${AGENT_ID}[[:space:]]*\|"; then
    if [[ "${VERIFIED:-false}" != "true" ]]; then
      sed -i.bak 's/^VERIFIED=.*/VERIFIED=true/' "$CONFIG_FILE"
      echo "[$TIMESTAMP]   ✓ verified (now in REGISTRY.md active list)"
    fi
  elif awk '/^##[[:space:]]+Pending/,/^##[[:space:]]/' "$REG_TMP" | grep -qE "^\|[[:space:]]*${AGENT_ID}[[:space:]]*\|"; then
    echo "[$TIMESTAMP]   ⚠ still in pending list (waiting for 佛老爷)"
  fi
else
  echo "[$TIMESTAMP]   ⚠ REGISTRY.md not found in $REPO"
fi
rm -f "$REG_TMP"

# ============================================================
# 2. Fetch new issues
# ============================================================
# Direct (to:AGENT_ID)
RAW_DIRECT=$(gh issue list \
  --repo "$REPO" \
  --state open \
  --label "to:${AGENT_ID}" \
  --limit 100 \
  --json number,title,state,labels,updatedAt,author,body,url 2>/dev/null) || RAW_DIRECT="[]"

# Persona (to-persona:PERSONA) - v2.1: any of my persona
RAW_PERSONA="[]"
if [[ -n "${AGENT_PERSONA:-}" ]]; then
  RAW_PERSONA=$(gh issue list \
    --repo "$REPO" \
    --state open \
    --label "to-persona:${AGENT_PERSONA}" \
    --limit 100 \
    --json number,title,state,labels,updatedAt,author,body,url 2>/dev/null) || RAW_PERSONA="[]"
fi

# Broadcast (to:All)
RAW_BROADCAST=$(gh issue list \
  --repo "$REPO" \
  --state open \
  --label "to:All" \
  --limit 100 \
  --json number,title,state,labels,updatedAt,author,body,url 2>/dev/null) || RAW_BROADCAST="[]"

# Combine
RAW=$(jq -s 'add | unique_by(.number)' <<< "$RAW_DIRECT $RAW_PERSONA $RAW_BROADCAST")
COUNT=$(echo "$RAW" | jq 'length')
echo "[$TIMESTAMP]   found $COUNT open issue(s) for $AGENT_ID"

# ============================================================
# 3. Process each new issue
# ============================================================
NEW=0
SKIPPED=0
while IFS= read -r issue; do
  [[ -z "$issue" || "$issue" == "null" ]] && continue
  num=$(echo "$issue" | jq -r .number)
  seen=$(echo "$issue" | jq -r --arg me "$AGENT_ID" '.labels[] | select(.name == "seen-by:" + $me) | .name' | head -1)
  if [[ -n "$seen" ]]; then
    SKIPPED=$((SKIPPED + 1))
    continue
  fi
  out="$INBOX_DIR/$num.json"
  echo "$issue" | jq . > "$out"
  NEW=$((NEW + 1))
  echo "[$TIMESTAMP]   NEW: #$num → $out"
  gh issue edit "$num" --repo "$REPO" --add-label "seen-by:${AGENT_ID}" >/dev/null 2>&1 || \
    echo "[$TIMESTAMP]   WARN: failed to label seen-by:$AGENT_ID on #$num"
done < <(echo "$RAW" | jq -c '.[]')

echo "[$TIMESTAMP]   new=$NEW skipped=$SKIPPED"

# ============================================================
# 4. Cleanup old inbox entries (>7 days)
# ============================================================
find "$INBOX_DIR" -name "*.json" -mtime +7 -delete 2>/dev/null || true

# ============================================================
# 5. Optional notify hook
# ============================================================
if [[ -n "${AGENT_BUS_NOTIFY_CMD:-}" && $NEW -gt 0 ]]; then
  new_nums=$(ls -1t "$INBOX_DIR"/*.json 2>/dev/null | head -n "$NEW" | xargs -I {} basename {} .json)
  if [[ -n "$new_nums" ]]; then
    echo "[$TIMESTAMP]   notify: $AGENT_BUS_NOTIFY_CMD $new_nums"
    # shellcheck disable=SC2086
    $AGENT_BUS_NOTIFY_CMD $new_nums || echo "[$TIMESTAMP]   WARN: notify failed"
  fi
fi

# ============================================================
# 6. v2.3: Update AGENT.md last_seen
# ============================================================
if [[ -f "$AGENT_MD_FILE" ]]; then
  sed -i.bak "s/^Last seen:.*/Last seen:   $TIMESTAMP/" "$AGENT_MD_FILE" 2>/dev/null || true
  rm -f "$AGENT_MD_FILE.bak"
fi

exit 0
