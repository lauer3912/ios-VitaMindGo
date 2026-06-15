#!/bin/bash
# check-placeholders.sh — 自动化检查简称 / 占位符 / 省略
# 用途: 任何 commit 前跑, 防止漏改 (按 18:31 佛老爷拍板)
# 用法: bash scripts/check-placeholders.sh

set -euo pipefail

cd "$(dirname "$0")/.."

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

ERRORS=0
WARN=0

echo "=== check-placeholders.sh (按 18:31 佛老爷拍板) ==="
echo ""

# 1. K-E2wa1m 简称 (跳过反例/说明)
K_E=$(grep -rn '\bK-E2wa1m\b' . 2>/dev/null | grep -v ".bak:" | grep -v "/.git/" | grep -v "/.dreams/" | grep -v "/screenshots/" | grep -v "K-E2wa1m 都是错的" | grep -v "K-E2wa1m 都不允许" | grep -v "K-E2wa1m 都不行" | grep -v "K-E2wa1m / K-yl2rKS" | grep -v "K-E2wa1m → Katherine" | grep -v "❌.*K-E2wa1m" | grep -v "改 K-E2wa1m" | grep -v "K-E2wa1m 简称" | wc -l)
if [ "$K_E" -gt 0 ]; then
    echo -e "${RED}❌ K-E2wa1m 简称: $K_E 处${NC}"
    grep -rn '\bK-E2wa1m\b' . 2>/dev/null | grep -v ".bak:" | grep -v "/.git/" | grep -v "/.dreams/" | grep -v "/screenshots/" | grep -v "都是错的" | grep -v "都不允许" | grep -v "都不行" | grep -v "K-E2wa1m / K-yl2rKS" | grep -v "K-E2wa1m → Katherine" | grep -v "❌.*K-E2wa1m" | grep -v "改 K-E2wa1m" | grep -v "K-E2wa1m 简称" | head -5
    ERRORS=$((ERRORS + K_E))
else
    echo -e "${GREEN}✅ 无 K-E2wa1m 简称${NC}"
fi

# 2. K-yl2rKS 简称
K_Y=$(grep -rn '\bK-yl2rKS\b' . 2>/dev/null | grep -v ".bak:" | grep -v "/.git/" | grep -v "/.dreams/" | grep -v "/screenshots/" | grep -v "K-E2wa1m / K-yl2rKS" | grep -v "K-yl2rKS → Katherine" | grep -v "❌.*K-yl2rKS" | grep -v "改 K-yl2rKS" | grep -v "K-yl2rKS 简称" | grep -v "K-yl2rKS 都不允许" | wc -l)
if [ "$K_Y" -gt 0 ]; then
    echo -e "${RED}❌ K-yl2rKS 简称: $K_Y 处${NC}"
    grep -rn '\bK-yl2rKS\b' . 2>/dev/null | grep -v ".bak:" | grep -v "/.git/" | grep -v "/.dreams/" | grep -v "/screenshots/" | grep -v "K-E2wa1m / K-yl2rKS" | grep -v "K-yl2rKS → Katherine" | grep -v "❌.*K-yl2rKS" | grep -v "改 K-yl2rKS" | grep -v "K-yl2rKS 简称" | grep -v "都不允许" | head -5
    ERRORS=$((ERRORS + K_Y))
else
    echo -e "${GREEN}✅ 无 K-yl2rKS 简称${NC}"
fi

# 3. Katherine-a7f3 / Katherine-b2c1d4 占位符 (历史, 应是真名)
K_HIST=$(grep -rn 'Katherine-a7f3\|Katherine-b2c1d4\|Katherine-c5d2e1\|Katherine2-xxxxxx' . 2>/dev/null | grep -v ".bak:" | grep -v "/.git/" | wc -l)
if [ "$K_HIST" -gt 0 ]; then
    echo -e "${RED}❌ 历史占位符 Katherine-a7f3 等: $K_HIST 处${NC}"
    grep -rn 'Katherine-a7f3\|Katherine-b2c1d4\|Katherine-c5d2e1\|Katherine2-xxxxxx' . 2>/dev/null | grep -v ".bak:" | grep -v "/.git/" | head -5
    ERRORS=$((ERRORS + K_HIST))
else
    echo -e "${GREEN}✅ 无历史占位符${NC}"
fi

# 4. ghp_yyy / ghp_yyyxxxxx / ghp_yyyx (跳过 feishu-to-ubuntu-agent.txt 历史消息, 但**应该**改)
GHP=$(grep -rn 'ghp_yyy\+\|ghp_yyyxxx\+\|ghp_x' . 2>/dev/null | grep -v ".bak:" | grep -v "/.git/" | grep -v "feishu-to-ubuntu-agent-2026-06-14" | wc -l)
if [ "$GHP" -gt 0 ]; then
    echo -e "${RED}❌ ghp_yyy 占位符: $GHP 处${NC}"
    grep -rn 'ghp_yyy\+\|ghp_yyyxxx\+\|ghp_x' . 2>/dev/null | grep -v ".bak:" | grep -v "/.git/" | grep -v "feishu-to-ubuntu-agent" | head -5
    ERRORS=$((ERRORS + GHP))
else
    echo -e "${GREEN}✅ 无 ghp_yyy 占位符${NC}"
fi

# 5. YOUR_USER / YOUR_GITHUB_PAT / YOUR_WEBHOOK_URL 占位符
YOUR=$(grep -rn 'YOUR_[A-Z_]\+\|EXAMPLE_[A-Z_]\+\|<YOUR[A-Z_-]*>' . 2>/dev/null | grep -v ".bak:" | grep -v "/.git/" | wc -l)
if [ "$YOUR" -gt 0 ]; then
    echo -e "${YELLOW}⚠️ YOUR_ 占位符: $YOUR 处 (非错, 是教 user 改, 但佛老爷 17:46 强禁省略)${NC}"
    grep -rn 'YOUR_[A-Z_]\+\|EXAMPLE_[A-Z_]\+\|<YOUR[A-Z_-]*>' . 2>/dev/null | grep -v ".bak:" | grep -v "/.git/" | head -3
    WARN=$((WARN + YOUR))
else
    echo -e "${GREEN}✅ 无 YOUR_ 占位符${NC}"
fi

# 6. 总结
echo ""
echo "=== 总结 ==="
if [ "$ERRORS" -gt 0 ]; then
    echo -e "${RED}❌ 错: $ERRORS 处 (必须改)${NC}"
fi
if [ "$WARN" -gt 0 ]; then
    echo -e "${YELLOW}⚠️ 警告: $WARN 处 (佛老爷 17:46 强禁, 但不是执行命令, 跳过)${NC}"
fi
if [ "$ERRORS" -eq 0 ] && [ "$WARN" -eq 0 ]; then
    echo -e "${GREEN}✅ 全清! 0 占位符 / 0 简称${NC}"
    exit 0
elif [ "$ERRORS" -gt 0 ]; then
    exit 1
else
    exit 0
fi
