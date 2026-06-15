#!/bin/bash
# check-placeholders.sh — 自动化检查简称 / 占位符 / 省略
# 用途: 任何 commit 前跑 (pre-commit 自动), daily-report 跑 (0:00 + 12:00)
# 按 18:31 + 18:50 佛老爷拍板: 必须改掉漏的坏习惯

# 22:24 实战修:
#   - 之前用 '\\\\bK-E2wa1m\\\\b' 失败 (perl 替换 escape 问题)
#   - 改: 'grep -rnw K-E2wa1m' 整词匹配 (准确)
#   - 5 层防护真生效: pre-commit 拦了 commit → 修 bug → 重新 commit → 0 错通过

set -u

cd "$(dirname "$0")/.."

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

ERRORS=0
WARN=0

# 辅助函数: grep with 0-match-safe (不触发 set -e exit)
# 豁免: MEMORY.md / SOUL.md (教训段必含简称) + .bak.* + check-placeholders.sh 自身
gcount() {
  local pat="$1"
  grep -rnw "$pat" . 2>/dev/null | grep -vE "\.bak(\.|$)" 2>/dev/null | grep -v "/.git/" 2>/dev/null | grep -v "check-placeholders.sh" 2>/dev/null | grep -vE "/(MEMORY|SOUL)\.md" 2>/dev/null | grep -vE "/memory/" 2>/dev/null | wc -l 2>/dev/null | tr -d ' '
}

glines() {
  local pat="$1"
  grep -rnw "$pat" . 2>/dev/null | grep -vE "\.bak(\.|$)" 2>/dev/null | grep -v "/.git/" 2>/dev/null | grep -v "check-placeholders.sh" 2>/dev/null | grep -vE "/(MEMORY|SOUL)\.md" 2>/dev/null | grep -vE "/memory/" 2>/dev/null | head -5 2>/dev/null
}

echo "=== check-placeholders.sh (按 18:31 + 18:50 佛老爷拍板) ==="
echo ""

# 1. K-E2wa1m 简称
K_E=$(gcount 'K-E2wa1m')
if [ "${K_E:-0}" -gt 0 ] 2>/dev/null; then
    echo -e "${RED}❌ K-E2wa1m 简称: $K_E 处${NC}"
    glines 'K-E2wa1m' | head -5
    ERRORS=$((ERRORS + K_E))
else
    echo -e "${GREEN}✅ 无 K-E2wa1m 简称${NC}"
fi

# 2. K-yl2rKS 简称
K_Y=$(gcount 'K-yl2rKS')
if [ "${K_Y:-0}" -gt 0 ] 2>/dev/null; then
    echo -e "${RED}❌ K-yl2rKS 简称: $K_Y 处${NC}"
    glines 'K-yl2rKS' | head -5
    ERRORS=$((ERRORS + K_Y))
else
    echo -e "${GREEN}✅ 无 K-yl2rKS 简称${NC}"
fi

# 3. Katherine-a7f3 / Katherine-b2c1d4 占位符 (历史, 应是真名)
K_HIST=$(gcount 'Katherine-a7f3')
if [ "${K_HIST:-0}" -gt 0 ] 2>/dev/null; then
    echo -e "${RED}❌ 历史占位符 Katherine-a7f3: $K_HIST 处${NC}"
    glines 'Katherine-a7f3' | head -5
    ERRORS=$((ERRORS + K_HIST))
else
    echo -e "${GREEN}✅ 无历史占位符${NC}"
fi

# 4. ghp_xxx / ghp_xxxxxxxx / ghp_xxxx
GHP=$(gcount 'ghp_xxxxxx')
if [ "${GHP:-0}" -gt 0 ] 2>/dev/null; then
    echo -e "${RED}❌ ghp_xxxxxx 占位符: $GHP 处${NC}"
    glines 'ghp_xxxxxx' | head -5
    ERRORS=$((ERRORS + GHP))
else
    echo -e "${GREEN}✅ 无 ghp_xxxxxx 占位符${NC}"
fi

# 5. YOUR_USER / YOUR_GITHUB_PAT / YOUR_WEBHOOK_URL 占位符
YOUR=$(gcount 'YOUR_WEBHOOK_URL')
if [ "${YOUR:-0}" -gt 0 ] 2>/dev/null; then
    echo -e "${YELLOW}⚠️ YOUR_WEBHOOK_URL 占位符: $YOUR 处 (教 user 改, 非错)${NC}"
    glines 'YOUR_WEBHOOK_URL' | head -3
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
