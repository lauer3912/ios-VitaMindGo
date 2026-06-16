#!/usr/bin/env bash
# content-checklist.sh v1.0 — agent-bus 发内容前必跑 checklist (佛老爷 10:48 拍板)
# 目的: 防止低级错误 (SSH 命令错 / 简写 / 占位符 / 失职)
# 触发:
#   1. agent-bus.sh send 前自动调 (集成)
#   2. 任何 pre-commit 前调 (集成)
#   3. daily-report + midday cron 调 (双复盘)
#   4. 手动: bash scripts/content-checklist.sh <file_or_text>
#
# 8 项 check:
#   C1: SSH 方式 (per SOP §0.2.3) — 不能 192.168.1.9
#   C2: AGENT_ID 全名 (6 铁律 #6) — 不能 Katherine-E2wa1m / Katherine-yl2rKS 简写
#   C3: 完整值传递 (6 铁律 #5) — 不能 <placeholder> / xxx
#   C4: 永久可查 (6 铁律 #4) — commit hash / comment id 必引用
#   C5: ASC 协议已签 (16:27 拍板) — 不能说"ASC 协议没签" 当阻塞
#   C6: 真实命令 (ssh -o StrictHostKeyChecking=no + ssh macmini / 47.77.237.73)
#   C7: 不发送密钥文件 (.p8 / .pem / private key 内容)
#   C8: 不冒充 Agent (只能 from: 自己 AGENT_ID, --impersonate 是 admin/test)

# 用法:
#   bash scripts/content-checklist.sh <file>
#   bash scripts/content-checklist.sh -     # 读 stdin
#   bash scripts/content-checklist.sh --auto-fix   # 自动修 (SSH + 简写), 其他 flag
#
# 维护: Katherine-E2wa1m (Tier 1 调度员, 4 仓库专项管理)

set -u

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS=0
FAIL=0
WARN=0
ERRORS=()
AUTO_FIX=0

# Self-skip: content-checklist.sh 自身含规则示例 (ASC 协议 / placeholder / private key 提示), 跳过
SELF_SKIP=false
if [[ "${1:-}" == "--self-skip" ]]; then
  SELF_SKIP=true
  shift
fi

ok()   { PASS=$((PASS+1)); echo -e "  ${GREEN}✅ C$1: $2${NC}"; }
warn() { WARN=$((WARN+1)); echo -e "  ${YELLOW}⚠️  C$1: $2${NC}"; }
ko()   { FAIL=$((FAIL+1)); ERRORS+=("C$1: $2"); echo -e "  ${RED}❌ C$1: $2${NC}"; }

# Auto-fix flag
if [[ "${1:-}" == "--auto-fix" ]]; then
  AUTO_FIX=1
  shift
fi

