#!/bin/bash
# ========================================
# OpenClaw: 远程触发 Mac mini 跑 iOS 截图
# ========================================
# 用法: ssh-macmini-screenshot.sh <AppName>
# 示例: ssh-macmini-screenshot.sh VitaMind  (兼容 VitaMindGo.xcodeproj)
# 前置:
#   1. Mac mini 上 ~/Desktop/ios-{AppName}/ 已 git clone
#   2. App 已 archive (可选, 也可用 Debug build)
#   3. 模拟器列表 (iPhone 16 / iPad Pro 13")
# ========================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=ios-project-helper.sh
source "$SCRIPT_DIR/ios-project-helper.sh"

die() { echo "✗ $*" >&2; exit 1; }
log() { echo "✓ $*"; }

# --- 参数检查 ---
if [ $# -ne 1 ]; then
  echo "Usage: $0 <AppName>"
  echo "  AppName: iOS 项目名 (例: VitaMind, 自动找 VitaMindGo.xcodeproj)"
  exit 1
fi

APP_NAME="$1"
SSH_HOST="macmini"
BUNDLE_ID="com.ggsheng.${APP_NAME}"  # 默认值, 实际可能不同

# --- 智能查找项目目录 ---
PROJECT_DIR=$(find_project_dir "$SSH_HOST" "$APP_NAME") || die "找不到项目目录 for '${APP_NAME}'.
试过的位置: ios-\${APP_NAME}/, \${APP_NAME}/, ios-\${APP_NAME}Go/, ios-\${APP_NAME}App/, ... 
修法 1: \`PROJECT_DIR_OVERRIDE=~/path ssh-macmini-screenshot.sh ...\`
修法 2: 在 ~/.config/ios-projects/${APP_NAME}.conf 加 \`PROJECT_DIR=~/path\`"
log "项目目录: $PROJECT_DIR"
SCREENSHOTS_DIR="${PROJECT_DIR}/AppStore/Screenshots"

echo "════════════════════════════════════════════════"
echo "  远程截图: ${APP_NAME}"
echo "════════════════════════════════════════════════"
echo ""

# --- 1. SSH 自检 ---
echo "=== [1/4] SSH 通道自检 ==="
if ! ssh -o ConnectTimeout=10 "$SSH_HOST" 'echo "✅ Mac mini: $(hostname)"'; then
  echo "❌ SSH 通道不通"
  exit 1
fi

# --- 2. 准备模拟器和 App ---
echo ""
echo "=== [2/4] 启动模拟器 + 安装 App ==="
ssh "$SSH_HOST" << EOF
  set -euo pipefail
  cd $PROJECT_DIR

  # 模拟器 (iPhone 16)
  DEVICE_NAME="iPhone 16"
  echo "[Mac mini] 启动模拟器: \$DEVICE_NAME"
  xcrun simctl boot "\$DEVICE_NAME" 2>/dev/null || true
  open -a Simulator
  sleep 3

  # 找 .app - 智能检测 (尝试多个变体, 兑底找任一 .app)
  APP_PATH=""
  for app_name in "${APP_NAME}Go.app" "${APP_NAME}.app" "${APP_NAME}App.app"; do
    FOUND="\$(find ~/Library/Developer/Xcode/DerivedData -name \"$app_name\" -type d 2>/dev/null | head -1)"
    if [ -n "\$FOUND" ]; then
      APP_PATH="\$FOUND"
      echo "[Mac mini] ✅ 找到 App (变体 \$app_name): \$APP_PATH"
      break
    fi
  done
  if [ -z "\$APP_PATH" ]; then
    APP_PATH="\$(find $PROJECT_DIR/build -name \"*.app\" -type d 2>/dev/null | head -1)"
    [ -n "\$APP_PATH" ] && echo "[Mac mini] ⚠️  在 build/ 里找到 .app: \$APP_PATH"
  fi
  if [ -z "\$APP_PATH" ]; then
    APP_PATH="\$(find ~/Library/Developer/Xcode/DerivedData -name \"*.app\" -type d 2>/dev/null | head -1)"
    [ -n "\$APP_PATH" ] && echo "[Mac mini] ⚠️  DerivedData 里兑底找到: \$APP_PATH"
  fi
  if [ -z "\$APP_PATH" ]; then
    echo "[Mac mini] ❌ 找不到 .app, 请先跑 archive 或 Debug build"
    exit 1
  fi
  echo "[Mac mini] App 路径: \$APP_PATH"

  # 读 Bundle ID
  BUNDLE_ID_FROM_PLIST="\$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "\$APP_PATH/Info.plist" 2>/dev/null || echo "")"
  if [ -n "\$BUNDLE_ID_FROM_PLIST" ]; then
    BUNDLE_ID="\$BUNDLE_ID_FROM_PLIST"
    echo "[Mac mini] Bundle ID: \$BUNDLE_ID"
  else
    echo "[Mac mini] ⚠️  用默认 Bundle ID: $BUNDLE_ID"
  fi

  # 安装
  echo "[Mac mini] 安装 App..."
  xcrun simctl install booted "\$APP_PATH"

  # 启动
  echo "[Mac mini] 启动 App..."
  xcrun simctl launch booted "\$BUNDLE_ID"
  sleep 5  # 等 App 加载完
EOF

# --- 3. 截图 ---
echo ""
echo "=== [3/4] 截图 ==="
# 截图张数 (iPhone 4 张 + iPad 4 张 = 8 张, App Store 要求)
# 这里简化, 跑 1 张 iPhone + 1 张 iPad, 实际可调整
NUM_SCREENSHOTS="${NUM_SCREENSHOTS:-4}"  # 默认 4 张, 通过环境变量覆盖

ssh "$SSH_HOST" << EOF
  set -euo pipefail

  mkdir -p $SCREENSHOTS_DIR

  # iPhone 截图 (4 张)
  for i in 1 2 3 4; do
    echo "[Mac mini] 截图 iPhone-\$i.png"
    xcrun simctl io booted screenshot $SCREENSHOTS_DIR/iPhone-\$i.png
    sleep 2  # 给用户操作 App 留时间
  done

  # iPad 截图 (4 张) - 切换到 iPad
  DEVICE_IPAD="iPad Pro 13-inch (M4)"
  echo "[Mac mini] 切换到 iPad: \$DEVICE_IPAD"
  xcrun simctl shutdown booted
  xcrun simctl boot "\$DEVICE_IPAD" 2>/dev/null || true
  open -a Simulator
  sleep 3

  for i in 1 2 3 4; do
    echo "[Mac mini] 截图 iPad-\$i.png"
    xcrun simctl io booted screenshot $SCREENSHOTS_DIR/iPad-\$i.png
    sleep 2
  done

  # 关闭
  xcrun simctl terminate booted "\$BUNDLE_ID" 2>/dev/null || true
  xcrun simctl shutdown booted

  echo ""
  echo "[Mac mini] ✅ 截图完成"
  ls -la $SCREENSHOTS_DIR/
EOF

# --- 4. 拉回截图 ---
echo ""
echo "=== [4/4] 拉回截图到本地 ==="
LOCAL_DIR="./screenshots/${APP_NAME}"
mkdir -p "$LOCAL_DIR"
scp -r "$SSH_HOST:$SCREENSHOTS_DIR/" "$LOCAL_DIR/"

echo "✅ 截图已拉到: $LOCAL_DIR/"
ls -la "$LOCAL_DIR/" | head -10

echo ""
echo "════════════════════════════════════════════════"
echo "  ✅ 截图完成"
echo "════════════════════════════════════════════════"
echo "  本地:  $LOCAL_DIR/"
echo "  远程:  ${SSH_HOST}:${SCREENSHOTS_DIR}/"
echo "════════════════════════════════════════════════"
echo ""
echo "下一步:"
echo "  - 用 ImageMagick / sips 调整尺寸 (App Store 要求 1242×2688 iPhone, 2048×2732 iPad)"
echo "  - 上传到 App Store Connect"
echo ""
