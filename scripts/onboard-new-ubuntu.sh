#!/bin/bash
# ========================================
# OpenClaw: 新 Ubuntu agent 一键入职 (5 分钟)
# ========================================
# 用法: sudo bash onboard-new-ubuntu.sh <server_tag>
# 作用: 在一台全新的 Ubuntu 上, 一键完成所有入职配置
# 前置: 
#   1. 老爷已给本 Ubuntu 授权 GitHub (PAT 或 SSH key)
#   2. 本机能访问 internet
# ========================================

set -euo pipefail

# --- 参数检查 ---
if [ $# -ne 1 ]; then
  echo "Usage: $0 <server_tag>"
  echo "  server_tag: 本机唯一标识 (alpha/beta/gamma/...)"
  exit 1
fi

SERVER_TAG="$1"
GITHUB_REPO="lauer3912/openclaw-portable-template"
# 装到 agent workspace 下子目录, 不污染 OpenClaw 自身 config
INSTALL_DIR="$HOME/.openclaw/workspace/openclaw-portables"

echo "════════════════════════════════════════════════"
echo "  OpenClaw: 新 Ubuntu agent 入职"
echo "  Tag: $SERVER_TAG"
echo "════════════════════════════════════════════════"
echo ""

# --- 1. 系统检查 ---
echo "=== [1/8] 系统检查 ==="
if [ "$(uname -s)" != "Linux" ]; then
  echo "❌ 不是 Linux 系统"
  exit 1
fi
if ! grep -q "Ubuntu" /etc/os-release 2>/dev/null; then
  echo "⚠️  不是 Ubuntu (但可能也能跑)"
fi
echo "✅ OS: $(uname -s) $(uname -r)"

# --- 2. 安装基础依赖 ---
echo ""
echo "=== [2/8] 安装基础依赖 ==="
sudo apt update -qq
sudo apt install -y git curl wget openssh-client python3 2>&1 | tail -3
echo "✅ 基础依赖已装"

# --- 3. Clone private 仓库 ---
echo ""
echo "=== [3/8] Clone 模板仓库 (private) ==="
echo "  仓库: $GITHUB_REPO"
echo "  路径: $INSTALL_DIR"

# 智能跳过: 如果脚本本身已经在 $INSTALL_DIR, 说明 user 手动 clone 过, 跳过
if [ -f "$INSTALL_DIR/scripts/onboard-new-ubuntu.sh" ]; then
  echo "  ⏭️  检测到脚本已在 $INSTALL_DIR, 跳过 clone (user 手动 clone 过)"
else
  # 尝试 SSH 方式
  if ssh -T -o ConnectTimeout=5 git@github.com 2>&1 | grep -q "successfully authenticated"; then
    echo "  用 SSH 方式 clone..."
    git clone "git@github.com:${GITHUB_REPO}.git" "$INSTALL_DIR"
  else
    # 退到 PAT 方式
    echo "  SSH 认证未配置, 需 PAT"
    if [ -z "${GITHUB_TOKEN:-}" ]; then
      echo "❌ 未设置 GITHUB_TOKEN 环境变量"
      echo "   设置: export GITHUB_TOKEN=<token>"
      echo "   或先在 GitHub 添加本机 SSH 公钥"
      exit 1
    fi
    echo "  用 PAT 方式 clone..."
    git clone "https://lauer3912:${GITHUB_TOKEN}@github.com/${GITHUB_REPO}.git" "$INSTALL_DIR"
    # 存凭据, 避免每次都输
    git config --global credential.helper store
  fi
fi
echo "✅ 仓库已 clone"

# --- 4. 验证关键文件 ---
echo ""
echo "=== [4/8] 验证关键文件 ==="
KEY_FILES=(
  "$INSTALL_DIR/docs/SOP-iOS-Ubuntu-Development.md"
  "$INSTALL_DIR/scripts/setup-ubuntu-ssh-client.sh"
  "$INSTALL_DIR/scripts/ssh-macmini-build.sh"
  "$INSTALL_DIR/examples/.github/workflows/ios-verify.yml"
)

for f in "${KEY_FILES[@]}"; do
  if [ -f "$f" ]; then
    echo "  ✅ $(basename $f) ($(wc -l < $f) 行)"
  else
    echo "  ❌ 缺失: $f"
    exit 1
  fi
done

# --- 5. 装 gh CLI (如缺) ---
echo ""
echo "=== [5/8] 装 gh CLI ==="
if ! command -v gh &> /dev/null; then
  echo "安装 gh CLI..."
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
  sudo apt update -qq
  sudo apt install -y gh
fi
gh --version | head -1

# --- 6. 跑 SSH 配置脚本 ---
echo ""
echo "=== [6/8] 配置 SSH 远程通道 ==="
echo "  Tag: $SERVER_TAG"
sudo bash "$INSTALL_DIR/scripts/setup-ubuntu-ssh-client.sh" "$SERVER_TAG"

# --- 7. 入职检查清单 ---
echo ""
echo "=== [7/8] 入职检查清单 ==="
echo "Agent 必须报告以下 4 项:"
echo ""
echo "  [1] 私钥生成:"
echo "      ls -la ~/.ssh/id_ed25519_${SERVER_TAG}"
echo ""
echo "  [2] 公钥内容 (发给老爷):"
echo "      cat ~/.ssh/id_ed25519_${SERVER_TAG}.pub"
echo ""
echo "  [3] SSH 通道测试:"
echo "      ssh macmini 'echo \"✅ Mac mini OK\"'"
echo ""
echo "  [4] Xcode 工具链验证:"
echo "      ssh macmini 'xcodebuild -version | head -1'"
echo ""

# --- 8. 启动时注入 AGENTS.md ---
echo "=== [8/8] 注入 AGENTS.md (让 agent 启动就看到 SOP) ==="
INJECT_FILE="$HOME/.openclaw/workspace/AGENTS.md"
if [ -f "$INSTALL_DIR/docs/AGENTS-injection.md" ]; then
  if ! grep -q "iOS 远程开发 SOP" "$INJECT_FILE" 2>/dev/null; then
    echo "" >> "$INJECT_FILE"
    cat "$INSTALL_DIR/docs/AGENTS-injection.md" >> "$INJECT_FILE"
    echo "  ✅ AGENTS-injection.md 已追加到 $INJECT_FILE"
  else
    echo "  ⚠️  AGENTS.md 已有 iOS SOP 段, 跳过"
  fi
else
  echo "  ⚠️  AGENTS-injection.md 不存在, 跳过"
fi

echo ""
echo "════════════════════════════════════════════════"
echo "  ✅ 入职脚本完成"
echo "════════════════════════════════════════════════"
echo ""
echo "📋 接下来你 (agent) 必须做的事:"
echo "  1. 把上面的公钥发给老爷 (QQ/微信/邮件)"
echo "  2. 跑 'ssh macmini \"echo ok\"' 验证 (等老爷加公钥后)"
echo "  3. 跑 'ssh macmini \"xcodebuild -version | head -1\"' 验证 Xcode"
echo "  4. 4 项检查都 ✅ 后, 报告老爷"
echo "  5. 任何 ❌, 立即报告 (附 log)"
echo ""
echo "⚠️ 不要静默继续, 任何失败都报告!"
echo ""
