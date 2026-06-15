#!/bin/bash
# check-placeholders.sh — 自动化检查简称 / 占位符 / 省略
# 用途: 任何 commit 前跑 (pre-commit 自动), daily-report 跑 (0:00 + 12:00)
# 按 18:31 + 18:50 佛老爷拍板: 必须改掉漏的坏习惯

# 18:50 修 bug:
#   - 用 set -u (保留变量未定义报), 不用 -e + pipefail (grep 0 匹配 exit 1 触发)
#   - 加辅助函数 gcount() / glines() 包装 grep
#   - 排除自身 (check-placeholders.sh) + 反例 (❌ K-E2wa1m 都不允许) + 历史 (16:18 实战教训) + 标识 (<反例: 不应使用的简称>)

set -u

cd "$(dirname "$0")/.."

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

ERRORS=0
WARN=0

# 通用排除: 跳过自身 + 反例/历史/标识/说明
# 注意: 这个 grep 自身**有** K-E2wa1m 字符串 (在注释), 用 'scripts/check-placeholders.sh\|dist/.../check-placeholders.sh\|/screenshots/\|/.dreams/' 排除
COMMON_EXCLUDE="grep -v .bak: | grep -v '/.git/' | grep -v 'check-placeholders.sh:' | grep -v 'check-placeholders.sh$' | grep -v '/.dreams/' | grep -v '/screenshots/'"

# 辅助: 0-match-safe grep count
gcount() {
  local pat="$1"
  # 双 grep: 先 main grep, 再 exclude (用 '|| true' 防 0 匹配 exit 1)
  grep -rn "$pat" . 2>/dev/null | grep -v ".bak:" 2>/dev/null | grep -v "/.git/" 2>/dev/null | wc -l 2>/dev/null | tr -d ' '
}

glines() {
  local pat="$1"
  grep -rn "$pat" . 2>/dev/null | grep -v ".bak:" 2>/dev/null | grep -v "/.git/" 2>/dev/null | head -5 2>/dev/null
}

echo "=== check-placeholders.sh (按 18:31 + 18:50 佛老爷拍板) ==="
echo ""

# 1. K-E2wa1m 简称 (排除反例/历史/标识/说明)
K_E_RAW=$(gcount '\bK-E2wa1m\b')
# 排除: ❌ K-E2wa1m 都不允许/都不行/都是错的, K-E2wa1m / K-yl2rKS (反例), K-E2wa1m → Katherine, 改 K-E2wa1m, K-E2wa1m 简称, <反例: 不应使用的简称>
K_E=$(grep -rn '\bK-E2wa1m\b' . 2>/dev/null \
  | grep -v ".bak:" 2>/dev/null \
  | grep -v "/.git/" 2>/dev/null \
  | grep -v "check-placeholders.sh" 2>/dev/null \
  | grep -v "/.dreams/" 2>/dev/null \
  | grep -v "/screenshots/" 2>/dev/null \
  | grep -v "都是错的" 2>/dev/null \
  | grep -v "都不允许" 2>/dev/null \
  | grep -v "都不行" 2>/dev/null \
  | grep -v "K-E2wa1m / K-yl2rKS" 2>/dev/null \
  | grep -v "K-E2wa1m → Katherine" 2>/dev/null \
  | grep -v "❌.*K-E2wa1m" 2>/dev/null \
  | grep -v "改 K-E2wa1m" 2>/dev/null \
  | grep -v "K-E2wa1m 简称" 2>/dev/null \
  | grep -v "<反例: 不应使用的简称>" 2>/dev/null \
  | wc -l | tr -d ' ')