# Read input
if [[ $# -gt 0 && -f "$1" ]]; then
  # Self-skip: 如果检的是 content-checklist.sh 自身, 跳过 (规则示例触发)
  if [[ "$SELF_SKIP" == "true" ]] && [[ "$(basename "$1")" == "content-checklist.sh" ]]; then
    echo "⏭️  self-skip: content-checklist.sh 自身 (含规则示例, 触发自身)"
    exit 0
  fi
  CONTENT=$(cat "$1")
elif [[ "${1:-}" == "-" ]]; then
  CONTENT=$(cat)
elif [[ $# -gt 0 ]]; then
  CONTENT="$1"
else
  echo "用法: $0 <file_or_text> [--auto-fix] [--self-skip]" >&2
  exit 1
fi

echo "═══════════════════════════════════════════════════════════════"
echo "  🧪 content-checklist.sh v1.0 (佛老爷 10:48 拍板)"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# === C1: SSH 方式 (per SOP §0.2.3) ===
# 错: ssh user291981@192.168.1.9 (内网 IP, Ubuntu 云端不通)
# 对: ssh macmini (alias) 或 ssh user291981@47.77.237.73 -p 2222
if echo "$CONTENT" | grep -qE 'ssh[^"]*user291981@192\.168\.1\.9|ssh[^"]*192\.168\.1\.9'; then
  if [[ $AUTO_FIX -eq 1 ]]; then
    NEW_CONTENT=$(echo "$CONTENT" | sed -E 's|ssh([^"]*)user291981@192\.168\.1\.9|ssh\1macmini|g; s|192\.168\.1\.9|47.77.237.73:2222 (cloudflared 穿透)|g')
    CONTENT="$NEW_CONTENT"
    # Verify auto-fix 成功
    if echo "$CONTENT" | grep -qE 'ssh[^"]*user291981@192\.168\.1\.9|ssh[^"]*192\.168\.1\.9'; then
      ko "1" "SSH 命令含 192.168.1.9, auto-fix 失败, 手动修"
    else
      ok 1 "SSH 命令含 192.168.1.9 已自动替换为 ssh macmini (auto-fix)"
    fi
  else
    ko "1" "SSH 命令含 192.168.1.9 内网 IP (Ubuntu 云端走不通). 用 ssh macmini 或 ssh user291981@47.77.237.73 -p 2222 (per SOP §0.2.3). 加 --auto-fix 自动修"
  fi
else
  ok 1 "SSH 方式 OK (无 192.168.1.9 内网 IP)"
fi

# === C2: AGENT_ID 全名 (6 铁律 #6) ===
# 错: Katherine-E2wa1m / Katherine-yl2rKS / Katherine2 / K-9L6
# 对: Katherine-E2wa1m / Katherine-yl2rKS
SHORT_K_E=$(echo "$CONTENT" | grep -cE '\bK-E2wa1m\b' || true)
SHORT_K_Y=$(echo "$CONTENT" | grep -cE '\bK-yl2rKS\b' || true)
SHORT_K2=$(echo "$CONTENT" | grep -cE '\bKatherine2\b|\bK-9L6\b' || true)
TOTAL_SHORT=$((SHORT_K_E + SHORT_K_Y + SHORT_K2))
if [[ $TOTAL_SHORT -gt 0 ]]; then
  if [[ $AUTO_FIX -eq 1 ]]; then
    NEW_CONTENT=$(echo "$CONTENT" | sed -E 's|\bK-E2wa1m\b|Katherine-E2wa1m|g; s|\bK-yl2rKS\b|Katherine-yl2rKS|g')
    CONTENT="$NEW_CONTENT"
    # Verify auto-fix 成功
    SHORT_AFTER_E=$(echo "$CONTENT" | grep -cE '\bK-E2wa1m\b' || true)
    SHORT_AFTER_Y=$(echo "$CONTENT" | grep -cE '\bK-yl2rKS\b' || true)
    if [[ $SHORT_AFTER_E -eq 0 && $SHORT_AFTER_Y -eq 0 ]]; then
      ok 2 "AGENT_ID 简写 $TOTAL_SHORT 处 已自动替换全名 (auto-fix)"
    else
      ko "2" "AGENT_ID 简写 auto-fix 失败, 手动修"
    fi
  else
    ko "2" "AGENT_ID 简写 $TOTAL_SHORT 处 (Katherine-E2wa1m $SHORT_K_E / Katherine-yl2rKS $SHORT_K_Y). 6 铁律 #6 必全名. 加 --auto-fix 自动修"
  fi
else
  ok 2 "AGENT_ID 全名 OK (无 Katherine-E2wa1m / Katherine-yl2rKS 简写)"
fi

# === C3: 完整值传递 (6 铁律 #5) ===
# 错: <placeholder> / <xxx> / xxx@ / YOUR_ / ghp_xxx
if echo "$CONTENT" | grep -qE '<placeholder>|<xxx>|<YOUR_|<your_|\bghp_xxx'; then
  ko "3" "占位符 (<placeholder> / <xxx> / <your_>) 出现. 15:36 拍板 占位符 = Kill. 用真实值"
else
  ok 3 "完整值传递 OK (无占位符)"
fi

# === C4: 永久可查 (6 铁律 #4) ===
# 检查引用 issue #N + commit hash 至少 1 处 (按上下文判断)
if echo "$CONTENT" | grep -qE '#[0-9]{2,}|commit [a-f0-9]{7,}|comment [0-9]{10,}'; then
  ok 4 "永久可查 OK (引用 #N / commit hash / comment id)"
else
  warn "4" "未引用 #N / commit hash / comment id. 6 铁律 #4 永久可查建议加"
fi

# === C5: ASC 协议已签 (16:27 拍板) ===
if echo "$CONTENT" | grep -qiE 'ASC.*协议.*没签|协议.*未签|ASC.*协议.*未签'; then
  ko "5" "ASC 协议永远 = 已签 (16:27 拍板). 不允许把'ASC 协议没签' 当阻塞 / 原因 / 障碍"
else
  ok 5 "ASC 协议 OK (未当阻塞)"
fi

# === C6: 真实命令 (SSH + cert / key 完整) ===
# 检查 SSH 命令有 user / host
if echo "$CONTENT" | grep -qE '^[[:space:]]*ssh[[:space:]]'; then
  # 有 ssh 命令, 检查是否含 user@host 或 alias
  if echo "$CONTENT" | grep -qE 'ssh[[:space:]]+[a-zA-Z][a-zA-Z0-9_-]*(@|@.*\.)|ssh[[:space:]]+[a-zA-Z][a-zA-Z0-9_-]*[[:space:]]'; then
    ok 6 "SSH 命令 OK (含 user@host 或 alias)"
  else
    warn "6" "SSH 命令格式可疑 (无 user@host 或 alias), 检查格式"
  fi
else
  ok 6 "无 SSH 命令, 跳过"
fi

# === C7: 不发送密钥文件 ===
# C7 修复 (Tick 11:23): 只匹配 PEM 内容, 不匹配路径 (AuthKey_*.p8 是路径引用, 不是文件内容)
  if echo "$CONTENT" | grep -qE '-----BEGIN [A-Z ]*PRIVATE KEY-----|-----BEGIN [A-Z ]*PRIVATE KEY$'; then
  ko "7" "内容含 private key / p8 文件内容, **不**应发送. 用路径引用 ~/.appstoreconnect/private_keys/AuthKey_*.p8"
else
  ok 7 "无密钥文件内容 (用路径引用)"
fi

# === C8: 不冒充 Agent (只能 from: 自己 AGENT_ID) ===
# 内容含 from: 字段
if echo "$CONTENT" | grep -qE 'from:[A-Za-z0-9_-]+'; then
  FROM_FIELD=$(echo "$CONTENT" | grep -oE 'from:[A-Za-z0-9_-]+' | head -1 | sed 's|from:||')
  MY_AGENT_ID="${AGENT_ID:-Katherine-E2wa1m}"
  if [[ "$FROM_FIELD" == "$MY_AGENT_ID" ]]; then
    ok 8 "from: 字段 OK ($FROM_FIELD = 自己)"
  else
    warn "8" "from: 字段 ($FROM_FIELD) != 自己 ($MY_AGENT_ID), 检查 --impersonate 是否 admin/test"
  fi
else
  ok 8 "无 from: 字段 (默认自己), 跳过"
fi

# 总结
echo ""
echo "═══════════════════════════════════════════════════════════════"
TOTAL=$((PASS + FAIL + WARN))
if [[ $FAIL -eq 0 ]]; then
  echo -e "  ${GREEN}🏁 PASS: $PASS / $TOTAL (FAIL: $FAIL, WARN: $WARN)${NC}"
  echo "═══════════════════════════════════════════════════════════════"
  if [[ $AUTO_FIX -eq 1 ]]; then
    # 输出修后内容 (供 agent-bus send 用)
    echo "$CONTENT"
  fi
  exit 0
else
  echo -e "  ${RED}❌ FAIL: $FAIL / $TOTAL (PASS: $PASS, WARN: $WARN)${NC}"
  for e in "${ERRORS[@]}"; do
    echo -e "  ${RED}  - $e${NC}"
  done
  echo "═══════════════════════════════════════════════════════════════"
  echo -e "  ${YELLOW}修法: 加 --auto-fix 自动修 SSH + 简写, 其他手动修${NC}"
  exit 1
fi
