#!/bin/bash
# ========================================
# OpenClaw: iOS 项目查找 helper (ssh-macmini-*.sh 共享)
# ========================================
# 提供 2 个函数:
#   find_project_dir <ssh-host> <app-name>   → 输出 $HOME/Desktop/... 路径
#   find_xcode_artifact <ssh-host> <proj-dir> <app-name>  → 输出 "-workspace X" 或 "-project Y"
#
# 用法 (在 ssh-macmini-*.sh 里):
#   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#   # shellcheck source=ios-project-helper.sh
#   source "$SCRIPT_DIR/ios-project-helper.sh"
#
#   PROJECT_DIR=$(find_project_dir "$SSH_HOST" "$APP_NAME") || die "..."
#   WORKSPACE_ARG=$(find_xcode_artifact "$SSH_HOST" "$PROJECT_DIR" "$APP_NAME") || die "..."
#
# 智能查找顺序:
#   1. $PROJECT_DIR_OVERRIDE env var
#   2. ~/.config/ios-projects/<app-name>.conf 的 PROJECT_DIR= 字段
#   3. SSH test -d 尝试 8 个常见路径
#   4. 失败 → 返回非零 (caller die)
# ========================================

# --- find_project_dir ---
find_project_dir() {
  local ssh_host="$1"
  local app_name="$2"
  local candidate

  # 1. Env var override
  if [[ -n "${PROJECT_DIR_OVERRIDE:-}" ]]; then
    echo "$PROJECT_DIR_OVERRIDE"
    return 0
  fi

  # 2. Project config file
  local conf_file="$HOME/.config/ios-projects/${app_name}.conf"
  if [[ -f "$conf_file" ]]; then
    # shellcheck source=/dev/null
    source "$conf_file"
    if [[ -n "${PROJECT_DIR:-}" ]]; then
      if ssh "$ssh_host" "test -d $PROJECT_DIR" 2>/dev/null; then
        echo "$PROJECT_DIR"
        return 0
      fi
    fi
  fi

  # 3. Try 8 common candidate paths (兼容历史重命名)
  local candidates=(
    "\$HOME/Desktop/ios-${app_name}"        # 标准 (新项目)
    "\$HOME/Desktop/${app_name}"             # 无 ios- 前缀
    "\$HOME/Desktop/ios-${app_name}Go"       # 历史加 Go 后缀 (例: VitaMind → VitaMindGo)
    "\$HOME/Desktop/ios-${app_name}App"      # 加 App 后缀
    "\$HOME/Desktop/${app_name}Go"           # Go 后缀无 ios-
    "\$HOME/Desktop/${app_name}App"          # App 后缀无 ios-
    "\$HOME/ios-${app_name}"                  # ~/ 下直接放
    "\$HOME/projects/${app_name}"             # ~/projects/ 下
  )
  for candidate in "${candidates[@]}"; do
    if ssh "$ssh_host" "test -d $candidate" 2>/dev/null; then
      echo "$candidate"
      return 0
    fi
  done

  # 4. All failed
  return 1
}

# --- find_xcode_artifact ---
# 输出: "-workspace X" 或 "-project Y" (含 dash 前缀, 直接给 xcodebuild 用)
find_xcode_artifact() {
  local ssh_host="$1"
  local project_dir="$2"
  local app_name="$3"

  # 优先 xcworkspace (新项目)
  if ssh "$ssh_host" "test -d $project_dir/${app_name}.xcworkspace" 2>/dev/null; then
    echo "-workspace ${app_name}.xcworkspace"
    return 0
  fi

  # xcodeproj (标准)
  if ssh "$ssh_host" "test -d $project_dir/${app_name}.xcodeproj" 2>/dev/null; then
    echo "-project ${app_name}.xcodeproj"
    return 0
  fi

  # xcodeproj + 后缀 (历史重命名)
  for suffix in "Go" "App"; do
    if ssh "$ssh_host" "test -d $project_dir/${app_name}${suffix}.xcodeproj" 2>/dev/null; then
      echo "-project ${app_name}${suffix}.xcodeproj"
      return 0
    fi
  done

  # 兜底: 目录里任一 .xcodeproj
  local found
  found=$(ssh "$ssh_host" "ls -d $project_dir/*.xcodeproj 2>/dev/null | head -1" 2>/dev/null)
  if [[ -n "$found" ]]; then
    local found_name
    found_name=$(basename "$found")
    echo "-project ${found_name}"
    return 0
  fi

  return 1
}
