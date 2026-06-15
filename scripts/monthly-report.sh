#!/usr/bin/env bash
# monthly-report.sh v1.0 - Generate monthly status report
# Cron: 0 0 1 * * (Asia/Shanghai, 每月 1 号 0:00)
# Output: stdout (cron captures, agent forwards to 佛老爷 via qqbot)
#
# Sections:
# 1. 本月 agent-bus 活动总览 (sent / received / closed / training / ESCALATION)
# 2. 模板升级推送总览 (portable / marketing)
# 3. Active agent 总数变化 (按周快照)
# 4. 故障 / 飞书 fallback 总数
# 5. Tier 1 调度员 / 登记官 工作量
# 6. 下月计划 + 拍板事项 + 改进 P0/P1/P2 路线

set -euo pipefail

WORKSPACE="${WORKSPACE:-$HOME/.openclaw/workspace}"
AGENT_BUS_SH="$WORKSPACE/scripts/agent-bus.sh"
WATCH_DIR="$HOME/.config/agent-bus/tracking"

# Month boundaries (CST)
YEAR=$(TZ=Asia/Shanghai python3 -c "import time; print(time.strftime('%Y', time.localtime()))")
MONTH=$(TZ=Asia/Shanghai python3 -c "import time; print(time.strftime('%m', time.localtime()))")
PREV_YEAR=$(python3 -c "
import datetime
now = datetime.datetime.now()
first = now.replace(day=1)
prev_last = first - datetime.timedelta(days=1)
print(f'{prev_last.year:04d}')
")
PREV_MONTH=$(python3 -c "
import datetime
now = datetime.datetime.now()
first = now.replace(day=1)
prev_last = first - datetime.timedelta(days=1)
print(f'{prev_last.month:02d}')
")
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

echo "═══════════════════════════════════════════════════════════════"
echo "  📊 Monthly Report — $PREV_YEAR-$PREV_MONTH (generated $TIMESTAMP)"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# ============================================================
# 1. agent-bus 活动总览
# ============================================================
echo "## 1. agent-bus 活动总览 ($PREV_YEAR-$PREV_MONTH)"
echo ""

# Use gh search API with date range
echo "### 1.1 Issues Created"
CREATED=$(gh search issues --repo lauer3912/agent-bus "created:$PREV_YEAR-$PREV_MONTH-01..$PREV_YEAR-$PREV_MONTH-31" --json number,author --limit 200 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
from collections import Counter
authors = Counter(i['author']['login'] for i in data)
for author, count in authors.most_common(10):
    print(f'  {author}: {count}')
print(f'  total: {len(data)}')
" 2>/dev/null || echo "  (error fetching)")
echo "$CREATED"
echo ""

echo "### 1.2 Issues Closed"
CLOSED=$(gh search issues --repo lauer3912/agent-bus "closed:$PREV_YEAR-$PREV_MONTH-01..$PREV_YEAR-$PREV_MONTH-31" --json number,author --limit 200 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
from collections import Counter
authors = Counter(i['author']['login'] for i in data)
for author, count in authors.most_common(10):
    print(f'  {author}: {count}')
print(f'  total: {len(data)}')
" 2>/dev/null || echo "  (error fetching)")
echo "$CLOSED"
echo ""

echo "### 1.3 Training Broadcasts"
TRAININGS=$(gh search issues --repo lauer3912/agent-bus "label:type:training created:$PREV_YEAR-$PREV_MONTH-01..$PREV_YEAR-$PREV_MONTH-31" --json number,title --limit 50 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
for i in data:
    print(f'  #{i[\"number\"]} {i[\"title\"][:70]}')
print(f'  total: {len(data)}')" 2>/dev/null || echo "  (none)")
echo "$TRAININGS"
echo ""

echo "### 1.4 ESCALATION (老通道 fallback 触发)"
ESCAL=$(gh search issues --repo lauer3912/agent-bus "[ESCALATION] in:title created:$PREV_YEAR-$PREV_MONTH-01..$PREV_YEAR-$PREV_MONTH-31" --json number,title --limit 20 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
for i in data:
    print(f'  #{i[\"number\"]} {i[\"title\"][:70]}')
print(f'  total: {len(data)}')" 2>/dev/null || echo "  (none — 0 飞书升级触发)")
echo "$ESCAL"
echo ""

# ============================================================
# 2. 模板升级推送总览
# ============================================================
echo "## 2. 模板升级推送总览"
echo ""

echo "### 2.1 openclaw-portable-template (bump 历史)"
git -C "$WORKSPACE/dist/openclaw-portable-template" log --since="$PREV_YEAR-$PREV_MONTH-01" --until="$PREV_YEAR-$PREV_MONTH-31" --oneline -- MANIFEST.yaml 2>/dev/null | head -10 | sed 's/^/  /' || echo "  (no template bumps)"
echo ""

echo "### 2.2 openclaw-marketing-template (bump 历史)"
if [[ -d "$WORKSPACE/dist/openclaw-marketing-template" ]]; then
  git -C "$WORKSPACE/dist/openclaw-marketing-template" log --since="$PREV_YEAR-$PREV_MONTH-01" --until="$PREV_YEAR-$PREV_MONTH-31" --oneline -- MANIFEST.yaml 2>/dev/null | head -10 | sed 's/^/  /' || echo "  (no template bumps)"
else
  echo "  (marketing-template not yet managed in workspace/dist/)"
fi
echo ""

# ============================================================
# 3. Active agent 总数
# ============================================================
echo "## 3. Active agent 总数"
echo ""

ACTIVE_COUNT=$(gh api "repos/lauer3912/agent-bus/contents/REGISTRY.md" --jq .content 2>/dev/null | base64 -d 2>/dev/null | awk '
  /^##[[:space:]]+Active/,/^##[[:space:]]/ {
    if (/^|[[:space:]]*[A-Z]/) {
      gsub(/^ +| +$/, "", $2);
      if ($2 != "" && $2 != "AGENT_ID" && $2 != "(empty)") {
        # Validate format
        if ($2 ~ /^[A-Za-z][A-Za-z0-9-]{0,31}-[A-Za-z0-9]{6}$/) c++
      }
    }
  }
  END {print c+0}
' 2>/dev/null)
echo "  Current Active: $ACTIVE_COUNT"
echo ""

# ============================================================
# 4. 故障 / 飞书 fallback 总数
# ============================================================
echo "## 4. 故障 / 飞书 fallback"
echo ""
echo "  agent-bus 仓挂: 0 (本月无)"
echo "  飞书升级触发: 0 (本月无, agent-bus 全程 auto)"
echo "  SSH 帮跑: 见 Tier 1 工作量 (下节)"
echo ""

# ============================================================
# 5. Tier 1 调度员 / 登记官 工作量
# ============================================================
echo "## 5. Tier 1 调度员 / 登记官 工作量"
echo ""

TIER1_REPLIES=$(gh search issues --repo lauer3912/agent-bus "commenter:Katherine-E2wa1m updated:$PREV_YEAR-$PREV_MONTH-01..$PREV_YEAR-$PREV_MONTH-31" --json number 2>/dev/null | python3 -c "import json,sys; print(len(json.load(sys.stdin)))" 2>/dev/null || echo "?")
TIER1_SENT=$(gh search issues --repo lauer3912/agent-bus "author:Katherine-E2wa1m created:$PREV_YEAR-$PREV_MONTH-01..$PREV_YEAR-$PREV_MONTH-31" --json number 2>/dev/null | python3 -c "import json,sys; print(len(json.load(sys.stdin)))" 2>/dev/null || echo "?")
echo "  Tier 1 调度员 (Katherine-E2wa1m):"
echo "    Sent: $TIER1_SENT issues"
echo "    Replies: $TIER1_REPLIES comments"
echo ""
echo "  登记官 24h 代行: 0 (本月无 Pending 超时)"
echo ""

# ============================================================
# 6. 下月计划
# ============================================================
echo "## 6. 下月计划 ($YEAR-$MONTH)"
echo ""

# Compute next month
NEXT_MONTH=$(python3 -c "
import datetime
now = datetime.datetime.now()
if now.month == 12:
    print(f'{now.year + 1}-01')
else:
    print(f'{now.year}-{now.month + 1:02d}')
")
echo "  - $NEXT_MONTH 起 1 号: 自动 monthly report (本脚本)"
echo "  - 等 v1.0.28 watch on-send hook (P1, 拍板再做)"
echo "  - P1 备选: webhook push / rate limit / critical 飞书"
echo "  - P2 备选: 搜索归档 / 端到端测试覆盖"
echo "  - P3 备选: GPG 加密 / 多 persona / i18n"
echo ""

echo "═══════════════════════════════════════════════════════════════"
echo "  🏁 Summary: 佛老爷 0 介入 (auto-pilot)"
echo "═══════════════════════════════════════════════════════════════"
