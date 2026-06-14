#!/bin/bash
# ========================================
# OpenClaw: 远程触发 Mac mini 跑 iOS archive
# ========================================
# 用法: ssh-macmini-build.sh <AppName> [version]
# 示例: ssh-macmini-build.sh VitaMind 3.0.1  (APP_NAME 传项目名, 脚本自动找 VitaMindGo.xcodeproj 兼容)
# 前置:
#   1. SSH 通道已配通 (ssh macmini 'echo ok' 成功)
#   2. Mac mini 上 ~/Desktop/ios-{AppName}/ 已 git clone
#   3. 项目已有 xcworkspace / xcodeproj (xcodegen generate 已跑)
# ========================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=ios-project-helper.sh
source "$SCRIPT_DIR/ios-project-helper.sh"

die() { echo "✗ $*" >&2; exit 1; }
log() { echo "✓ $*"; }

# --- 参数检查 ---
if [ $# -lt 1 ]; then
  echo "Usage: $0 <AppName> [version]"
  echo "  AppName:  iOS 项目名 (例: VitaMind)"
  echo "  version:  可选, 默认 = 时间戳 (例: 3.0.1)"
  echo ""
  echo "Examples:"
  echo "  $0 VitaMind              # 自动时间戳版本"
  echo "  $0 VitaMind 3.0.1        # 指定版本"
  exit 1
fi

APP_NAME="$1"
VERSION="${2:-$(date +%Y%m%d-%H%M%S)}"
SSH_HOST="macmini"
ARCHIVE_PATH="\$HOME/Desktop/build/${APP_NAME}-${VERSION}.xcarchive"
LOCK_FILE="\$HOME/.openclaw/locks/${APP_NAME}.lock"

# --- 智能查找项目目录 ---
PROJECT_DIR=$(find_project_dir "$SSH_HOST" "$APP_NAME") || die "找不到项目目录 for '${APP_NAME}'.
试过的位置: ios-\${APP_NAME}/, \${APP_NAME}/, ios-\${APP_NAME}Go/, ios-\${APP_NAME}App/, ... 
修法 1: \`PROJECT_DIR_OVERRIDE=~/path ssh-macmini-build.sh ...\`
修法 2: 在 ~/.config/ios-projects/${APP_NAME}.conf 加 \`PROJECT_DIR=~/path\`"
log "项目目录: $PROJECT_DIR"

# --- SSH 通道自检 ---
echo "════════════════════════════════════════════════"
echo "  远程 archive: ${APP_NAME} v${VERSION}"
echo "════════════════════════════════════════════════"
echo ""
echo "=== [1/6] SSH 通道自检 ==="
if ! ssh -o ConnectTimeout=10 "$SSH_HOST" 'echo "✅ Mac mini: $(hostname)"'; then
  echo "❌ SSH 通道不通, 排查: ssh -v $SSH_HOST"
  exit 1
fi

# --- 工具链自检 ---
echo ""
echo "=== [2/6] Mac mini 工具链自检 ==="
ssh "$SSH_HOST" << 'EOF'
  set -e
  xcodebuild -version | head -1
  xcode-select -p
  test -d ~/Desktop && echo "✅ ~/Desktop OK"
  test -d ~/.openclaw/locks && echo "✅ ~/.openclaw/locks OK"
  sw_vers | head -2
EOF

# --- Client 端预检测 workspace/project (避免 server 端 set -u 问题, 修 TOCTOU 竞态) ---
# 智能检测: 尝试多个命名变体 (兼容历史重命名项目)
# 重要: 检测是只读, 不需要锁; 检测后才进 flock 块
echo ""
echo "=== [3/6] 检测 Mac mini 上的 workspace/project ==="
WORKSPACE_ARG=""
# 变体1: ${APP_NAME}.xcworkspace / .xcodeproj (新项目, 名字一致)
# 变体2: ${APP_NAME}Go.xcodeproj (历史重命名, 如 VitaMind → VitaMindGo)
# 变体3: ${APP_NAME}App.xcodeproj (另一种重命名模式)
# 变体4: 目录里任一 .xcodeproj (兑底)
if ssh "$SSH_HOST" "test -d $PROJECT_DIR/${APP_NAME}.xcworkspace" 2>/dev/null; then
  WORKSPACE_ARG="-workspace ${APP_NAME}.xcworkspace"
  echo "  ✅ 使用 workspace: ${APP_NAME}.xcworkspace"
elif ssh "$SSH_HOST" "test -d $PROJECT_DIR/${APP_NAME}.xcodeproj" 2>/dev/null; then
  WORKSPACE_ARG="-project ${APP_NAME}.xcodeproj"
  echo "  ✅ 使用 project: ${APP_NAME}.xcodeproj"
elif ssh "$SSH_HOST" "test -d $PROJECT_DIR/${APP_NAME}Go.xcodeproj" 2>/dev/null; then
  WORKSPACE_ARG="-project ${APP_NAME}Go.xcodeproj"
  echo "  ✅ 使用 project (历史重命名): ${APP_NAME}Go.xcodeproj"
elif ssh "$SSH_HOST" "test -d $PROJECT_DIR/${APP_NAME}App.xcodeproj" 2>/dev/null; then
  WORKSPACE_ARG="-project ${APP_NAME}App.xcodeproj"
  echo "  ✅ 使用 project (历史重命名): ${APP_NAME}App.xcodeproj"
else
  # 兑底: 目录里任一 .xcodeproj
  FOUND=$(ssh "$SSH_HOST" "ls -d $PROJECT_DIR/*.xcodeproj 2>/dev/null | head -1")
  if [ -n "$FOUND" ]; then
    FOUND_NAME=$(basename "$FOUND")
    WORKSPACE_ARG="-project ${FOUND_NAME}"
    echo "  ⚠️  用 APP_NAME 找不到, 用目录里第一个: ${FOUND_NAME}"
  else
    echo "  ❌ 找不到 .xcworkspace 或 .xcodeproj 在 $PROJECT_DIR/"
    echo "     排查: ssh $SSH_HOST 'ls -la $PROJECT_DIR/'"
    exit 1
  fi
fi

# --- Client 端预检测 scheme ---
echo ""
echo "=== [4/6] 检测 Mac mini 上的 scheme ==="
SCHEME="${APP_NAME}Go"
SCHEME_LIST=$(ssh "$SSH_HOST" "cd $PROJECT_DIR && xcodebuild -list $WORKSPACE_ARG 2>/dev/null | awk '/Schemes:/{flag=1; next} flag && NF{print \$1}'" 2>/dev/null || echo "")
if echo "$SCHEME_LIST" | grep -q "^${SCHEME}$"; then
  echo "  ✅ 使用 scheme: $SCHEME"
else
  echo "  ⚠️  Scheme ${SCHEME} 不存在, 列出所有可用 scheme:"
  echo "$SCHEME_LIST" | sed 's/^/    /'
  # Fallback: 取第一个非空行
  SCHEME=$(echo "$SCHEME_LIST" | head -1)
  if [ -z "$SCHEME" ]; then
    echo "  ❌ 没有可用 scheme"
    exit 1
  fi
  echo "  ✅ 使用 fallback scheme: $SCHEME"
fi

# --- flock 保护下跑 archive (修 TOCTOU: 检测后唯一一次拿锁) ---
echo ""
echo "=== [5/6] 跑 xcodebuild archive (在 Mac mini 上, flock 互斥) ==="
echo "  workspace/project: $WORKSPACE_ARG"
echo "  scheme: $SCHEME"
echo "  archive 路径: $ARCHIVE_PATH"
echo "  预计耗时: 5-15 分钟 (取决于项目大小)"
echo ""

# 拿锁 (非阻塞, 拿不到立刻报 BUSY, 防止多 agent 并发)
# 修前: 先 flock -n check (拿锁) → 检测 (无锁) → flock archive (TOCTOU 竞态)
# 修后: 所有检测 先 走完, 唯一次拿锁点 在 archive 起步, flock -n 防双开
LOCK_TAKE=$(ssh "$SSH_HOST" "flock -n $LOCK_FILE echo TAKEN || echo BUSY" 2>/dev/null || echo "BUSY")
if [ "$LOCK_TAKE" = "BUSY" ]; then
  echo "❌ 锁被占用, 另一台 Ubuntu 正在跑 ${APP_NAME} 的 archive"
  echo "   等下个心跳或找老爷手动 unlock:"
  echo "   ssh $SSH_HOST 'rm -f $LOCK_FILE'"
  exit 1
fi
echo "✅ 锁获取成功 (flock -n non-blocking)"

# 锁获取后, 释放 (仅为占位, 让别 agent 能看到 BUSY) - flock 命令释放后锁消失
# 实际: 上面的 flock -n 在 ssh 命令结束时释放
# 下一步: 跑 archive (需要时再拿锁, 加 -n)

# 实际 archive 命令 (不持锁, 但走检测过的配置, 保护靠手件)
# 为了真正互斥, 下面用 flock -n 包 archive
ssh "$SSH_HOST" "flock -n $LOCK_FILE bash -s" << EOF
  set -euo pipefail
  cd $PROJECT_DIR

  echo "[Mac mini] 当前目录: \$(pwd)"
  echo "[Mac mini] 锁文件: $LOCK_FILE"

  # 1. xcodegen (如果有 project.yml)
  if [ -f project.yml ]; then
    if ! command -v xcodegen &> /dev/null; then
      echo "[Mac mini] 安装 xcodegen..."
      brew install xcodegen
    fi
    xcodegen generate
  fi

  # 2. pod install (如果有 Podfile)
  if [ -f Podfile ]; then
    if ! command -v pod &> /dev/null; then
      echo "[Mac mini] 安装 cocoapods..."
      gem install cocoapods --no-document
    fi
    pod install --repo-update
  fi

  # 3. 跑 archive
  echo "[Mac mini] 开始 archive..."
  xcodebuild archive \\
    $WORKSPACE_ARG \\
    -scheme "$SCHEME" \\
    -configuration Release \\
    -archivePath "$ARCHIVE_PATH" \\
    -destination 'generic/platform=iOS' \\
    -allowProvisioningUpdates \\
    CODE_SIGNING_ALLOWED=NO \\
    | xcpretty || xcodebuild archive \\
    $WORKSPACE_ARG \\
    -scheme "$SCHEME" \\
    -configuration Release \\
    -archivePath "$ARCHIVE_PATH" \\
    -destination 'generic/platform=iOS' \\
    -allowProvisioningUpdates \\
    CODE_SIGNING_ALLOWED=NO

  echo ""
  echo "[Mac mini] ✅ Archive OK: $ARCHIVE_PATH"
  ls -la "$ARCHIVE_PATH" | head -3
EOF

# --- 验证 ---
echo ""
echo "=== [6/6] 验证 archive 产物 ==="
if ssh "$SSH_HOST" "test -d $ARCHIVE_PATH"; then
  ssh "$SSH_HOST" "ls -la $ARCHIVE_PATH | head -5"
  echo "✅ Archive 已生成"
else
  echo "❌ Archive 路径不存在: $ARCHIVE_PATH"
  exit 1
fi

# --- 完成 ---
echo ""
echo "════════════════════════════════════════════════"
echo "  ✅ Archive 成功"
echo "════════════════════════════════════════════════"
echo "  App:    ${APP_NAME}"
echo "  版本:   ${VERSION}"
echo "  路径:   ${ARCHIVE_PATH}"
echo "════════════════════════════════════════════════"
echo ""
echo "下一步:"
echo "  - 上传 App Store Connect:  ./scripts/ssh-macmini-upload.sh ${APP_NAME} ${VERSION}"
echo "  - 跑截图:                 ./scripts/ssh-macmini-screenshot.sh ${APP_NAME}"
echo ""
