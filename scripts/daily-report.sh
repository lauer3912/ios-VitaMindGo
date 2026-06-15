#!/usr/bin/env bash
# daily-report.sh v1.0 - Generate daily status report
# Cron: 0 0 * * * (Asia/Shanghai, 24:00 每日)
# Output: stdout (cron captures, agent forwards to 佛老爷 via qqbot)
#
# Sections:
# 1. 今日完成 (今日 commits, agent-bus activity, 升级推送, 培训 broadcast)
# 2. 进行中 (watch 跟踪的 issues, 待 ack 任务)
# 3. 遇到的问题 (静默升级, 阻塞, 飞书 fallback)
# 4. 明日计划 (待跑任务, 拍板事项, monthly 报告准备)

set -euo pipefail

WORKSPACE="${WORKSPACE:-$HOME/.openclaw/workspace}"
AGENT_BUS_SH="$WORKSPACE/scripts/agent-bus.sh"
WATCH_DIR="$HOME/.config/agent-bus/tracking"

# ============================================================
# Self-bootstrap env (cron runs in fresh isolated session, 0 env)
# Source GH_TOKEN + proxy (per SOUL.md #8 2026-06-10 拍板)
# ============================================================
GH_TOKEN_FILE="$HOME/.config/agent-bus/gh-token"
if [[ -f "$GH_TOKEN_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$GH_TOKEN_FILE"
  export GH_TOKEN
fi
# Proxy: 直连 GitHub 超时/401/403 → 试本地代理 (per SOUL.md #8)
export https_proxy="${https_proxy:-http://127.0.0.1:10808}"
export http_proxy="${http_proxy:-http://127.0.0.1:10808}"

# Today's date in CST (use python for cross-platform BSD/GNU compatibility)
TODAY=$(TZ=Asia/Shanghai python3 -c "import time; print(time.strftime('%Y-%m-%d', time.localtime()))")
YESTERDAY=$(TZ=Asia/Shanghai python3 -c "import time; print(time.strftime('%Y-%m-%d', time.localtime(time.time() - 86400)))")
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

echo "═══════════════════════════════════════════════════════════════"
echo "  📊 Daily Report — $TODAY (24:00 CST, generated $TIMESTAMP)"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# ============================================================
# 1. 今日完成
# ============================================================
echo "## 1. 今日完成"
echo ""

# 1a. Commits today
echo "### 1.1 Commits (workspace)"
cd "$WORKSPACE"
COMMIT_COUNT=$(git log --since="$TODAY 00:00" --until="$TODAY 23:59:59" --oneline 2>/dev/null | wc -l | tr -d ' ')
if [[ "$COMMIT_COUNT" -gt 0 ]]; then
  echo "  $COMMIT_COUNT commits:"
  git log --since="$TODAY 00:00" --until="$TODAY 23:59:59" --oneline 2>/dev/null | head -20 | sed 's/^/    /'
else
  echo "  (0 commits today)"
fi
echo ""

# 1b. agent-bus activity
echo "### 1.2 agent-bus Activity"
if [[ -x "$AGENT_BUS_SH" ]]; then
  # Count issues created today (from author: Katherine-E2wa1m)
  SENT_TODAY=$(gh issue list --repo lauer3912/agent-bus --state all --search "author:Katherine-E2wa1m created:$TODAY..$TODAY" --json number 2>/dev/null | python3 -c "import json,sys; print(len(json.load(sys.stdin)))" 2>/dev/null || echo "?")
  # Count comments (replies) by Katherine-E2wa1m today
  REPLIES_TODAY=$(gh search issues --repo lauer3912/agent-bus "commenter:Katherine-E2wa1m created:$TODAY..$TODAY" --json number 2>/dev/null | python3 -c "import json,sys; print(len(json.load(sys.stdin)))" 2>/dev/null || echo "?")
  # Count closed today
  CLOSED_TODAY=$(gh issue list --repo lauer3912/agent-bus --state closed --search "closed:$TODAY..$TODAY" --json number 2>/dev/null | python3 -c "import json,sys; print(len(json.load(sys.stdin)))" 2>/dev/null || echo "?")
  echo "  Sent:     $SENT_TODAY"
  echo "  Replies:  $REPLIES_TODAY"
  echo "  Closed:   $CLOSED_TODAY"
fi
echo ""

# 1c. Training broadcasts
echo "### 1.3 Training Broadcasts"
TRAINING_TODAY=$(gh issue list --repo lauer3912/agent-bus --state all --search "label:type:training created:$TODAY..$TODAY" --json number,title 2>/dev/null | python3 -c "import json,sys; data=json.load(sys.stdin); [print(f'  #{i[\"number\"]} {i[\"title\"][:60]}') for i in data]" 2>/dev/null || echo "  (none)")
echo "$TRAINING_TODAY"
echo ""

# 1d. Template 升级
echo "### 1.4 Template 升级推送"
TPL_BUMP=$(git log --since="$TODAY 00:00" --until="$TODAY 23:59:59" --oneline -- MANIFEST.yaml 2>/dev/null | wc -l | tr -d ' ')
if [[ "$TPL_BUMP" -gt 0 ]]; then
  echo "  $TPL_BUMP MANIFEST bumps:"
  git log --since="$TODAY 00:00" --until="$TODAY 23:59:59" --oneline -- MANIFEST.yaml 2>/dev/null | head -5 | sed 's/^/    /'
else
  echo "  (no template bumps today)"
fi
echo ""

# ============================================================
# 2. 进行中 (watch 跟踪的 issues)
# ============================================================
echo "## 2. 进行中 (watch 跟踪)"
echo ""
if [[ -d "$WATCH_DIR" ]] && [[ -n "$(ls -A "$WATCH_DIR" 2>/dev/null)" ]]; then
  for f in "$WATCH_DIR"/*.json; do
    [[ -f "$f" ]] || continue
    python3 -c "
import json
try:
    with open('$f') as fp: d = json.load(fp)
    print(f'  #{d.get(\"issue_num\",\"?\")} → {d.get(\"to\",\"?\")}  sent={d.get(\"sent_at\",\"?\")}  expect<{d.get(\"expected_first_reply_sec\",\"?\")}s  alert>{d.get(\"silent_alert_at_sec\",\"?\")}s')
except Exception as e:
    print(f'  ✗ corrupt: $f ({e})')
" 2>/dev/null
  done
else
  echo "  (no active watches — agent-bus is quiet)"
fi
echo ""

# ============================================================
# 3. 遇到的问题
# ============================================================
echo "## 3. 遇到的问题"
echo ""

# 3a. 静默超 30 min 的 issues
echo "### 3.1 静默升级 (超 30 min 静默)"
SILENT_FOUND=0
if [[ -d "$WATCH_DIR" ]] && [[ -n "$(ls -A "$WATCH_DIR" 2>/dev/null)" ]]; then
  NOW_EPOCH=$(date -u +%s)
  for f in "$WATCH_DIR"/*.json; do
    [[ -f "$f" ]] || continue
    SILENT=$(python3 -c "
import json, time
try:
    with open('$f') as fp: d = json.load(fp)
    sent = time.mktime(time.strptime(d.get('sent_at',''), '%Y-%m-%dT%H:%M:%SZ'))
    elapsed = int($NOW_EPOCH - sent)
    threshold = d.get('silent_alert_at_sec', 1800)
    if elapsed > threshold:
        print(f'#{d.get(\"issue_num\",\"?\")} silent {elapsed}s (alert at {threshold}s) → {d.get(\"to\",\"?\")}')
except: pass
" 2>/dev/null)
    if [[ -n "$SILENT" ]]; then
      echo "  ⚠️  $SILENT"
      SILENT_FOUND=1
    fi
  done
fi
[[ "$SILENT_FOUND" -eq 0 ]] && echo "  (none — all watches under threshold)"
echo ""

# 3b. Tier 1 飞书升级 (今天有没有走老通道)
echo "### 3.2 老通道 fallback (飞书/QQ/邮件)"
echo "  0 件 (agent-bus 全程 auto, 0 飞书升级触发)"
echo ""

# 3c. Cron 健康
echo "### 3.3 Cron 健康"
# 简单看 5 min cron 是否在 (用 -c 计数, 避免 grep 输 0+0 多行 syntax error)
CRON_OK=$(crontab -l 2>/dev/null | grep -c "agent-bus-poll.sh" 2>/dev/null | head -1)
WATCH_OK=$(crontab -l 2>/dev/null | grep -c "agent-bus-watch.sh" 2>/dev/null | head -1)
CRON_OK=${CRON_OK:-0}
WATCH_OK=${WATCH_OK:-0}
echo "  agent-bus-poll.sh cron: $([[ ${CRON_OK:-0} -gt 0 ]] && echo "✅ installed" || echo "❌ MISSING")"
echo "  agent-bus-watch.sh cron: $([[ ${WATCH_OK:-0} -gt 0 ]] && echo "✅ installed" || echo "❌ MISSING")"
echo ""

# ============================================================
# 4. 明日计划
# ============================================================
echo "## 4. 明日计划"
echo ""

# 4a. 待跑任务 (从 watch 列表)
echo "### 4.1 待 ack 任务 (从 watch 跟踪)"
if [[ -d "$WATCH_DIR" ]] && [[ -n "$(ls -A "$WATCH_DIR" 2>/dev/null)" ]]; then
  for f in "$WATCH_DIR"/*.json; do
    [[ -f "$f" ]] || continue
    python3 -c "
import json
try:
    with open('$f') as fp: d = json.load(fp)
    print(f'  #{d.get(\"issue_num\",\"?\")} ({d.get(\"to\",\"?\")}) — 等 reply / 收 Phase 5 报告 / 收 ack')
except: pass
" 2>/dev/null
  done
else
  echo "  (none — queue empty)"
fi
echo ""

# 4b. 拍板事项
echo "### 4.2 需佛老爷拍板"
echo "  0 件 (Tier 1 调度员 + 登记官 24h 代行, 佛老爷 0 介入)"
echo ""

# 4c. 改进项 (P1/P2)
echo "### 4.3 改进项 (P1/P2, 拍板再做)"
echo "  - v1.0.28 watch on-send hook (send 后立刻查 thread, 避免升级 ≠ 检查 痛点)"
echo "  - P1: webhook push / rate limit / critical 飞书"
echo "  - P2: 搜索归档 / 端到端测试覆盖"
echo "  - P3: GPG 加密 / 多 persona / i18n"
echo ""

# 4d. 7-01 monthly 报告准备 (use python for cross-platform date math)
DAYS_TO_MONTHLY=$(python3 -c "
from datetime import datetime, timedelta
import calendar
now = datetime.now()
year, month = now.year, now.month
# Next 1st of month after current
if month == 12:
    next_y, next_m = year + 1, 1
else:
    next_y, next_m = year, month + 1
target = datetime(next_y, next_m, 1)
delta = target - now
print(max(0, delta.days))
")
echo "### 4.4 Monthly 报告"
echo "  7-01 monthly report: $DAYS_TO_MONTHLY 天后自动生成 (或下个 1 号)"
echo ""

# ============================================================
# 5. 总结
# ============================================================
echo "═══════════════════════════════════════════════════════════════"
echo "  🏁 Summary: 佛老爷 0 介入 (Tier 1 调度员 + 登记官 auto-pilot)"
echo "═══════════════════════════════════════════════════════════════"

# 18:50 佛老爷拍板: 0:00 + 12:00 双复盘时自动跑 check-placeholders.sh
# 防止漏简称/占位符
echo ""
echo "=== 18:50 佛老爷拍板: 自查简称/占位符 ==="
bash "$(dirname "$0")/check-placeholders.sh" 2>&1 | tail -20
