#!/bin/bash
# ========================================
# OpenClaw: 单台 Ubuntu 一键配置 SSH 远程通道
# ========================================
# 用法: sudo bash setup-ubuntu-ssh-client.sh <server_tag>
# 示例: sudo bash setup-ubuntu-ssh-client.sh alpha
# 必填: server_tag (alpha/beta/gamma/..., 每台 Ubuntu 唯一)
# ========================================

set -euo pipefail

# --- 参数检查 ---
if [ $# -ne 1 ]; then
  echo "Usage: $0 <server_tag>"
  echo "  server_tag: 本机唯一标识 (alpha/beta/gamma/...)"
  echo ""
  echo "Examples:"
  echo "  $0 alpha    # 第一台 Ubuntu"
  echo "  $0 beta     # 第二台 Ubuntu"
  echo "  $0 gamma    # 第三台 Ubuntu"
  exit 1
fi

SERVER_TAG="$1"

# 校验 tag 格式 (小写字母数字下划线连字符, 1-32 字符)
if ! [[ "$SERVER_TAG" =~ ^[a-z0-9_-]{1,32}$ ]]; then
  echo "❌ server_tag 格式不合法: $SERVER_TAG"
  echo "   必须是 1-32 字符的小写字母/数字/下划线/连字符"
  exit 1
fi

KEY_PATH="$HOME/.ssh/id_ed25519_${SERVER_TAG}"
KEY_COMMENT="openclaw-${SERVER_TAG}@$(hostname)"

# --- 1. 检查 SSH 客户端 ---
echo "=== [1/6] 检查 SSH 客户端 ==="
if ! command -v ssh &> /dev/null; then
  echo "❌ ssh 未安装"
  echo "   安装: sudo apt update && sudo apt install -y openssh-client"
  exit 1
fi
SSH_VERSION=$(ssh -V 2>&1 | awk '{print $1}')
echo "✅ $SSH_VERSION"

# --- 2. 检查/生成密钥对 ---
echo ""
echo "=== [2/6] 检查/生成密钥对 ==="

# 先确保 ~/.ssh 存在 (修 bug: 新机器上 $HOME/.ssh 可能还不存在)
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

if [ -f "$KEY_PATH" ]; then
  echo "⚠️  私钥已存在: $KEY_PATH"
  echo "   不覆盖, 使用现有密钥"
  echo "   如要重新生成, 先手动删除: rm $KEY_PATH $KEY_PATH.pub"
else
  echo "生成新密钥对..."
  ssh-keygen -t ed25519 \
    -f "$KEY_PATH" \
    -C "$KEY_COMMENT" \
    -N ""
  echo "✅ 密钥对已生成"
fi

# 修正权限 (ssh 客户端会拒绝权限过宽的私钥)
chmod 700 "$HOME/.ssh"
chmod 600 "$KEY_PATH"
chmod 644 "$KEY_PATH.pub"
echo "✅ 权限已修正 (私钥 600, 公钥 644)"

# --- 3. 写 ~/.ssh/config ---
echo ""
echo "=== [3/6] 写 ~/.ssh/config ==="
if ! grep -q "Host macmini" "$HOME/.ssh/config" 2>/dev/null; then
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"
  cat >> "$HOME/.ssh/config" << EOF

# === OpenClaw Mac mini 共享通道 (2026-06-05) ===
# 单入口: 47.77.237.73:2222 直连 Mac mini
# 维护: 佛罗多老爷 (lauer3912)
Host macmini
    HostName 47.77.237.73
    Port 2222
    User user291981
    IdentityFile $KEY_PATH
    IdentitiesOnly yes
    StrictHostKeyChecking accept-new
    ServerAliveInterval 60
    ServerAliveCountMax 3
    Compression yes
EOF
  chmod 600 "$HOME/.ssh/config"
  echo "✅ ~/.ssh/config 已添加 macmini Host 块"
else
  echo "⚠️  ~/.ssh/config 已有 macmini 块, 跳过"
fi

# --- 4. 提示把公钥发给老爷 ---
echo ""
echo "=== [4/6] 把公钥发给老爷 ==="
echo "请把以下公钥发给老爷 (任意安全通道, 公钥本身是公开信息):"
echo ""
echo "--- BEGIN PUBLIC KEY ---"
cat "$KEY_PATH.pub"
echo "--- END PUBLIC KEY ---"
echo ""
echo "老爷收到后, 会在 Mac mini 上把它追加到 ~/.ssh/authorized_keys"
echo ""
read -p "公钥已发给老爷? (按 Enter 继续, Ctrl+C 取消): "

# --- 5. 验证 SSH 通道 ---
echo ""
echo "=== [5/6] 验证 SSH 通道 ==="
echo "测试 ssh macmini (首次会询问 host key, 输入 yes)..."
if ssh -o ConnectTimeout=10 macmini 'echo "✅ Mac mini OK: $(hostname) && uname -a"'; then
  echo ""
  echo "✅ SSH 通道已通"
else
  echo ""
  echo "❌ SSH 通道测试失败"
  echo "   可能原因:"
  echo "   1. 老爷还没把公钥追加到 Mac mini 的 authorized_keys"
  echo "   2. 入口地址/端口错 (47.77.237.73:2222)"
  echo "   3. Mac mini 上 SSH 服务未开"
  echo "   4. 防火墙挡"
  echo ""
  echo "   排查: ssh -v macmini (详细日志)"
  exit 1
fi

# --- 6. 验证 Xcode 工具链 ---
echo ""
echo "=== [6/6] 验证 Mac mini 工具链 ==="
if ssh macmini 'xcodebuild -version | head -1 && xcode-select -p'; then
  echo ""
  echo "✅ Xcode 工具链可用"
else
  echo ""
  echo "❌ Xcode 工具链验证失败"
  echo "   排查: ssh macmini 'xcodebuild -version'"
  exit 1
fi

# --- 完成 ---
echo ""
echo "════════════════════════════════════════════════"
echo "  ✅ Ubuntu 端配置完成 (tag=$SERVER_TAG)"
echo "════════════════════════════════════════════════"
echo ""
echo "后续:"
echo "  - 日常: ssh macmini 'xcodebuild ...'"
echo "  - 跑 archive: ssh-macmini-build.sh <AppName>"
echo "  - 跑上传:   ssh-macmini-upload.sh <AppName> <version>"
echo "  - 跑截图:   ssh-macmini-screenshot.sh <AppName>"
echo ""
