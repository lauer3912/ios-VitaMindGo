#!/bin/bash
# ========================================
# OpenClaw: GitHub Credential 一键设置 (新 Ubuntu 入职用)
# ========================================
# 用法 (3 选 1):
#   GITHUB_TOKEN="$YOUR_GITHUB_PAT" bash setup-github-cred.sh   # 从 env (推荐 CI/自动化, $YOUR_GITHUB_PAT 是你的真实 GitHub PAT)
#   bash setup-github-cred.sh $YOUR_GITHUB_PAT                  # 从第 1 个位置参数 (实参 = 你的真实 GitHub PAT)
#   bash setup-github-cred.sh                          # 交互式 prompt
#
# 前置:
#   老爷先去 https://github.com/settings/tokens 生成 PAT
#   需要 'repo' 权限 (经典 token 即可, 90 天到期)
#
# 作用:
#   1. git config --global credential.helper store
#   2. 写 https://x-access-token:TOKEN@github.com 到 ~/.git-credentials
#   3. chmod 600 (敏感)
#   4. 测试 git ls-remote 验证认证
#
# 跟 onboard-new-ubuntu.sh 集成:
#   onboard Step 2.5/8 在 clone 仓库前自动调
#
# 轮换: token 90 天到期前, 老爷去 https://github.com/settings/tokens 重生成,
#        然后改本脚本 DEFAULT_GITHUB_TOKEN 常量, 重 push
# ========================================

set -euo pipefail

# --- 0. 默认 token (团队共享, 佛老爷 2026-06-08 拍板 "不用担心安全问题") ---
DEFAULT_GITHUB_TOKEN="GH_TOKEN=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"
DEFAULT_GITHUB_USER="lauer3912"

# --- 1. 拿 token (4 优先级: arg > env > --prompt > 强制交互) ---
if [ "${1:-}" = "--prompt" ]; then
    GITHUB_TOKEN=""
    shift
else
    GITHUB_TOKEN="${1:-${GITHUB_TOKEN:-${DEFAULT_GITHUB_TOKEN:-}}}"
fi
GITHUB_USER="${GITHUB_USER:-$DEFAULT_GITHUB_USER}"

# --- 2. (合并进步骤 1, GITHUB_USER 已在上面设) ---

# --- 3. 拿不到 token, 交互式 prompt (仅 --prompt 模式) ---
if [ -z "$GITHUB_TOKEN" ]; then
    echo "════════════════════════════════════════════════"
    echo "  OpenClaw: GitHub Credential 一键设置"
    echo "════════════════════════════════════════════════"
    echo ""
    echo "请粘贴 GitHub Personal Access Token (PAT):"
    echo "  1. 老爷去 https://github.com/settings/tokens 生成"
    echo "  2. 选 'Generate new token (classic)'"
    echo "  3. Scopes 勾 'repo' (Full control of private repositories)"
    echo "  4. 复制 16 位 token 粘到下面 (输入是隐藏的, 可直接粘贴)"
    echo ""
    echo "💡 传 token = 覆盖默认"
    echo "💡 不传 + 直接 Enter = 用默认 (团队共享 token)"
    echo "💡 bash setup-github-cred.sh --prompt = 强制提示"
    echo ""
    echo "按 Ctrl+C 退出"
    echo ""
    read -r -s -p "GitHub PAT (回车接受默认): " GITHUB_TOKEN
    echo

    # 空回车 = 用默认
    if [ -z "$GITHUB_TOKEN" ]; then
        GITHUB_TOKEN="$DEFAULT_GITHUB_TOKEN"
        echo "  (使用脚本默认 token: $DEFAULT_GITHUB_TOKEN)"
    fi
fi

# --- 4. 基础格式校验 (警告不报错) ---
if [[ "$GITHUB_TOKEN" =~ ^ghp_[a-zA-Z0-9]{36}$ ]]; then
    TOKEN_TYPE="classic"
elif [[ "$GITHUB_TOKEN" =~ ^github_pat_[a-zA-Z0-9_]{82}$ ]]; then
    TOKEN_TYPE="fine-grained"
else
    echo "⚠️  Token 格式不像标准 GitHub PAT (ghp_... 或 github_pat_...)"
    echo "   继续写入, 但认证可能失败, 验证步骤会暴露"
    TOKEN_TYPE="unknown"
fi
echo "  Token 类型: $TOKEN_TYPE"

# --- 5. 写 git credential helper ---
git config --global credential.helper store
echo "✅ git config --global credential.helper store"

# --- 6. 写 ~/.git-credentials ---
mkdir -p "$HOME"  # ensure HOME exists (always true, 但保险)
echo "https://x-access-token:${GITHUB_TOKEN}@github.com" > "$HOME/.git-credentials"
chmod 600 "$HOME/.git-credentials"
echo "✅ ~/.git-credentials written (mode 600, 8 字节权限)"

# --- 7. 测试连接 ---
echo ""
echo "=== 测试连接 (用 token 访问 ${GITHUB_USER} 仓库) ==="
TEST_REPO="${GITHUB_USER}/openclaw-portable-template"
TEST_URL="https://github.com/${TEST_REPO}.git"

if OUTPUT=$(git ls-remote "$TEST_URL" HEAD 2>&1); then
    HEAD_SHA=$(echo "$OUTPUT" | head -1 | awk '{print $1}')
    echo "✅ 认证成功!"
    echo "   URL: $TEST_URL"
    echo "   HEAD: ${HEAD_SHA:0:12}..."
else
    echo "❌ 认证失败:"
    echo "$OUTPUT" | head -5
    echo ""
    echo "排查:"
    echo "  1. Token 是否对 (去 https://github.com/settings/tokens 检查)"
    echo "  2. Token 有 'repo' 权限 (classic) 或对应 repo 访问 (fine-grained)"
    echo "  3. Token 没过期 (默认 90 天)"
    echo "  4. GITHUB_USER 是否对 (现在: $GITHUB_USER, 期望: 您的用户名)"
    exit 1
fi

# --- 8. 报告 ---
echo ""
echo "════════════════════════════════════════════════"
echo "  ✅ GitHub Credential 设置完成"
echo "════════════════════════════════════════════════"
echo "  Token 类型: $TOKEN_TYPE"
echo "  GitHub 用户: $GITHUB_USER"
echo "  凭证文件: $HOME/.git-credentials (mode 600)"
echo "  git config: credential.helper = store"
echo ""
echo "  之后这台 Ubuntu 跑 'git clone/push/pull' 都自动用这个 token"
echo "  验证: git clone https://github.com/${GITHUB_USER}/SOME_REPO.git"
echo ""
echo "💡 Token 轮换: 90 天到期前, 重新跑本脚本即可 (会覆盖旧 token)"
echo ""
