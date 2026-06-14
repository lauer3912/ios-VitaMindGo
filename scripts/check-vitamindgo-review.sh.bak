#!/bin/bash
# ========================================
# OpenClaw: VitaMindGo 审核状态变更检测 (cron 友好)
# ========================================
# 用法:
#   check-vitamindgo-review.sh              # 跑一次, 输出通知 / NO_REPLY
#
# 设计:
#   - 调 asc-api-query.sh 拿当前 state
#   - 跟 ~/.openclaw/workspace/.cache/vitamindgo-review-state 比对
#   - state 变 → 输出通知 (1-2 句中文)
#   - state 没变 → 输出 NO_REPLY (cron 不打扰)
#   - state = REJECTED → 输出详细通知
#   - state file 不存在 → 创建 + 输出当前 state (防 cron 首次跑误报)
#
# 配合 cron: 每 4h 跑一次, delivery: announce 到 QQ
# ========================================

set -euo pipefail

# --- 配置 ---
export APP_STORE_CONNECT_ISSUER_ID="b2a00f88-3a8d-40d0-b148-1f1db92e10b7"
APP_ID="6774840392"
CACHE_DIR="$HOME/.openclaw/workspace/.cache"
STATE_FILE="$CACHE_DIR/vitamindgo-review-state"
SCRIPT_DIR="$HOME/.openclaw/workspace/scripts"
APP_NAME="VitaMindGo"
APP_VERSION="3.0.0"
APP_BUNDLE="com.ggsheng.VitaMind"

# --- 拿当前 state ---
CURRENT_RAW=$(bash "$SCRIPT_DIR/asc-api-query.sh" version-state "$APP_ID" 2>&1)
if echo "$CURRENT_RAW" | grep -q "❌"; then
  echo "❌ asc-api-query.sh 调用失败:"
  echo "$CURRENT_RAW" | head -5
  exit 1
fi
CURRENT_STATE=$(echo "$CURRENT_RAW" | grep "^  State:" | awk '{print $2}')
if [ -z "$CURRENT_STATE" ]; then
  echo "❌ 解析 state 失败, 原始输出:"
  echo "$CURRENT_RAW" | head -10
  exit 1
fi

# --- 拿上次 state ---
mkdir -p "$CACHE_DIR"
if [ -f "$STATE_FILE" ]; then
  LAST_STATE=$(cat "$STATE_FILE" | cut -d: -f1)
  LAST_TIME=$(cat "$STATE_FILE" | cut -d: -f2-)
else
  LAST_STATE=""
  LAST_TIME=""
fi

# --- 比对 + 输出 ---
NOW=$(date -Iseconds)
if [ "$CURRENT_STATE" = "$LAST_STATE" ]; then
  # 没变, 静默
  echo "NO_REPLY"
  exit 0
fi

# 变了, 写新 state
echo "$CURRENT_STATE:$NOW" > "$STATE_FILE"

# 输出通知
if [ -z "$LAST_STATE" ]; then
  # 首次记录 (不是真变更, 算初始化)
  echo "📌 $APP_NAME 审核状态初始化记录: $CURRENT_STATE (上次记录缺失, 写入了新 cache)"
  echo "   提交至今: 5 天+ (2026-06-04 14:37 提交)"
  echo "   Version: $APP_VERSION ($APP_BUNDLE)"
  exit 0
fi

# 真变更, 输出通知
case "$CURRENT_STATE" in
  REJECTED)
    echo "🚨 **$APP_NAME 审核被拒!**"
    echo ""
    echo "状态: $LAST_STATE → **$CURRENT_STATE**"
    echo "时间: $NOW"
    echo ""
    echo "⚠️ 立即动作:"
    echo "1. 登 App Store Connect → Resolution Center 看拒绝原因"
    echo "2. 修代码/元数据/截图"
    echo "3. 重新提交 (新 version)"
    echo "4. 我可以帮您: 跑 asc-api-query.sh --json 拿详细 reason field"
    ;;
  READY_FOR_SALE)
    echo "🎉 **$APP_NAME 审核通过! 已上架!**"
    echo ""
    echo "状态: $LAST_STATE → **$CURRENT_STATE**"
    echo "时间: $NOW"
    echo ""
    echo "下一步:"
    echo "1. App Store 搜 '$APP_NAME' 验证上架"
    echo "2. 准备营销 (截图、描述)"
    echo "3. 推 v3.0.1 增量 (新功能)"
    ;;
  PENDING_DEVELOPER_RELEASE)
    echo "⏸️ **$APP_NAME 审核通过, 等您手动发布**"
    echo ""
    echo "状态: $LAST_STATE → **$CURRENT_STATE**"
    echo "时间: $NOW"
    echo ""
    echo "下一步: App Store Connect → 选版本 → 'Release This Version'"
    ;;
  IN_REVIEW)
    echo "🔄 **$APP_NAME 进 Apple 审核了!**"
    echo ""
    echo "状态: $LAST_STATE → **$CURRENT_STATE**"
    echo "时间: $NOW"
    echo "上次状态变更: $LAST_TIME"
    echo ""
    echo "Apple 通常 24-48h 完成 review, 期待下个状态变 READY_FOR_SALE / REJECTED"
    ;;
  *)
    echo "🔔 **$APP_NAME 审核状态变更**"
    echo ""
    echo "状态: $LAST_STATE → **$CURRENT_STATE**"
    echo "时间: $NOW"
    echo "上次状态: $LAST_TIME"
    ;;
esac

# 同时写一条 memory (兜底)
MEMORY_FILE="$HOME/.openclaw/workspace/memory/$(date +%Y-%m-%d).md"
echo "## $(date +%H:%M) VitaMindGo 审核状态变更: $LAST_STATE → $CURRENT_STATE" >> "$MEMORY_FILE" 2>/dev/null || true
