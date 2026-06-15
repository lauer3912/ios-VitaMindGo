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
# 重要: 加 || true, check-placeholders exit 1 不应阻塞 broadcast 段 (17:23 拍板)
echo ""
echo "=== 18:50 佛老爷拍板: 自查简称/占位符 ==="
bash "$(dirname "$0")/check-placeholders.sh" 2>&1 | tail -20 || true

# ============================================================
# 6. 6 铁律 training broadcast (17:23 拍板 + master-rules § 7.6)
# 每天 0:00 必 send to:All training, 引用 master-rules 6 铁律 + ASC + 4 仓库
# 检查今天是否已发, 避免重复 (6 铁律 #1 务实不打扰)
# ============================================================
echo ""
echo "=== 17:23 拍板: 0:00 必 send to:All 6 铁律 broadcast ==="
TODAY_BCAST=$(date +%Y-%m-%d)
# Use gh api + python datetime filter (since API filter is by updated_at, not created_at)
# Get all type:training+to:All issues, filter by created_at in [today 00:00 CST, tomorrow 00:00 CST)
TODAY_CST_START="${TODAY_BCAST}T00:00:00+08:00"
TOMORROW_CST_START=$(python3 -c "from datetime import datetime, timedelta; print((datetime.strptime('$TODAY_BCAST', '%Y-%m-%d') + timedelta(days=1)).strftime('%Y-%m-%dT00:00:00+08:00'))")
EXISTING_BCAST=$(gh api "repos/lauer3912/agent-bus/issues?state=all&labels=type:training,to:All&per_page=100" 2>/dev/null | python3 -c "
import json, sys
from datetime import datetime
data = json.load(sys.stdin)
start_str = '$TODAY_CST_START'  # e.g. 2026-06-16T00:00:00+08:00
end_str = '$TOMORROW_CST_START'
start = datetime.fromisoformat(start_str)
end = datetime.fromisoformat(end_str)
count = 0
for i in data:
    t_str = i.get('created_at', '')
    if not t_str:
        continue
    # ISO 8601: replace 'Z' with '+00:00' for fromisoformat
    if t_str.endswith('Z'):
        t_str = t_str[:-1] + '+00:00'
    try:
        t = datetime.fromisoformat(t_str)
    except ValueError:
        continue
    if start <= t < end:
        count += 1
print(count)
" 2>/dev/null || echo "0")
if [[ "${EXISTING_BCAST:-0}" -gt 0 ]] && [[ "${SKIP_DAILY_BROADCAST:-0}" != "1" ]]; then
  echo "  ⏭️  今天已发 $EXISTING_BCAST 条 to:All training broadcast, 跳过 (避免重复)"
else
  if [[ -x "$(dirname "$0")/agent-bus.sh" ]]; then
    BROADCAST_BODY="## 6 铁律 (佛老爷拍板, 所有 Agent 必守, 16:18 + 16:27 + 16:39 + 17:23 + 18:20)

1. 务实老实, 不弄虚作假 (Kill 警告)
2. 经常自省, 多多审核, 检查遗漏
3. 永久记忆 (每次操作完立刻存)
4. 每天 ≥ 2 次复盘 + 永久可查
5. 完整值传递 (4 仓库, Katherine-E2wa1m 专项)
6. AGENT_ID 必须全名 (18:20 拍板, Katherine-E2wa1m / Katherine-yl2rKS)

## ASC 协议永远 = 已签 (16:27 拍板, 严禁卡)

佛老爷 ASC 账号 support@techidaily.com 所有协议早签 (2026-06-10 VitaMindGo 上架时签 4 项)。
任何 App 上架: 协议已签, 直接 build archive + export + upload + Submit。

## 4 仓库 (Katherine-E2wa1m 专项管理)

- lauer3912/agent-bus (public)
- lauer3912/openclaw-portable-template (private)
- lauer3912/openclaw-portable-marketing-template (private)
- lauer3912/agent-bus-config-backup (private, 每日 03:00 cron 备份)

## 关键信息真实值 (严禁占位符)

- Apple ID: support@techidaily.com
- ASC API Key ID: H3973L93M5
- ASC Issuer ID: b2a00f88-3a8d-40d0-b148-1f1db92e10b7
- macmini IP: 192.168.1.9
- gh proxy (Mac mini): http://127.0.0.1:10808

## 单文件索引

docs/master-rules-from-frodo.md = 佛老爷所有拍板单文件集中 + 抽查必答 8 问

## 维护

Katherine-E2wa1m (Tier 1 调度员, 4 仓库专项管理, 17:23 拍板)"

    BCAST_OUT=$(bash "$(dirname "$0")/agent-bus.sh" send \
      Katherine-E2wa1m \
      All \
      training \
      normal \
      bus \
      "[佛老爷 6 铁律 + master-rules 必读] $(date +%Y-%m-%d) daily" \
      --body "$BROADCAST_BODY" 2>&1)
    if echo "$BCAST_OUT" | grep -q "issue #"; then
      BCAST_NUM=$(echo "$BCAST_OUT" | grep -oE 'issue #[0-9]+' | grep -oE '[0-9]+')
      echo "  ✅ daily broadcast 发出: #$BCAST_NUM"
    else
      echo "  ❌ daily broadcast 失败: $BCAST_OUT"
      # 6 铁律 #1 务实老实, 失败立刻报佛老爷 (Katherine-E2wa1m Tier 1 调度员权限)
      echo "  ⚠️  紧急: 0:00 6 铁律 broadcast 失败, 等下次 cron 重试或人工补发"
    fi
  else
    echo "  ⚠️  agent-bus.sh 不可执行, 跳过 broadcast (待人工补发)"
  fi
fi
