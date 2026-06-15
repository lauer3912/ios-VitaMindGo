#!/usr/bin/env bash
# test-suite.sh v1.0 — 6 铁律 + 抽查 + 机制 verify (佛老爷 06-16 06:55 拍板 "立马补救, 还得多测试")
# 用途:
#   1. 任何 commit 前 (pre-commit hook)
#   2. 每日 0:00 + 12:00 (daily-report + midday)
#   3. 抽查准备 (佛老爷 100% 抽查 6 铁律 + ASC + 4 仓库 + 关键信息真实值)
#
# 8 个测试:
#   T1: 6 铁律 (master-rules § 1 必含 6 条)
#   T2: ASC 协议 = 已签 (master-rules § "永远 = 已签")
#   T3: 4 仓库 (lauer3912/agent-bus, portable-template, portable-marketing-template, config-backup)
#   T4: API Key 真实值 (H3973L93M5, b2a00f88-...)
#   T5: daily-report.sh broadcast 段存在 + skip dup 工作
#   T6: check-placeholders.sh 0 错
#   T7: check-fake-values.sh 0 错
#   T8: 抽查 8 问答案都在 master-rules
#
# 维护: Katherine-E2wa1m (Tier 1 调度员)

set -u

cd "$(dirname "$0")/.."

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS=0
FAIL=0
ERRORS=()

ok() { PASS=$((PASS+1)); echo -e "  ${GREEN}✅ $1${NC}"; }
ko() { FAIL=$((FAIL+1)); ERRORS+=("$1: $2"); echo -e "  ${RED}❌ $1: $2${NC}"; }

echo "═══════════════════════════════════════════════════════════════"
echo "  🧪 test-suite.sh v1.0 (佛老爷 06-16 06:55 拍板多测试)"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# T1: 6 铁律 (master-rules § 1)
echo "T1: 6 铁律 (master-rules § 1)"
if [[ -f docs/master-rules-from-frodo.md ]]; then
  for n in "务实老实" "经常自省" "永久记忆" "每天 ≥ 2 次复盘" "完整值传递" "AGENT_ID 必须全名"; do
    if grep -q "$n" docs/master-rules-from-frodo.md; then
      ok "6 铁律: $n 找到"
    else
      ko "6 铁律: $n 缺失" "master-rules-from-frodo.md"
    fi
  done
else
  ko "T1: master-rules-from-frodo.md 不存在" ""
fi
echo ""

# T2: ASC 协议 = 已签
echo "T2: ASC 协议永远 = 已签"
if [[ -f docs/master-rules-from-frodo.md ]]; then
  if grep -q "永远 = 已签" docs/master-rules-from-frodo.md; then
    ok "ASC 协议拍板: 永远 = 已签"
  else
    ko "ASC 协议拍板" "master-rules 没 '永远 = 已签'"
  fi
fi
echo ""

# T3: 4 仓库
echo "T3: 4 仓库 (Katherine-E2wa1m 专项管理)"
REPOS=("lauer3912/agent-bus" "lauer3912/openclaw-portable-template" "lauer3912/openclaw-portable-marketing-template" "lauer3912/agent-bus-config-backup")
for r in "${REPOS[@]}"; do
  if [[ -f docs/master-rules-from-frodo.md ]] && grep -q "$r" docs/master-rules-from-frodo.md; then
    ok "4 仓库: $r 在 master-rules"
  else
    ko "4 仓库: $r" "master-rules 缺失"
  fi
done
echo ""

# T4: API Key 真实值
echo "T4: API Key 真实值 (6 铁律 #5 完整值传递)"
KEYS=("H3973L93M5" "b2a00f88-3a8d-40d0-b148-1f1db92e10b7" "support@techidaily.com")
for k in "${KEYS[@]}"; do
  if [[ -f docs/master-rules-from-frodo.md ]] && grep -q "$k" docs/master-rules-from-frodo.md; then
    ok "API Key 真实值: $k 在 master-rules"
  else
    ko "API Key 真实值: $k" "master-rules 缺失"
  fi
done
echo ""

# T5: daily-report.sh broadcast 段
echo "T5: daily-report.sh broadcast 段 + skip dup"
if [[ -f scripts/daily-report.sh ]]; then
  if grep -q "17:23 拍板: 0:00 必 send to:All 6 铁律 broadcast" scripts/daily-report.sh; then
    ok "broadcast 段存在"
  else
    ko "broadcast 段" "daily-report.sh 缺失"
  fi
  if grep -q "fromisoformat" scripts/daily-report.sh; then
    ok "datetime filter (修字符串比较 bug)"
  else
    ko "datetime filter" "daily-report.sh 缺失"
  fi
  if grep -q "|| true" scripts/daily-report.sh; then
    ok "check-placeholders || true (avoid pipefail 提前退出)"
  else
    ko "check-placeholders || true" "daily-report.sh 缺失"
  fi
