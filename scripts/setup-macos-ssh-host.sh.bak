#!/bin/bash
# ========================================
# OpenClaw: Mac mini 一次性接收端配置
# ========================================
# 用法: bash setup-macos-ssh-host.sh
# 运行位置: Mac mini 本地 (老爷手工)
# 作用: 创建锁目录 / 准备项目根 / 启用 SSH / 不动密码登录
# ========================================

set -euo pipefail

echo "════════════════════════════════════════════════"
echo "  Mac mini 接收端一次性配置"
echo "  适用: OpenClaw 远程 iOS App 开发"
echo "════════════════════════════════════════════════"
echo ""

# --- 1. 确认当前用户 ---
CURRENT_USER=$(whoami)
echo "=== [1/6] 当前用户 ==="
echo "用户: $CURRENT_USER"
echo "⚠️  本 SOP 默认 SSH 用户 = user291981"
if [ "$CURRENT_USER" != "user291981" ]; then
  echo "❌ 当前用户不是 user291981, 请在 user291981 账户下跑本脚本"
  exit 1
fi
echo "✅ 用户名匹配 SOP 默认值"

# --- 2. 创建锁目录 ---
echo ""
echo "=== [2/6] 创建锁目录 ==="
mkdir -p "$HOME/.openclaw/locks"
chmod 755 "$HOME/.openclaw/locks"
echo "✅ $HOME/.openclaw/locks 已创建 (用于 flock 并发控制)"

# --- 3. 准备项目根目录 ---
echo ""
echo "=== [3/6] 准备项目根目录 ==="
mkdir -p "$HOME/Desktop"
mkdir -p "$HOME/Desktop/build"
chmod 755 "$HOME/Desktop"
echo "✅ ~/Desktop/ 已存在 (项目根: ~/Desktop/ios-{AppName}/)"

# --- 4. 启用 SSH 服务 ---
echo ""
echo "=== [4/6] 启用 SSH 服务 ==="
SSH_STATUS=$(sudo systemsetup -getremotelogin 2>/dev/null | awk '{print $3}')
if [ "$SSH_STATUS" != "On" ]; then
  echo "启用远程登录..."
  sudo systemsetup -setremotelogin on
fi

# 验证 sshd 在跑
if sudo launchctl list | grep -q com.openssh.sshd; then
  echo "✅ SSH 服务运行中 (com.openssh.sshd)"
else
  echo "❌ SSH 服务未运行, 请检查: sudo launchctl list | grep sshd"
  exit 1
fi

# --- 5. 准备 authorized_keys ---
echo ""
echo "=== [5/6] 准备 ~/.ssh/authorized_keys ==="
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

if [ ! -f "$HOME/.ssh/authorized_keys" ]; then
  touch "$HOME/.ssh/authorized_keys"
  chmod 600 "$HOME/.ssh/authorized_keys"
  echo "✅ $HOME/.ssh/authorized_keys 已创建 (空文件)"
else
  echo "⚠️  $HOME/.ssh/authorized_keys 已存在"
  echo "   现有公钥数: $(grep -c '^ssh-' $HOME/.ssh/authorized_keys)"
fi
echo ""
echo "📋 下一步: 把每台 Ubuntu 的公钥追加到这里 (一行一个)"
echo "   例: echo 'ssh-ed25519 AAAA... openclaw-alpha@...' >> ~/.ssh/authorized_keys"

# --- 6. 验证 Xcode 工具链 ---
echo ""
echo "=== [6/6] 验证 Xcode 工具链 ==="
if ! command -v xcodebuild &> /dev/null; then
  echo "❌ xcodebuild 未找到"
  echo "   安装: xcode-select --install"
  echo "   或: App Store 安装 Xcode"
  exit 1
fi
XCODE_VERSION=$(xcodebuild -version | head -1)
XCODE_PATH=$(xcode-select -p)
echo "✅ $XCODE_VERSION"
echo "✅ $XCODE_PATH"

# --- 完成 ---
echo ""
echo "════════════════════════════════════════════════"
echo "  ✅ Mac mini 接收端配置完成"
echo "════════════════════════════════════════════════"
echo ""
echo "后续 (手工):"
echo "  1. 把每台 Ubuntu 的公钥追加到 ~/.ssh/authorized_keys"
echo "  2. (可选) 等 SSH 公钥全部验证通过后, 禁用密码登录:"
echo "     sudo sed -i '' 's/^#\\?PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config"
echo "     sudo sed -i '' 's/^#\\?ChallengeResponseAuthentication yes/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config"
echo "     sudo launchctl kickstart -k system/com.openssh.sshd"
echo ""
echo "验证 (从 Ubuntu 端):"
echo "  ssh macmini 'echo ok'"
echo ""
