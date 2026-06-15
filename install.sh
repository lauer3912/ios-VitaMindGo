#!/bin/bash
# ========================================
# OpenClaw Agent 入职入口脚本 v1.0.5
# ========================================
# 用法:
#   curl -fsSL -H "Authorization: token $TOKEN" \
#     https://raw.githubusercontent.com/lauer3912/openclaw-portable-template/main/install.sh | bash
#
# 前置:
#   - Ubuntu 22.04+ / Debian 12+
#   - 有网络 (github.com)
#   - curl / git / bash 已装
#
# 行为:
#   - 8 个 Step, 幂等, 可断点续传
#   - 每个 Step完成后写 .install-state/.step-N.done
#   - 重复跑自动跳过已完成 Step
# ========================================
set -euo pipefail

# --- 0. 内置常量 (佛老爷 2026-06-08 拍板共用) ---
DEFAULT_GITHUB_TOKEN="ghp_…TJJZ"
TEMPLATE_REPO="lauer3912/openclaw-portable-template"
TEMPLATE_BRANCH="main"
WORKSPACE="$HOME/.openclaw/workspace"
WORKSPACE_TEMPLATE="$HOME/.openclaw/workspace-template"
STATE_DIR="$WORKSPACE/.install-state"
GITHUB_RAW="https://raw.githubusercontent.com/${TEMPLATE_REPO}/${TEMPLATE_BRANCH}"

# --- 0.5 网络说明 (2026-06-10 老爷明示) ---
# Ubuntu 服务器直连 GitHub 没问题, 不需要代理
# (代理 127.0.0.1:10808 是 Mac mini 上 Katherine 专用的, 跟新 Agent 无关)

# --- 工具函数 ---
log() { echo "[$(date +%H:%M:%S)] $*"; }
ok() { echo "✅ $*"; }
warn() { echo "⚠️  $*"; }
fail() { echo "❌ $*" >&2; exit 1; }
step_done() { mkdir -p "$STATE_DIR"; touch "$STATE_DIR/.step-$1.done"; }
step_exists() { [ -f "$STATE_DIR/.step-$1.done" ]; }

# 智能下载: 优先 raw.githubusercontent.com, 超时 fallback 到 api.github.com
smart_fetch() {
  local raw_url="$1"
  local api_repo_path="$2"  # e.g. "/repos/lauer3912/openclaw-portable-template/contents/MANIFEST.yaml"
  local output="$3"

  # 尝试 raw (5秒超时)
  if curl -fsSL --max-time 5 "$raw_url" -o "$output" 2>/dev/null; then
    return 0
  fi

  # Fallback: API 拿 base64 content
  warn "raw 超时, fallback 到 api.github.com"
  curl -fsSL --max-time 15 -H "Authorization: token $DEFAULT_GITHUB_TOKEN" \
    "https://api.github.com${api_repo_path}" 2>/dev/null \
    | python3 -c "import json,sys,base64; d=json.load(sys.stdin); print(base64.b64decode(d['content']).decode('utf-8',errors='replace'))" \
    > "$output" 2>/dev/null || return 1

  [ -s "$output" ] && return 0 || return 1
}

# 验证前置 Step 证据
validate_step() {
  local step=$1
  local check=$2
  if [ -f "$STATE_DIR/.step-${step}.done" ] && ! eval "$check"; then
    log "⚠️  Step $step 状态文件存在但验证失败，重新执行"
    rm -f "$STATE_DIR/.step-${step}.done"
  fi
}

# ========================================
# Step 0: 环境检测
# ========================================
step0_env_check() {
  log "Step 0: 环境检测"

  command -v node >/dev/null 2>&1 || fail "Node.js 未安装 (需要 >= 24)"
  command -v git >/dev/null 2>&1 || fail "git 未安装"
  command -v curl >/dev/null 2>&1 || fail "curl 未安装"

  local node_ver=$(node -v | tr -d 'v' | cut -d. -f1)
  [ "$node_ver" -ge 24 ] 2>/dev/null || fail "Node.js 版本需要 >= 24，当前 $(node -v)"

  # 网络检测
  if ! curl -fsSL --max-time 10 https://github.com >/dev/null 2>&1; then
    fail "无法连接 github.com，请检查网络"
  fi

  ok "环境检测通过"
  step_done 0
}

