#!/bin/bash
# ========================================
# OpenClaw: launchd 调用的 VitaMindGo 审核检测 wrapper
# ========================================
# 设计:
#   - launchd (macOS 系统级 scheduler) 调此 wrapper
#   - wrapper 调原 check-vitamindgo-review.sh
#   - 拿脚本输出, 根据 emoji 决定要不要弹 Mac 通知
#   - 所有输出写 log 文件
#
# 触发场景:
#   - launchd 每 2h 跑一次 (offset cron 的 1h, 2/6/10/14/18/22)
#   - OpenClaw cron 挂了的时候, launchd 仍跑 + 弹 Mac 通知
#   - 双保险: cron + launchd 都盯着 ASC 状态
#
# State 文件: ~/.openclaw/workspace/.cache/vitamindgo-review-state
# (跟 cron 共享, 不会重复 announce)
#
# Log 文件: ~/.openclaw/workspace/.cache/vitamindgo-review-launchd.log
# ========================================

set -uo pipefail

# --- 配置 ---
SCRIPT="$HOME/.openclaw/workspace/scripts/check-vitamindgo-review.sh"
LOG="$HOME/.openclaw/workspace/.cache/vitamindgo-review-launchd.log"
CACHE_DIR="$HOME/.openclaw/workspace/.cache"
STATE_FILE="$CACHE_DIR/vitamindgo-review-state"
MAX_LOG_LINES=500  # 滚动保留最后 500 行, 避免无限增长

# --- 前置检查 ---
if [ ! -f "$SCRIPT" ]; then
    osascript -e 'display notification "check-vitamindgo-review.sh not found" with title "VitaMindGo 审核 wrapper 错误"' 2>/dev/null || true
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ❌ 主脚本不存在: $SCRIPT" >> "$LOG"
    exit 2
fi

mkdir -p "$CACHE_DIR"

# --- 跑主脚本 ---
OUTPUT=$(bash "$SCRIPT" 2>&1)
EXIT_CODE=$?
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# --- 写 log (滚动) ---
{
    echo "[$TIMESTAMP] exit=$EXIT_CODE state=$(cat "$STATE_FILE" 2>/dev/null || echo 'MISSING')"
    echo "$OUTPUT"
    echo "---"
} >> "$LOG"

# 滚动 log (保留最后 500 行)
if [ -f "$LOG" ] && [ "$(wc -l < "$LOG")" -gt "$MAX_LOG_LINES" ]; then
    tail -n "$MAX_LOG_LINES" "$LOG" > "$LOG.tmp" && mv "$LOG.tmp" "$LOG"
fi

# --- 决定要不要弹 Mac 通知 ---
# 状态变更的输出包含 emoji: 🚨/🎉/⏸️/🔄/🔔
if echo "$OUTPUT" | grep -qE '🚨|🎉|⏸️|🔄|🔔'; then
    # 取前 200 字符当通知正文
    BODY=$(echo "$OUTPUT" | tr -d '\n' | head -c 200)
    osascript -e "display notification \"$BODY\" with title \"VitaMindGo 审核状态变更\"" 2>/dev/null || true
fi

# 错误时也弹通知
if [ "$EXIT_CODE" -ne 0 ] || echo "$OUTPUT" | grep -q '❌'; then
    BODY=$(echo "$OUTPUT" | tr -d '\n' | head -c 200)
    osascript -e "display notification \"$BODY\" with title \"VitaMindGo 审核检查错误\"" 2>/dev/null || true
fi

exit $EXIT_CODE
