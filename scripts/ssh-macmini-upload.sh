#!/bin/bash
# ========================================
# OpenClaw: ⚠️ DEPRECATED ⚠️
# ========================================
# 佛老爷 2026-06-16 11:38 拍板: Ubuntu Agent **不**直接 SSH 到 Mac mini 跑 archive.
# 改走 E 方案: 走 agent-bus send to:Katherine-E2wa1m type:request 委托.
# 完整流程见 docs/SOP-iOS-Ubuntu-Development.md §6.10
#
# 本脚本**仍可用** (历史档案, 测试环境, 紧急 fix bug), 但**官方**走 E 方案.
# ========================================
#!/bin/bash
# ========================================
# OpenClaw: 远程把 archive 上传到 App Store Connect
# ========================================
# 用法: ssh-macmini-upload.sh <AppName> <version>
# 示例: ssh-macmini-upload.sh VitaMind 3.0.1  (跟 ssh-macmini-build.sh 的 APP_NAME 保持一致)
# 前置:
#   1. 已跑过 ssh-macmini-build.sh (archive 已生成)
#   2. App Store Connect API Key 已配 (Mac mini 上 ~/.appstoreconnect/private_keys/AuthKey_*.p8)
#   3. ExportOptions.plist 在项目 AppStore/ 目录
# ========================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=ios-project-helper.sh
source "$SCRIPT_DIR/ios-project-helper.sh"

die() { echo "✗ $*" >&2; exit 1; }
log() { echo "✓ $*"; }

# --- 参数检查 ---
if [ $# -ne 2 ]; then
  echo "Usage: $0 <AppName> <version>"
  echo "  AppName: iOS 项目名 (例: VitaMind, 跟 build 的 APP_NAME 一致)"
  echo "  version: archive 版本 (例: 3.0.1)"
  exit 1
fi

APP_NAME="$1"
VERSION="$2"
SSH_HOST="macmini"
ARCHIVE_PATH="\$HOME/Desktop/build/${APP_NAME}-${VERSION}.xcarchive"
EXPORT_PATH="\$HOME/Desktop/build/${APP_NAME}-${VERSION}"

# --- 智能查找项目目录 ---
PROJECT_DIR=$(find_project_dir "$SSH_HOST" "$APP_NAME") || die "找不到项目目录 for '${APP_NAME}'.
试过的位置: ios-\${APP_NAME}/, \${APP_NAME}/, ios-\${APP_NAME}Go/, ios-\${APP_NAME}App/, ... 
修法 1: \`PROJECT_DIR_OVERRIDE=~/path ssh-macmini-upload.sh ...\`
修法 2: 在 ~/.config/ios-projects/${APP_NAME}.conf 加 \`PROJECT_DIR=~/path\`"
log "项目目录: $PROJECT_DIR"

echo "════════════════════════════════════════════════"
echo "  上传 archive 到 App Store Connect"
echo "  App:    ${APP_NAME}"
echo "  版本:   ${VERSION}"
echo "════════════════════════════════════════════════"
echo ""

# --- 1. 验证 archive ---
echo "=== [1/5] 验证 archive 存在 ==="
if ! ssh "$SSH_HOST" "test -d $ARCHIVE_PATH"; then
  echo "❌ Archive 不存在: $ARCHIVE_PATH"
  echo "   先跑: ./scripts/ssh-macmini-build.sh ${APP_NAME} ${VERSION}"
  exit 1
fi
echo "✅ Archive 存在"

# --- 2. 导出 .ipa ---
echo ""
echo "=== [2/5] 导出 .ipa ==="
EXPORT_OPTIONS="${PROJECT_DIR}/AppStore/ExportOptions.plist"
ssh "$SSH_HOST" << EOF
  set -euo pipefail
  mkdir -p $EXPORT_PATH

  # 检查 ExportOptions.plist
  if [ ! -f "$EXPORT_OPTIONS" ]; then
    echo "❌ ExportOptions.plist 不存在: $EXPORT_OPTIONS"
    echo "   请创建: ~/Desktop/ios-${APP_NAME}/AppStore/ExportOptions.plist"
    exit 1
  fi

  xcodebuild -exportArchive \\
    -archivePath $ARCHIVE_PATH \\
    -exportPath $EXPORT_PATH \\
    -exportOptionsPlist $EXPORT_OPTIONS \\
    -allowProvisioningUpdates
EOF
echo "✅ .ipa 已导出"

# --- 3. 找 .ipa 文件 ---
echo ""
echo "=== [3/5] 找 .ipa 文件 ==="
IPA_PATH=$(ssh "$SSH_HOST" "ls -t $EXPORT_PATH/*.ipa 2>/dev/null | head -1")
if [ -z "$IPA_PATH" ]; then
  echo "❌ 找不到 .ipa 文件在 $EXPORT_PATH/"
  exit 1
fi
echo "✅ 找到 .ipa: $IPA_PATH"

# --- 4. 上传 (altool with API Key) ---
echo ""
echo "=== [4/5] 上传到 App Store Connect ==="
echo "  使用 xcrun altool + API Key"

# API Key 路径 (Mac mini 上)
API_KEY_DIR="\$HOME/.appstoreconnect/private_keys"
API_KEY_NAME=$(ssh "$SSH_HOST" "ls $API_KEY_DIR/AuthKey_*.p8 2>/dev/null | head -1 | xargs basename 2>/dev/null" 2>/dev/null || echo "")

if [ -z "$API_KEY_NAME" ]; then
  echo "❌ Mac mini 上找不到 API Key: $API_KEY_DIR/AuthKey_*.p8"
  echo "   生成步骤:"
  echo "   1. https://appstoreconnect.apple.com/access/api"
  echo "   2. 生成 Team Key, 下载 .p8"
  echo "   3. 放到 Mac mini: ~/.appstoreconnect/private_keys/AuthKey_XXXXXXXXXX.p8"
  exit 1
fi

# Key ID (从文件名提取)
KEY_ID=$(echo "$API_KEY_NAME" | sed -E 's/AuthKey_([A-Z0-9]+)\.p8/\1/')
ISSUER_ID="\${APP_STORE_CONNECT_ISSUER_ID:-00000000-0000-0000-0000-000000000000}"

# 上传 (用 API Key, 不用密码)
ssh "$SSH_HOST" << EOF
  set -euo pipefail
  xcrun altool --upload-app \\
    --type ios \\
    --file "$IPA_PATH" \\
    --apiKey "$KEY_ID" \\
    --apiIssuer "$ISSUER_ID" \\
    --asc-provider "\${APPLE_TEAM_ID:-9L6N2ZF26B}"
EOF

echo "✅ 已上传到 App Store Connect"

# --- 5. 通知 ---
echo ""
echo "=== [5/5] 完成 ==="
echo ""
echo "════════════════════════════════════════════════"
echo "  ✅ 上传成功"
echo "════════════════════════════════════════════════"
echo "  App:      ${APP_NAME}"
echo "  版本:     ${VERSION}"
echo "  .ipa:     $IPA_PATH"
echo "════════════════════════════════════════════════"
echo ""
echo "下一步:"
echo "  1. 打开 App Store Connect → My Apps → ${APP_NAME}Go → TestFlight"
echo "  2. 等待构建处理 (1-5 分钟)"
echo "  3. 跑截图: ./scripts/ssh-macmini-screenshot.sh ${APP_NAME}"
echo "  4. 提交审核 (手工, 在 App Store Connect 网页)"
echo ""