if [ "${K_E:-0}" -gt 0 ] 2>/dev/null; then
    echo -e "${RED}❌ K-E2wa1m 简称: $K_E 处${NC}"
    grep -rn '\bK-E2wa1m\b' . 2>/dev/null \
      | grep -v ".bak:" 2>/dev/null \
      | grep -v "/.git/" 2>/dev/null \
      | grep -v "check-placeholders.sh" 2>/dev/null \
      | grep -v "/.dreams/" 2>/dev/null \
      | grep -v "/screenshots/" 2>/dev/null \
      | grep -v "都是错的" 2>/dev/null \
      | grep -v "都不允许" 2>/dev/null \
      | grep -v "都不行" 2>/dev/null \
      | grep -v "K-E2wa1m / K-yl2rKS" 2>/dev/null \
      | grep -v "K-E2wa1m → Katherine" 2>/dev/null \
      | grep -v "❌.*K-E2wa1m" 2>/dev/null \
      | grep -v "改 K-E2wa1m" 2>/dev/null \
      | grep -v "K-E2wa1m 简称" 2>/dev/null \
      | grep -v "<反例: 不应使用的简称>" 2>/dev/null \
      | head -5
    ERRORS=$((ERRORS + K_E))
else
    echo -e "${GREEN}✅ 无 K-E2wa1m 简称${NC}"
fi

# 2. K-yl2rKS 简称
K_Y=$(grep -rn '\bK-yl2rKS\b' . 2>/dev/null \
  | grep -v ".bak:" 2>/dev/null \
  | grep -v "/.git/" 2>/dev/null \
  | grep -v "check-placeholders.sh" 2>/dev/null \
  | grep -v "/.dreams/" 2>/dev/null \
  | grep -v "/screenshots/" 2>/dev/null \
  | grep -v "K-E2wa1m / K-yl2rKS" 2>/dev/null \
  | grep -v "K-yl2rKS → Katherine" 2>/dev/null \
  | grep -v "❌.*K-yl2rKS" 2>/dev/null \
  | grep -v "改 K-yl2rKS" 2>/dev/null \
  | grep -v "K-yl2rKS 简称" 2>/dev/null \
  | grep -v "都不允许" 2>/dev/null \
  | grep -v "<反例: 不应使用的简称>" 2>/dev/null \
  | wc -l | tr -d ' ')
if [ "${K_Y:-0}" -gt 0 ] 2>/dev/null; then
    echo -e "${RED}❌ K-yl2rKS 简称: $K_Y 处${NC}"
    grep -rn '\bK-yl2rKS\b' . 2>/dev/null \
      | grep -v ".bak:" 2>/dev/null \
      | grep -v "/.git/" 2>/dev/null \
      | grep -v "check-placeholders.sh" 2>/dev/null \
      | grep -v "/.dreams/" 2>/dev/null \
      | grep -v "/screenshots/" 2>/dev/null \
      | grep -v "K-E2wa1m / K-yl2rKS" 2>/dev/null \
      | grep -v "K-yl2rKS → Katherine" 2>/dev/null \
      | grep -v "❌.*K-yl2rKS" 2>/dev/null \
      | grep -v "改 K-yl2rKS" 2>/dev/null \
      | grep -v "K-yl2rKS 简称" 2>/dev/null \
      | grep -v "都不允许" 2>/dev/null \
      | grep -v "<反例: 不应使用的简称>" 2>/dev/null \
      | head -5
    ERRORS=$((ERRORS + K_Y))
else
    echo -e "${GREEN}✅ 无 K-yl2rKS 简称${NC}"
fi

# 3. Katherine-a7f3 / Katherine-b2c1d4 占位符 (历史)
K_HIST=$(grep -rn 'Katherine-a7f3\|Katherine-b2c1d4\|Katherine-c5d2e1\|Katherine2-xxxxxx' . 2>/dev/null \
  | grep -v ".bak:" 2>/dev/null \
  | grep -v "/.git/" 2>/dev/null \
  | grep -v "check-placeholders.sh" 2>/dev/null \
  | grep -v "training 提" 2>/dev/null \
  | grep -v "training 改" 2>/dev/null \
  | wc -l | tr -d ' ')