fi
echo ""

# T6: check-placeholders.sh 0 错
echo "T6: check-placeholders.sh 0 错 (全名检查)"
if [[ -x scripts/check-placeholders.sh ]]; then
  CP_OUT=$(bash scripts/check-placeholders.sh 2>&1)
  if echo "$CP_OUT" | grep -q "全清"; then
    ok "check-placeholders: 全清"
  else
    ko "check-placeholders" "$(echo "$CP_OUT" | grep '❌' | head -1)"
  fi
else
  ko "T6" "check-placeholders.sh 不可执行"
fi
echo ""

# T7: check-fake-values.sh 0 错
echo "T7: check-fake-values.sh 0 错 (真值检查)"
if [[ -x scripts/check-fake-values.sh ]]; then
  CF_OUT=$(bash scripts/check-fake-values.sh 2>&1)
  if echo "$CF_OUT" | grep -q "无假值/占位符"; then
    ok "check-fake-values: 无假值/占位符"
  else
    ko "check-fake-values" "$(echo "$CF_OUT" | grep '❌' | head -1)"
  fi
else
  ko "T7" "check-fake-values.sh 不可执行"
fi
echo ""

# T8: 抽查 8 问答案都在 master-rules
echo "T8: 抽查 8 问答案都在 master-rules"
if [[ -f docs/master-rules-from-frodo.md ]]; then
  # Q1: 6 铁律
  if grep -q "抽查问题 1" docs/master-rules-from-frodo.md && grep -q "6 铁律" docs/master-rules-from-frodo.md; then
    ok "抽查 Q1: 6 铁律 (在 master-rules § 抽查必答清单)"
  else
    ko "抽查 Q1" "缺失"
  fi
  # Q2: ASC 协议
  if grep -q "抽查问题 2" docs/master-rules-from-frodo.md; then
    ok "抽查 Q2: ASC 协议 (在 master-rules § 抽查必答清单)"
  else
    ko "抽查 Q2" "缺失"
  fi
  # Q3: 4 仓库
  if grep -q "抽查问题 3" docs/master-rules-from-frodo.md; then
    ok "抽查 Q3: 4 仓库 (在 master-rules § 抽查必答清单)"
  else
    ko "抽查 Q3" "缺失"
  fi
  # Q4: API Key
  if grep -q "抽查问题 4" docs/master-rules-from-frodo.md; then
    ok "抽查 Q4: API Key 真实值 (在 master-rules § 抽查必答清单)"
  else
    ko "抽查 Q4" "缺失"
  fi
  # Q5: altool
  if grep -q "抽查问题 5" docs/master-rules-from-frodo.md; then
    ok "抽查 Q5: altool 命令 (在 master-rules § 抽查必答清单)"
  else
    ko "抽查 Q5" "缺失"
  fi
  # Q6: 昨天干了什么
  if grep -q "抽查问题 6" docs/master-rules-from-frodo.md; then
    ok "抽查 Q6: 昨天干了什么 (在 master-rules § 抽查必答清单)"
  else
    ko "抽查 Q6" "缺失"
  fi
  # Q7: 14:00 误判
  if grep -q "抽查问题 7" docs/master-rules-from-frodo.md; then
    ok "抽查 Q7: 14:00 误判失联 (在 master-rules § 抽查必答清单)"
  else
    ko "抽查 Q7" "缺失"
  fi
  # Q8: 16:18+16:27+16:39 拍板
  if grep -q "抽查问题 8" docs/master-rules-from-frodo.md; then
    ok "抽查 Q8: 16:18+16:27+16:39 拍板 (在 master-rules § 抽查必答清单)"
  else
    ko "抽查 Q8" "缺失"
  fi
fi
echo ""

# 总结
echo "═══════════════════════════════════════════════════════════════"
TOTAL=$((PASS + FAIL))
if [[ $FAIL -eq 0 ]]; then
  echo -e "  ${GREEN}🏁 ALL PASS: $PASS/$TOTAL${NC}"
else
  echo -e "  ${RED}❌ FAIL: $FAIL/$TOTAL${NC}"
  for e in "${ERRORS[@]}"; do
    echo -e "  ${RED}  - $e${NC}"
  done
  exit 1
fi
echo "═══════════════════════════════════════════════════════════════"
echo "  维护: Katherine-E2wa1m (Tier 1 调度员, 4 仓库专项管理, 17:23 拍板)"
echo "═══════════════════════════════════════════════════════════════"
