#!/bin/bash
# ========================================
# OpenClaw: VitaMindGo 上架数据监控
# ========================================
# 用法:
#   check-vitamindgo-sales.sh              # 跑一次, 输出通知 / NO_REPLY
#
# 设计:
#   - 调 iTunes Lookup API (公开, 无需 auth)
#   - 拿 ratingCount, averageUserRating, version, price, releaseDate
#   - 跟 ~/.openclaw/workspace/.cache/vitamindgo-sales-state 比对
#   - 关键数据变 (新评分/版本/价格) → 输出通知
#   - 没变 → 输出 NO_REPLY (cron 不打扰)
#   - state file 不存在 → 创建 + 输出当前 state (防 cron 首次跑误报)
#
# 配合 cron: 每天 1 次 (中午), delivery: announce 到 QQ
# ========================================

set -euo pipefail

# --- 配置 ---
APP_ID="6774840392"
COUNTRY="us"
CACHE_DIR="$HOME/.openclaw/workspace/.cache"
STATE_FILE="$CACHE_DIR/vitamindgo-sales-state"
APP_NAME="VitaMindGo"
APP_BUNDLE="com.ggsheng.VitaMind"

mkdir -p "$CACHE_DIR"

# --- 1. 拉 iTunes Lookup ---
ITUNES_URL="https://itunes.apple.com/lookup?id=${APP_ID}&country=${COUNTRY}"
RESP=$(curl -fsSL --max-time 15 "$ITUNES_URL" 2>&1) || {
  echo "❌ iTunes Lookup 请求失败: $RESP" >&2
  exit 1
}

# 解析 (用 python 避免 jq 依赖)
PARSED=$(echo "$RESP" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    if data.get('resultCount', 0) == 0:
        print('NOT_FOUND')
        sys.exit(0)
    r = data['results'][0]
    print(f\"{r.get('version','?')}|{r.get('averageUserRating',0)}|{r.get('userRatingCount',0)}|{r.get('price',0)}|{r.get('currentVersionReleaseDate','')}\")
except Exception as e:
    print(f'PARSE_ERROR: {e}', file=sys.stderr)
    sys.exit(1)
" 2>&1) || {
  echo "❌ iTunes Lookup 解析失败" >&2
  exit 1
}

if [ "$PARSED" = "NOT_FOUND" ]; then
  echo "🚨 VitaMindGo 在 App Store 查不到 (resultCount=0)"
  echo "   可能被下架或 ID 错, 立刻查 ASC 后台"
  exit 0
fi

CUR_VERSION=$(echo "$PARSED" | cut -d'|' -f1)
CUR_RATING=$(echo "$PARSED" | cut -d'|' -f2)
CUR_RATINGS=$(echo "$PARSED" | cut -d'|' -f3)
CUR_PRICE=$(echo "$PARSED" | cut -d'|' -f4)
CUR_RELEASEDATE=$(echo "$PARSED" | cut -d'|' -f5)

# --- 2. 读上次的 state ---
LAST_STATE=""
if [ -f "$STATE_FILE" ]; then
  LAST_STATE=$(cat "$STATE_FILE")
fi

CUR_STATE="${CUR_VERSION}|${CUR_RATING}|${CUR_RATINGS}|${CUR_PRICE}|${CUR_RELEASEDATE}"

# --- 3. 比较 + 输出 ---
if [ -z "$LAST_STATE" ]; then
  # 首次跑, 存 state + 报告
  echo "$CUR_STATE" > "$STATE_FILE"
  echo "🎉 VitaMindGo 上架数据监控启动 (首次):"
  echo "   版本: $CUR_VERSION"
  echo "   评分: $CUR_RATING ($CUR_RATINGS 人评)"
  echo "   价格: \$$CUR_PRICE USD"
  echo "   发布: $CUR_RELEASEDATE"
  exit 0
fi

if [ "$CUR_STATE" = "$LAST_STATE" ]; then
  # 没变
  echo "NO_REPLY"
  exit 0
fi

# 变了! 算 diff
LAST_VERSION=$(echo "$LAST_STATE" | cut -d'|' -f1)
LAST_RATINGS=$(echo "$LAST_STATE" | cut -d'|' -f3)
LAST_RELEASEDATE=$(echo "$LAST_STATE" | cut -d'|' -f5)

NOTIFY="📊 VitaMindGo 上架数据变化:"

# 版本变了
if [ "$CUR_VERSION" != "$LAST_VERSION" ]; then
  NOTIFY="${NOTIFY}\n  📦 版本: $LAST_VERSION → $CUR_VERSION"
fi

# 新评分
NEW_RATINGS=$((CUR_RATINGS - LAST_RATINGS))
if [ "$NEW_RATINGS" -gt 0 ]; then
  NOTIFY="${NOTIFY}\n  ⭐ 新增评分: +$NEW_RATINGS (总 $CUR_RATINGS, 平均 $CUR_RATING)"
fi

# 发布日期变了 (新版本)
if [ "$CUR_RELEASEDATE" != "$LAST_RELEASEDATE" ]; then
  NOTIFY="${NOTIFY}\n  📅 发布日期: $CUR_RELEASEDATE"
fi

# 价格变了 (罕见)
CUR_PRICE_OLD=$(echo "$LAST_STATE" | cut -d'|' -f4)
if [ "$CUR_PRICE" != "$CUR_PRICE_OLD" ]; then
  NOTIFY="${NOTIFY}\n  💰 价格: \$$CUR_PRICE_OLD → \$$CUR_PRICE"
fi

# 存新 state
echo "$CUR_STATE" > "$STATE_FILE"

# 输出
echo -e "$NOTIFY"
