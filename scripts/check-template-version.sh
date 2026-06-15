#!/bin/bash
# ========================================
# OpenClaw Template 版本检查脚本
# ========================================
# 用于 heartbeat 启动检查:
#   - 轻量, 只查版本号 (不 sync)
#   - 版本不一致 → 触发后台 sync
#   - 单次请求, 不 retry (heartbeat 频率够高)
# ========================================
set -euo pipefail

DEFAULT_GITHUB_TOKEN="GH_TOKEN=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"
TEMPLATE_REPO="lauer3912/openclaw-portable-template"
TEMPLATE_BRANCH="main"
GITHUB_RAW="https://raw.githubusercontent.com/${TEMPLATE_REPO}/${TEMPLATE_BRANCH}"

WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
VERSION_FILE="$WORKSPACE/.template-version"
LOCK_FILE="/tmp/openclaw-sync.lock"

acquire_lock() {
  exec 200>"$LOCK_FILE"
  if ! flock -n 200; then exit 0; fi
}

main() {
  acquire_lock

  local remote_ver
  remote_ver=$(curl -fsSL --max-time 10 \
    -H "Authorization: token $DEFAULT_GITHUB_TOKEN" \
    "$GITHUB_RAW/MANIFEST.yaml" 2>/dev/null \
    | grep '^version:' | awk '{print $2}' | tr -d '"') || exit 0

  local local_ver
  local_ver=$(cat "$VERSION_FILE" 2>/dev/null || echo "0.0.0")

  if [ "$remote_ver" != "$local_ver" ]; then
    echo "🔄 Template 有更新: $local_ver → $remote_ver"
    nohup bash "$WORKSPACE/scripts/sync-from-template.sh" \
      >"$WORKSPACE/.sync-nohup.log" 2>&1 &
  fi
}

main "$@"