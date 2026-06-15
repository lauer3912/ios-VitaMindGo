#!/bin/bash
# check-fake-values.sh — 自动化检查已知假值 / 编造凭证
# 用途: 任何 commit 前跑 (pre-commit 自动), daily-report 跑 (0:00 + 12:00)
# 按 2026-06-15 23:16 佛老爷 5 铁律 + 6 铁律 (完整值传递) 拍板
# 教训: 2026-06-15 22:39 #79 Comment 1 我 (Katherine-E2wa1m) 用了假值 `7Y8H9J2K` / `1065f10c-2d7c-4c8b-9a9c-6e0bbf12ee21`, 22:47 才纠正, 违反 #15 拍板

set -u

cd "$(dirname "$0")/.."

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

ERRORS=0

# 已知假值 (历史教训, 2026-06-15 22:39 #79 Comment 1 误用, 2026-06-15 23:16 纠正)
# 格式: "pattern|reason"  (一行一个, 严禁在 MEMORY/SOUL/scripts 出现这些模式)
FAKE_PATTERNS=(
  "7Y8H9J2K|假 ASC API Key ID (22:39 #79 Comment 1 误用, 真实是 H3973L93M5)"
  "1065f10c-2d7c-4c8b-9a9c-6e0bbf12ee21|假 ASC Issuer ID (22:39 #79 Comment 1 误用, 真实是 b2a00f88-3a8d-40d0-b148-1f1db92e10b7)"
  "lauer3912@techidaily|假 Apple ID (22:39 #79 Comment 1 暗示, 真实是 support@techidaily.com)"
  "@keychain:ASC_KEYCHAIN_NAME|占位符 keychain 引用 (佛老爷 15:27 拍板严禁, 真实用 API key path)"
  "ASC_KEYCHAIN_NAME|占位符 keychain 名 (无真实值占位符, 严禁)"
  "xxx@techidaily|占位符 Apple ID (佛老爷 #15 拍板严禁)"
  "your_api_key_here|占位符 (严禁)"
  "your_issuer_id_here|占位符 (严禁)"
  "REPLACE_ME|占位符 (严禁)"
  "<your-|占位符尖括号 (佛老爷 #15 拍板严禁)"
  "your_.*_id|占位符 ID 模式 (佛老爷 #15 拍板严禁)"
)

echo "=== check-fake-values.sh (按 2026-06-15 23:16 佛老爷 5+6 铁律) ==="
echo ""

# 豁免文件 (教训段 / 已知真值)
EXCLUDE_FILES=(
  "check-fake-values.sh"        # 脚本自身含 pattern
  "/SOUL.md"                    # 教训段必含占位符反例
  "/MEMORY.md"                  # 教训段必含占位符反例
  "scripts/setup-github-cred.sh"  # 含团队共享真实 token (佛老爷 2026-06-08 拍板)
  "skills/reddit/"              # 教学文档, 用户填占位符
  "docs/"                       # 教学/参考文档
)
EXCLUDE_PATTERN=$(printf '%s|' "${EXCLUDE_FILES[@]}" | sed 's/|$//')

for entry in "${FAKE_PATTERNS[@]}"; do
  pattern="${entry%%|*}"
  reason="${entry#*|}"
  # 整词匹配 (-w) + 排除脚本自身 + 排除 .git/ + 排除 .bak + 排除豁免文件
  matches=$(grep -rnw "$pattern" . 2>/dev/null | grep -v "/.git/" 2>/dev/null | grep -vE "\.bak(\.|$)" 2>/dev/null | grep -vE "$EXCLUDE_PATTERN" 2>/dev/null)
  if [ -n "$matches" ]; then
    echo -e "${RED}❌ 假值 '$pattern' 出现:${NC}"
    echo "   原因: $reason"
    echo "$matches" | head -3 | sed 's/^/   /'
    ERRORS=$((ERRORS + 1))
  fi
done

# 额外: 扫 MEMORY.md 之外的"应该是真实值但用了 placeholder 模式"
# 模式: 真值看起来像 UUID/Key ID, 但写成 `<...>` 或 `xxx`
PLACEHOLDER_PATTERNS=(
  '<API_KEY_ID>|<.*> 占位符 (佛老爷 #15 拍板严禁)'
  '<API_Issuer_ID>|<.*> 占位符 (佛老爷 #15 拍板严禁)'
  '<issuer_id>|<.*> 占位符 (佛老爷 #15 拍板严禁)'
  '<key_id>|<.*> 占位符 (佛老爷 #15 拍板严禁)'
)
for entry in "${PLACEHOLDER_PATTERNS[@]}"; do
  pattern="${entry%%|*}"
  reason="${entry#*|}"
  matches=$(grep -rnE "$pattern" . 2>/dev/null | grep -v "/.git/" 2>/dev/null | grep -v ".bak:" 2>/dev/null | grep -v "check-fake-values.sh" 2>/dev/null)
  if [ -n "$matches" ]; then
    echo -e "${RED}❌ 占位符 '$pattern' 出现:${NC}"
    echo "   原因: $reason"
    echo "$matches" | head -3 | sed 's/^/   /'
    ERRORS=$((ERRORS + 1))
  fi
done

# 特殊: 检查 scripts/ 里的 shell 变量赋值, 避免硬编码假值
echo ""
echo "--- scripts/ 内 hardcoded fake credential check ---"
SCRIPT_FAKES=$(grep -rEn '(API_KEY|API_?KEY|API_?Issuer|ISSUER|TOKEN|ASC_)' scripts/ 2>/dev/null | grep -vE '^(.*#|.*echo|.*log|.*--apiKey|--apiIssuer|.*H3973L93M5|.*b2a00f88|.*AuthKey_)' | head -5)
if [ -n "$SCRIPT_FAKES" ]; then
  echo -e "${YELLOW}⚠️  scripts/ 内有疑似凭证引用:${NC}"
  echo "$SCRIPT_FAKES" | sed 's/^/   /'
  # 警告不阻塞
fi

if [ $ERRORS -gt 0 ]; then
  echo ""
  echo -e "${RED}❌ check-fake-values.sh 失败: 发现 $ERRORS 个假值/占位符${NC}"
  echo "   修复: 1) 查 MEMORY.md 真实值  2) 替换  3) 重跑"
  exit 1
fi

echo -e "${GREEN}✅ 无假值/占位符${NC}"
exit 0
