#!/bin/bash
# ========================================
# OpenClaw Agent 健康检查脚本
# ========================================
# 用途:
#   - 入职后检验 Agent 是否完整可用
#   - 平时做健康检查
#   - 故障排查第一步
#
# 用法:
#   bash verify-agent.sh
#   bash verify-agent.sh /path/to/workspace
#
# 输出:
#   - 各项 PASS/FAIL
#   - 总结 + 失败项列表
#   - 退出码 0=全过, 1=有失败
# ========================================
set -uo pipefail

WS="${1:-$HOME/.openclaw/workspace}"
PASS=0
FAIL=0
ERRORS=()

check() {
  local desc="$1"
  local cmd="$2"
  if eval "$cmd" >/dev/null 2>&1; then
    echo "  ✅ $desc"
    PASS=$((PASS + 1))
  else
    echo "  ❌ $desc"
    FAIL=$((FAIL + 1))
    ERRORS+=("$desc")
  fi
}

echo "════════════════════════════════════════════"
echo "  OpenClaw Agent 健康检查"
echo "  workspace: $WS"
echo "════════════════════════════════════════════"
echo ""

# 1. 环境依赖
echo "【1】环境依赖"
check "Node.js >= 24" "[ -n \"\$(command -v node)\" ] && [ \"\$(node -v | cut -d. -f1 | tr -d v)\" -ge 24 ]"
check "git 已装" "command -v git >/dev/null"
check "curl 已装" "command -v curl >/dev/null"
check "jq 已装" "command -v jq >/dev/null"
check "rsync 已装" "command -v rsync >/dev/null"
check "flock 已装" "command -v flock >/dev/null"

# 2. 核心文件
echo ""
echo "【2】5 个核心 .md 文件"
for f in AGENTS.md SOUL.md IDENTITY.md USER.md MEMORY.md; do
  check "$f 存在" "[ -f \"$WS/$f\" ]"
done
check "MANIFEST.yaml 存在" "[ -f \"$WS/MANIFEST.yaml\" ]"

# 3. 灵魂块标记
echo ""
echo "【3】灵魂文件块注入"
for f in AGENTS.md SOUL.md IDENTITY.md USER.md; do
  if [ -f "$WS/$f" ]; then
    cnt=$(grep -c "openclaw-block" "$WS/$f" 2>/dev/null || echo 0)
    if [ "$cnt" -ge 2 ]; then
      echo "  ✅ $f: $cnt 个块"
      PASS=$((PASS + 1))
    else
      echo "  ❌ $f: 只有 $cnt 个块 (预期 ≥ 2)"
      FAIL=$((FAIL + 1))
      ERRORS+=("$f 块数不足")
    fi
  else
    echo "  ❌ $f 不存在"
    FAIL=$((FAIL + 1))
    ERRORS+=("$f 缺失")
  fi
done

# 4. 核心脚本
echo ""
echo "【4】核心脚本 (存在 + 可执行)"
for s in inject-blocks.sh sync-from-template.sh check-template-version.sh \
         setup-github-cred.sh setup-ubuntu-ssh-client.sh sop-822-check.sh \
         restore-from-backup.sh; do
  check "$s" "[ -x \"$WS/scripts/$s\" ]"
done

# 5. 同步状态
echo ""
echo "【5】同步状态"
if [ -f "$WS/.template-version" ]; then
  ver=$(cat "$WS/.template-version")
  echo "  ✅ 本地版本: $ver"
  PASS=$((PASS + 1))
else
  echo "  ❌ .template-version 不存在"
  FAIL=$((FAIL + 1))
  ERRORS+=(".template-version 缺失")
fi

# 6. GitHub 认证 (从 setup-github-cred.sh 拿 token)
echo ""
echo "【6】GitHub 认证"
TOKEN=$(grep "DEFAULT_GITHUB_TOKEN=" "$WS/scripts/setup-github-cred.sh" 2>/dev/null | head -1 | awk -F'"' '{print $2}')
# 06-15 17:53 佛老爷拍板: 严禁占位符 (15:36 #15 + 17:46)
# 不再与占位符 ghp_*** 比较, 直接检查非空 + 长度合理
if [ -n "$TOKEN" ] && [ "${#TOKEN}" -ge 20 ]; then
  if curl -fsSL --max-time 10 -H "Authorization: token $TOKEN" \
     https://api.github.com/user 2>/dev/null | grep -q '"login"'; then
    login=$(curl -fsSL --max-time 10 -H "Authorization: token $TOKEN" \
      https://api.github.com/user 2>/dev/null | grep -oE '"login": "[^"]+"' | head -1)
    echo "  ✅ $login"
    PASS=$((PASS + 1))
  else
    echo "  ❌ GitHub 认证失败 (token 错或过期)"
    FAIL=$((FAIL + 1))
    ERRORS+=("GitHub 认证失败")
  fi
else
  echo "  ⚠️  找不到 token, 跳过"
fi

# 7. Cron 任务
echo ""
echo "【7】Cron 任务"
if command -v openclaw >/dev/null 2>&1; then
  if openclaw cron list 2>/dev/null | grep -q "sync-template-6am"; then
    echo "  ✅ sync-template-6am 已注册"
    PASS=$((PASS + 1))
  else
    echo "  ❌ sync-template-6am 未注册"
    FAIL=$((FAIL + 1))
    ERRORS+=("sync-template-6am 未注册")
  fi
else
  echo "  ⚠️  openclaw CLI 不存在, 跳过"
fi

# 8. USER.md 填写情况
echo ""
echo "【8】USER.md 填写"
if [ -f "$WS/USER.md" ]; then
  if grep -q "^name: [^<\"]" "$WS/USER.md" 2>/dev/null; then
    user_name=$(grep "^name:" "$WS/USER.md" | head -1 | sed 's/name:[[:space:]]*//')
    echo "  ✅ USER.md 已填 (name: $user_name)"
    PASS=$((PASS + 1))
  else
    echo "  ⚠️  USER.md 未填 (Onboarding 7 块待填)"
  fi
fi

# 总结
echo ""
echo "════════════════════════════════════════════"
echo "  通过: $PASS / 失败: $FAIL"
echo "════════════════════════════════════════════"

if [ $FAIL -gt 0 ]; then
  echo ""
  echo "❌ 失败项清单:"
  for e in "${ERRORS[@]}"; do
    echo "  - $e"
  done
  echo ""
  echo "💡 常见修复:"
  echo "  - 灵魂文件缺失: bash $WS/scripts/inject-blocks.sh"
  echo "  - 脚本缺失: 重跑 install.sh"
  echo "  - cron 未注册: openclaw cron add sync-template-6am ..."
  echo "  - token 错: 重新跑 setup-github-cred.sh"
  exit 1
fi

echo ""
echo "🎉 Agent 完全健康!"