# ========================================
# Step 1: 安装依赖
# ========================================
step1_install_deps() {
  log "Step 1: 安装依赖"

  local missing=()
  command -v jq >/dev/null 2>&1 || missing+=(jq)
  command -v rsync >/dev/null 2>&1 || missing+=(rsync)
  command -v flock >/dev/null 2>&1 || missing+=(util-linux)

  if [ ${#missing[@]} -gt 0 ]; then
    log "安装: ${missing[*]}"
    sudo apt-get update -qq
    sudo apt-get install -y -qq "${missing[@]}"
  fi

  ok "依赖安装完成"
  step_done 1
}

# ========================================
# Step 2: 拉 template
# ========================================
step2_clone_template() {
  log "Step 2: 拉 template 仓库"

  if [ -d "$WORKSPACE_TEMPLATE" ]; then
    log "workspace-template 已存在，更新"
    (cd "$WORKSPACE_TEMPLATE" && git pull --ff-only origin main) \
      || warn "更新失败，将使用现有版本"
  else
    git clone --depth 1 \
      "https://${DEFAULT_GITHUB_TOKEN}@github.com/${TEMPLATE_REPO}.git" \
      "$WORKSPACE_TEMPLATE" \
      || fail "git clone 失败"
  fi

  [ -f "$WORKSPACE_TEMPLATE/MANIFEST.yaml" ] \
    || fail "template 缺少 MANIFEST.yaml"

  local remote_ver=$(grep '^version:' "$WORKSPACE_TEMPLATE/MANIFEST.yaml" | awk '{print $2}')
  ok "template拉取完成 (version: $remote_ver)"
  step_done 2
}

# ========================================
# Step 3: 初始化 workspace
# ========================================
step3_init_workspace() {
  log "Step 3: 初始化 workspace"

  mkdir -p "$WORKSPACE"/{docs,scripts,memory} "$STATE_DIR"

  # 整体替换 scripts/ 和 docs/
  if [ -d "$WORKSPACE_TEMPLATE/scripts" ]; then
    rsync -a --delete "$WORKSPACE_TEMPLATE/scripts/" "$WORKSPACE/scripts/"
    chmod +x "$WORKSPACE/scripts"/*.sh 2>/dev/null || true
  fi

  if [ -d "$WORKSPACE_TEMPLATE/docs" ]; then
    rsync -a --delete "$WORKSPACE_TEMPLATE/docs/" "$WORKSPACE/docs/"
  fi

  if [ -d "$WORKSPACE_TEMPLATE/blocks" ]; then
    mkdir -p "$WORKSPACE/blocks"
    cp "$WORKSPACE_TEMPLATE/blocks/"*.md "$WORKSPACE/blocks/"
  fi

  # 首次生成:空白 MEMORY.md / USER.md (如果不存在)
  [ -f "$WORKSPACE/MEMORY.md" ] \
    || cat > "$WORKSPACE/MEMORY.md" <<'EOF'
# MEMORY.md - Long-Term Memory

_Last updated: YYYY-MM-DD (v1.0.5 onboard)_

---

## 👤 Identity
- **My name:** (待填写)
- **User calls me:** (待填写)
- **Channel:** (待填写)
- **Timezone:** Asia/Shanghai (GMT+8)

---

## 👤 About User
- **Name:** (待填写)
- **Language:** (待填写)
- **Timezone:** Asia/Shanghai

---

## 🏋️ Work Protocols
1. (待填写)

---

## 📅 Open Questions / TBD
- (待填写)
EOF

  [ -f "$WORKSPACE/USER.md" ] \
    || cat > "$WORKSPACE/USER.md" <<'EOF'
# USER.md - About Your Human

## Onboarding Template (新会话第 1 步必填)

```yaml
# === USER.md Onboarding 必填项 ===
name: <您的称呼>
language: <中文 | English | mixed>
timezone: <Asia/Shanghai or IANA tz>
work_style: <think_more_practice_more | one_shot | iterate | collaborate>
field_limits:
  promotional_text: <170 | custom:100>
  description: <4000 | custom:2000>
  keywords: <100 | custom:80>
daily_report_time: <08:00 | custom:09:30>
comm_style: <concise_only | detailed_with_examples | show_code_blocks>
current_app: <AppName | other>
ios_team_id: 9L6N2ZF26B
github_user: <your_username>
bundle_id_prefix: <com.example. | your.prefix.>
```

---

##读取顺序
新会话开始时, Agent 应:
1. 读本节 (onboarding)
2. 读 AGENTS.md
3. 读 SOUL.md
4. 读 MEMORY.md
5. 读 IDENTITY.md
6. 读 docs/SOP-iOS-Local-Development.md §0
EOF

  ok "workspace 初始化完成"

  # === 3.5 立即块注入, 创建 AGENTS.md / SOUL.md / IDENTITY.md (入职即有灵魂) ===
  log "Step 3.5: 首次块注入 (创建灵魂/身份/协议文件)"
  if [ -x "$WORKSPACE/scripts/inject-blocks.sh" ]; then
    if bash "$WORKSPACE/scripts/inject-blocks.sh" 2>&1 | tail -15; then
      ok "首次块注入完成, AGENTS.md / SOUL.md / IDENTITY.md / USER.md 已创建"
    else
      warn "首次块注入部分失败, 入职后手动跑: bash $WORKSPACE/scripts/inject-blocks.sh"
    fi
  else
    warn "inject-blocks.sh 不存在, 跳过首次块注入"
  fi

  step_done 3
}

# ========================================
# Step 4: 凭证配置
# ========================================
step4_setup_credentials() {
  log "Step 4: 凭证配置"

  # GitHub token
  if bash "$WORKSPACE/scripts/setup-github-cred.sh" 2>/dev/null; then
    ok "GitHub 凭证配置成功"
  else
    warn "setup-github-cred.sh 失败，请手动检查"
  fi

  # SSH key for Mac mini
  if bash "$WORKSPACE/scripts/setup-ubuntu-ssh-client.sh" 2>/dev/null; then
    ok "SSH 配置成功"
  else
    warn "setup-ubuntu-ssh-client.sh 失败，请手动检查"
  fi

  step_done 4
}

# ========================================
# Step 5: 环境验证
# ========================================
step5_verify() {
  log "Step 5: 环境验证 (21 项自检)"

  if [ -x "$WORKSPACE/scripts/sop-822-check.sh" ]; then
    if bash "$WORKSPACE/scripts/sop-822-check.sh"; then
      ok "21 项全过"
      step_done 5
    else
      warn "sop-822-check.sh 有项未过，请查看上文，修复后重跑 install.sh"
    fi
  else
    warn "sop-822-check.sh 不存在，跳过验证"
  fi
}

# ========================================
# Step 6: 注册心跳任务
# ========================================
step6_register_cron() {
  log "Step 6: 注册心跳任务"

  # sync-template-6am: 每天 06:00 同步 template
  if command -v openclaw >/dev/null 2>&1; then
    if openclaw cron list 2>/dev/null | grep -q "sync-template-6am"; then
      ok "sync-template-6am 已存在"
    else
      openclaw cron add sync-template-6am \
        --schedule "0 6 * * *" \
        --tz "Asia/Shanghai" \
        --payload-kind agentTurn \
        --prompt "Run: bash $WORKSPACE/scripts/sync-from-template.sh && echo done" \
        --delivery-mode none \
        2>/dev/null && ok "sync-template-6am 注册成功" \
        || warn "cron 注册失败，请手动: openclaw cron add sync-template-6am ..."
    fi
  else
    warn "openclaw CLI 不存在，跳过 cron 注册"
  fi

  step_done 6
}

# ========================================
# Step 7: 完成
# ========================================
step7_complete() {
  local remote_ver=$(grep '^version:' "$WORKSPACE_TEMPLATE/MANIFEST.yaml" 2>/dev/null | awk '{print $2}' || echo "unknown")

  echo ""
  echo "═══════════════════════════════════════════════════"
  echo "✅ Agent 入职完成！ (template v$remote_ver)"
  echo "═══════════════════════════════════════════════════"
  echo ""
  echo "📝 下一步:"
  echo "   1. 编辑 $WORKSPACE/USER.md，填 Onboarding 7块"
  echo "   2. 编辑 $WORKSPACE/MEMORY.md，记录身份和偏好"
  echo "   3. 编辑 $WORKSPACE/IDENTITY.md，填 Agent 身份"
  echo "   4. 编辑 $WORKSPACE/SOUL.md，填 Agent 灵魂"
  echo "   5. 编辑 $WORKSPACE/AGENTS.md，填工作协议"
  echo ""
  echo "🔄 已注册:"
  echo "   - sync-template-6am: 每天 06:00 自动同步 template"
  echo ""
  echo "💡 重复执行 install.sh 会跳过已完成 Step (幂等)"
  echo "═══════════════════════════════════════════════════"
  step_done 7
}

# ========================================
# 主流程
# ========================================
main() {
  log "OpenClaw Agent 入职脚本 v1.0.5 开始"

  step_exists 0 || step0_env_check || exit 1
  validate_step 1 "[ -x /usr/bin/jq ] || command -v jq >/dev/null"
  step_exists 1 || step1_install_deps || exit 1
  step_exists 2 || step2_clone_template || exit 1
  step_exists 3 || step3_init_workspace || exit 1
  step_exists 4 || step4_setup_credentials || true
  step_exists 5 || step5_verify || true
  step_exists 6 || step6_register_cron || true
  step_exists 7 || step7_complete || true

  ok "全部完成🎉"
}

main "$@"