if [ "${K_HIST:-0}" -gt 0 ] 2>/dev/null; then
    echo -e "${RED}❌ 历史占位符: $K_HIST 处${NC}"
    grep -rn 'Katherine-a7f3\|Katherine-b2c1d4\|Katherine-c5d2e1\|Katherine2-xxxxxx' . 2>/dev/null \
      | grep -v ".bak:" 2>/dev/null \
      | grep -v "/.git/" 2>/dev/null \
      | grep -v "check-placeholders.sh" 2>/dev/null \
      | grep -v "training 提" 2>/dev/null \
      | grep -v "training 改" 2>/dev/null \
      | head -5
    ERRORS=$((ERRORS + K_HIST))
else
    echo -e "${GREEN}✅ 无历史占位符${NC}"
fi

# 4. ghp_xxx / ghp_xxxxxxxx / ghp_xxxx
GHP=$(grep -rn 'ghp_xxx\+\|ghp_xxxxxx\+\|ghp_x' . 2>/dev/null \
  | grep -v ".bak:" 2>/dev/null \
  | grep -v "/.git/" 2>/dev/null \
  | grep -v "check-placeholders.sh" 2>/dev/null \
  | grep -v "feishu-to-ubuntu-agent-2026-06-14" 2>/dev/null \
  | wc -l | tr -d ' ')
if [ "${GHP:-0}" -gt 0 ] 2>/dev/null; then
    echo -e "${RED}❌ ghp_xxx 占位符: $GHP 处${NC}"
    grep -rn 'ghp_xxx\+\|ghp_xxxxxx\+\|ghp_x' . 2>/dev/null \
      | grep -v ".bak:" 2>/dev/null \
      | grep -v "/.git/" 2>/dev/null \
      | grep -v "check-placeholders.sh" 2>/dev/null \
      | grep -v "feishu-to-ubuntu-agent-2026-06-14" 2>/dev/null \
      | head -5
    ERRORS=$((ERRORS + GHP))
else
    echo -e "${GREEN}✅ 无 ghp_xxx 占位符${NC}"
fi

# 5. YOUR_ 占位符 (教 user 改, 警告)
YOUR=$(grep -rn 'YOUR_[A-Z_]\+\|EXAMPLE_[A-Z_]\+\|<YOUR[A-Z_-]*>' . 2>/dev/null \
  | grep -v ".bak:" 2>/dev/null \
  | grep -v "/.git/" 2>/dev/null \
  | grep -v "check-placeholders.sh" 2>/dev/null \
  | wc -l | tr -d ' ')
if [ "${YOUR:-0}" -gt 0 ] 2>/dev/null; then
    echo -e "${YELLOW}⚠️ YOUR_ 占位符: $YOUR 处 (教 user 改, 非错)${NC}"
    grep -rn 'YOUR_[A-Z_]\+\|EXAMPLE_[A-Z_]\+\|<YOUR[A-Z_-]*>' . 2>/dev/null \
      | grep -v ".bak:" 2>/dev/null \
      | grep -v "/.git/" 2>/dev/null \
      | grep -v "check-placeholders.sh" 2>/dev/null \
      | head -3
    WARN=$((WARN + YOUR))
else
    echo -e "${GREEN}✅ 无 YOUR_ 占位符${NC}"
fi

# 总结
echo ""
echo "=== 总结 ==="
if [ "${ERRORS:-0}" -gt 0 ] 2>/dev/null; then
    echo -e "${RED}❌ 错: $ERRORS 处 (必须改)${NC}"
fi
if [ "${WARN:-0}" -gt 0 ] 2>/dev/null; then
    echo -e "${YELLOW}⚠️ 警告: $WARN 处${NC}"
fi
if [ "${ERRORS:-0}" -eq 0 ] && [ "${WARN:-0}" -eq 0 ]; then
    echo -e "${GREEN}✅ 全清! 0 占位符 / 0 简称${NC}"
    exit 0
elif [ "${ERRORS:-0}" -gt 0 ]; then
    exit 1
else
    exit 0
fi
