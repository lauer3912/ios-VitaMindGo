#!/bin/bash
# check-cron-installed.sh — 5 层防护 #7, 守护 agent-bus cron 不漏装
# 用途: 每 30 min 跑一次 (cron 守护), daily-report 跑 (0:00 + 12:00)
# 教训: 2026-06-15 22:19 Katherine-yl2rKS 报 last_seen 13h 前, 实际我 (Katherine-E2wa1m) crontab 0 lines. 22:47 才装, 太晚
# 23:16 cron 守护: 漏装 → 静默补装 (不打扰), 持续漏 → 5 min 后重试

set -u

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE="$(cd "$SCRIPT_DIR/.." && pwd)"

POLL_SH="$WORKSPACE/scripts/agent-bus-poll.sh"
WATCH_SH="$WORKSPACE/scripts/agent-bus-watch.sh"

ERRORS=0
WARN=0

# 1. crontab 是否有 agent-bus-poll.sh
HAS_POLL=$(crontab -l 2>/dev/null | grep -c "agent-bus-poll.sh" || true)
if [ "${HAS_POLL:-0}" -lt 1 ]; then
  echo -e "${RED}❌ agent-bus-poll.sh cron 漏装${NC}"
  ERRORS=$((ERRORS + 1))
else
  echo -e "${GREEN}✅ agent-bus-poll.sh cron 装着${NC}"
fi

# 2. crontab 是否有 agent-bus-watch.sh (v2.3)
HAS_WATCH=$(crontab -l 2>/dev/null | grep -c "agent-bus-watch.sh" || true)
if [ "${HAS_WATCH:-0}" -lt 1 ]; then
  echo -e "${YELLOW}⚠️  agent-bus-watch.sh cron 漏装 (v2.3, 可选)${NC}"
  WARN=$((WARN + 1))
else
  echo -e "${GREEN}✅ agent-bus-watch.sh cron 装着${NC}"
fi

# 3. crontab 是否有 cron 守护自身 (防止 check-cron-installed.sh 也漏装)
HAS_SELF=$(crontab -l 2>/dev/null | grep -c "check-cron-installed.sh" || true)
if [ "${HAS_SELF:-0}" -lt 1 ]; then
  echo -e "${YELLOW}⚠️  check-cron-installed.sh cron 守护未装 (建议装)${NC}"
  WARN=$((WARN + 1))
fi

# 4. cron daemon 跑中?
CRON_RUNNING=$(ps -ef | grep -c "[/]usr/sbin/cron" || true)
if [ "${CRON_RUNNING:-0}" -lt 1 ]; then
  echo -e "${RED}❌ cron daemon 没跑${NC}"
  ERRORS=$((ERRORS + 1))
else
  echo -e "${GREEN}✅ cron daemon 跑中${NC}"
fi

# 5. 静默补装 (非交互): poll cron 漏装时自动补
if [ "${HAS_POLL:-0}" -lt 1 ] && [ -f "$POLL_SH" ]; then
  echo ""
  echo -e "${YELLOW}🔧 静默补装 agent-bus-poll.sh cron (5 min tick)...${NC}"
  CRON_LINE="*/5 * * * * $POLL_SH >> $HOME/.local/share/agent-bus/poll.log 2>&1"
  (crontab -l 2>/dev/null; echo "$CRON_LINE") | crontab -
  echo -e "${GREEN}✅ 已装: $CRON_LINE${NC}"
  ERRORS=$((ERRORS - 1))  # 装上后扣回
fi

# 6. 静默补装 watch cron (非交互)
if [ "${HAS_WATCH:-0}" -lt 1 ] && [ -f "$WATCH_SH" ]; then
  echo ""
  echo -e "${YELLOW}🔧 静默补装 agent-bus-watch.sh cron (3 min tick)...${NC}"
  CRON_LINE="*/3 * * * * $WATCH_SH >> $HOME/.local/share/agent-bus/watch.log 2>&1"
  (crontab -l 2>/dev/null; echo "$CRON_LINE") | crontab -
  echo -e "${GREEN}✅ 已装: $CRON_LINE${NC}"
  WARN=$((WARN - 1))
fi

# 7. 加 cron 守护 (每 30 min 跑 check-cron-installed.sh)
if [ "${HAS_SELF:-0}" -lt 1 ]; then
  echo ""
  echo -e "${YELLOW}🔧 加 cron 守护 (30 min tick, 守 cron 不漏装)...${NC}"
  CRON_LINE="*/30 * * * * $SCRIPT_DIR/check-cron-installed.sh >> $HOME/.local/share/agent-bus/cron-guard.log 2>&1"
  (crontab -l 2>/dev/null; echo "$CRON_LINE") | crontab -
  echo -e "${GREEN}✅ 已装: $CRON_LINE${NC}"
fi

echo ""
echo "--- 总结 ---"
if [ $ERRORS -gt 0 ]; then
  echo -e "${RED}❌ $ERRORS 个 cron 错${NC}"
  exit 1
fi
if [ $WARN -gt 0 ]; then
  echo -e "${YELLOW}⚠️  $WARN 个 cron 警告 (已尝试补装)${NC}"
fi
echo -e "${GREEN}✅ cron 健康${NC}"
exit 0
