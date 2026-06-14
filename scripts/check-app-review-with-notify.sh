#!/bin/bash
# ========================================
# OpenClaw: launchd 调用的 iOS App 审核检测 wrapper (通用)
# ========================================
# 用法:
#   check-app-review-with-notify.sh <app-name>
#
# 设计:
#   - launchd (macOS 系统级 scheduler) 调此 wrapper
#   - wrapper 调原 check-app-review.sh <app-name>
#   - 拿脚本输出, 根据 emoji 决定要不要弹 Mac 通知
#   - 所有输出写 log 文件
#
# 触发场景:
#   - launchd 每 2h 跑一次 (offset cron 的 1h, 2/6/10/14/18/22)
#   - OpenClaw cron 挂了的时候, launchd 仍跑 + 弹 Mac 通知
#   - 双保险: cron + launchd 都盯着 ASC 状态
#
# 配合 plist: ~/Library/LaunchAgents/com.openclaw.<app-name>-review.plist
# ========================================

set -uo pipefail

# --- 参数检查 ---
[[ $# -ge 1 ]] || { echo "Usage: $0 <app-name>" >&2; exit 1; }
APP_KEY="$1"

# --- 配置 ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$SCRIPT_DIR/check-app-review.sh"
LOG="$HOME/.openclaw/workspace/.cache/${APP_KEY}-review-launchd.log"
CACHE_DIR="$HOME/.openclaw/workspace/.cache"
STATE_FILE="$CACHE_DIR/${APP_KEY}-review-state"
MAX_LOG_LINES=500  # 滚动保留最后 500 行

# --- 加载 project 配置拿 display name ---
CONF_FILE="$HOME/.config/ios-projects/${APP_KEY}.conf"
[[ -f "$CONF_FILE" ]] || { echo "❌ config not found: $CONF_FILE" >&2; exit 1; }
# shellcheck source=/dev/null
source "$CONF_FILE"
APP_DISPLAY_NAME="${APP_DISPLAY_NAME:-$APP_KEY}"

# --- 前置检查 ---
if [ ! -f "$SCRIPT" ]; then
    osascript -e "display notification \"check-app-review.sh not found\" with title \"$APP_DISPLAY_NAME 审核 wrapper 错误\"" 2>/dev/null || true
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ❌ 主脚本不存在: $SCRIPT" >> "$LOG"
    exit 2
fi

mkdir -p "$CACHE_DIR"

# --- 跑主脚本 ---
OUTPUT=$(bash "$SCRIPT" "$APP_KEY" 2>&1)
EXIT_CODE=$?
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# --- 写 log (滚动) ---
{
    echo "[$TIMESTAMP] exit=$EXIT_CODE state=$(cat "$STATE_FILE" 2>/dev/null || echo 'MISSING')"
    echo "$OUTPUT"
    echo "---"
} >> "$LOG"

# 滚动 log
if [ -f "$LOG" ] && [ "$(wc -l < "$LOG")" -gt "$MAX_LOG_LINES" ]; then
    tail -n "$MAX_LOG_LINES" "$LOG" > "$LOG.tmp" && mv "$LOG.tmp" "$LOG"
fi

# --- 决定要不要弹 Mac 通知 ---
# 状态变更的输出包含 emoji
if echo "$OUTPUT" | grep -qE '🚨|🎉|⏸️|🔄|🔔'; then
    BODY=$(echo "$OUTPUT" | tr -d '\n' | head -c 200)
    osascript -e "display notification \"$BODY\" with title \"$APP_DISPLAY_NAME 审核状态变更\"" 2>/dev/null || true
fi

# 错误时也弹通知
if [ "$EXIT_CODE" -ne 0 ] || echo "$OUTPUT" | grep -q '❌'; then
    BODY=$(echo "$OUTPUT" | tr -d '\n' | head -c 200)
    osascript -e "display notification \"$BODY\" with title \"$APP_DISPLAY_NAME 审核检查错误\"" 2>/dev/null || true
fi

exit $EXIT_CODE
