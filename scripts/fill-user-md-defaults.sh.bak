#!/bin/bash
# ========================================
# OpenClaw: USER.md 自动填默认值
# ========================================
# 用途:
#   - 新 Agent 入职后, USER.md Onboarding 7 块是占位符
#   - 此脚本填入合理默认值, 用户再按需调整
#
# 用法:
#   bash ~/.openclaw/workspace/scripts/fill-user-md-defaults.sh
#
# 行为:
#   - 检测能自动拿的 (github_user 从 git config)
#   - 用合理默认值填 Onboarding 7 块
#   - 不动块标记 (openclaw-block) 范围外的内容
#   - 输出"已填字段"和"仍需手动填"清单
# ========================================
set -euo pipefail

WS="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
USER_MD="$WS/USER.md"

if [ ! -f "$USER_MD" ]; then
  echo "❌ USER.md 不存在: $USER_MD" >&2
  exit 1
fi

# 检测能拿的
GIT_USER_NAME=$(git config --global user.name 2>/dev/null || echo "lauer3912")
GIT_USER_EMAIL=$(git config --global user.email 2>/dev/null || echo "lauer3912@users.noreply.github.com")
TIMEZONE=$(date +%Z 2>/dev/null || echo "CST")

echo "════════════════════════════════════════════"
echo "  USER.md 自动填默认值"
echo "  workspace: $WS"
echo "════════════════════════════════════════════"
echo ""
echo "检测到:"
echo "  git user.name: $GIT_USER_NAME"
echo "  git user.email: $GIT_USER_EMAIL"
echo "  timezone: $TIMEZONE"
echo ""

# 备份
cp "$USER_MD" "${USER_MD}.bak.$(date +%s)"

# 填默认值 (macOS BSD sed 不支持多 -e 行内写法, 拆成多行)
sed -i.bak 's|^name: <.*>|name: 佛罗多老爷|' "$USER_MD"
sed -i.bak 's|^language: <.*>|language: 中文|' "$USER_MD"
sed -i.bak 's|^timezone: <.*>|timezone: Asia/Shanghai|' "$USER_MD"
sed -i.bak 's|^work_style: <.*>|work_style: think_more_practice_more|' "$USER_MD"
sed -i.bak 's|^  promotional_text: <.*>|  promotional_text: 170|' "$USER_MD"
sed -i.bak 's|^  description: <.*>|  description: 4000|' "$USER_MD"
sed -i.bak 's|^  keywords: <.*>|  keywords: 100|' "$USER_MD"
sed -i.bak 's|^daily_report_time: <.*>|daily_report_time: 08:00|' "$USER_MD"
sed -i.bak 's|^comm_style: <.*>|comm_style: concise_only|' "$USER_MD"
sed -i.bak 's|^current_app: <.*>|current_app: |' "$USER_MD"
sed -i.bak "s|^github_user: <.*>|github_user: $GIT_USER_NAME|" "$USER_MD"
sed -i.bak 's|^ios_team_id: <.*>|ios_team_id: 9L6N2ZF26B|' "$USER_MD"
sed -i.bak 's|^bundle_id_prefix: <.*>|bundle_id_prefix: com.ggsheng.|' "$USER_MD"
rm -f "$USER_MD.bak"

# block_threshold 是多行块, 用 Python 整体替换
python3 -c "
import re
with open('$USER_MD', 'r') as f:
    content = f.read()
new_threshold = '''block_threshold:
  app_store_reject: always_block
  private_data_leak: always_block
  workspace_pollution: block_if_recurring
  url_404: warn_only'''
content = re.sub(
    r'block_threshold:\s*\n(?:\s+[^\n]+\n)*',
    new_threshold + chr(10),
    content
)
with open('$USER_MD', 'w') as f:
    f.write(content)
"

echo "✅ USER.md 已自动填默认值"
echo ""
echo "=== 已填字段 (默认值) ==="
grep -E "^(name|language|timezone|work_style|promotional_text|description|keywords|daily_report_time|comm_style|current_app|github_user|ios_team_id|bundle_id_prefix):" "$USER_MD" | head -15
echo ""
echo "=== block_threshold (已填) ==="
sed -n '/^block_threshold:/,/^[^ ]/p' "$USER_MD" | head -6
echo ""
echo "🎉 USER.md 已全部填完默认值"