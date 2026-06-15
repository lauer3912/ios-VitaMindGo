#!/usr/bin/env bash
# agent-bus-test.sh v2 - Standalone self-test (calls agent-bus test)
# Exits 0 on PASS, 1 on FAIL. Sends a report to Katherine on FAIL.
# Useful for cron: 0 8 * * * agent-bus-test.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENT_BUS_SH="$SCRIPT_DIR/agent-bus.sh"
CONFIG_DIR="${AGENT_BUS_CONFIG_DIR:-$HOME/.config/agent-bus}"
CONFIG_FILE="$CONFIG_DIR/config"

[[ -f "$CONFIG_FILE" ]] || { echo "✗ no config: $CONFIG_FILE"; exit 1; }
# shellcheck source=/dev/null
source "$CONFIG_FILE"

if "$AGENT_BUS_SH" test; then
  echo "✓ agent-bus-test PASS at $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  exit 0
else
  echo "✗ agent-bus-test FAIL at $(date -u +%Y-%m-%dT%H:%M:%SZ)" >&2
  "$AGENT_BUS_SH" send "$AGENT_ID" Katherine-E2wa1m report high bus "agent-bus self-test FAILED" --body "
agent-bus v2 self-test failed at $(date -u +%Y-%m-%dT%H:%M:%SZ)
Host: $AGENT_HOST
Agent: $AGENT_ID
Repo: $REPO
Run: $AGENT_BUS_SH test
" 2>/dev/null || true
  exit 1
fi
