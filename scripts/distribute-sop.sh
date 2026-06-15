#!/bin/bash
# ========================================
# OpenClaw: 打包 SOP 给新机器 (支持 private repo 模式)
# ========================================
# 用法: sudo bash distribute-sop.sh [output_dir]
# 默认: ~/.openclaw/workspace/dist/openclaw-portable-template/
# 行为:
#   - 8步打包
#   - 自动递增 MANIFEST.yaml 版本号
#   - 拷贝 scripts/ + docs/ + install.sh + blocks/ + agent-onboarding-design.md
#   - 重打包后需 force push 更新 GitHub
# ========================================

set -euo pipefail

# --- 0. 内置 token ---
DEFAULT_GITHUB_TOKEN="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"

# --- 配置 ---
WORKSPACE="${WORKSPACE:-$HOME/.openclaw/workspace}"
OUTPUT_DIR="${1:-$WORKSPACE/dist/openclaw-portable-template}"

echo "════════════════════════════════════════════════"
echo "  OpenClaw: 打包 SOP 到 private repo 模板"
echo "════════════════════════════════════════════════"
echo "  Source: $WORKSPACE"
echo "  Output: $OUTPUT_DIR"
echo ""

# --- 1. 创建输出目录 ---
echo "=== [1/8] 创建输出目录 ==="
mkdir -p "$OUTPUT_DIR/docs"
mkdir -p "$OUTPUT_DIR/scripts"
mkdir -p "$OUTPUT_DIR/examples/.github/workflows"
mkdir -p "$OUTPUT_DIR/blocks"
echo "✅ $OUTPUT_DIR 目录结构就绪"

# --- 2. 升级 MANIFEST.yaml 版本号 ---
echo ""
echo "=== [2/8] 拷贝 MANIFEST.yaml ==="
if [ -f "$WORKSPACE/MANIFEST.yaml" ]; then
  cp "$WORKSPACE/MANIFEST.yaml" "$OUTPUT_DIR/MANIFEST.yaml"
  echo "  ✅ MANIFEST.yaml 源 → 输出目录"
else
  echo "  ⚠️  workspace/MANIFEST.yaml 不存在"
fi

# --- 2.5. 变更检测 + 智能 bump ---
echo ""
echo "=== [2.5/8] 检测变更 + 智能 bump 版本 ==="

# 统计变更: 新增 / 修改 / 删除
new_scripts=0
mod_scripts=0
new_blocks=0
mod_blocks=0
new_docs=0
mod_docs=0
mod_install=0
mod_manifest=0

# 脚本变化
for f in "$WORKSPACE"/scripts/*; do
  [ -f "$f" ] || continue
  base=$(basename "$f")
  if [ ! -f "$OUTPUT_DIR/scripts/$base" ]; then
    new_scripts=$((new_scripts + 1))
  elif ! cmp -s "$f" "$OUTPUT_DIR/scripts/$base" 2>/dev/null; then
    mod_scripts=$((mod_scripts + 1))
  fi
done

# 块变化
for f in "$WORKSPACE"/blocks/*; do
  [ -f "$f" ] || continue
  base=$(basename "$f")
  if [ ! -f "$OUTPUT_DIR/blocks/$base" ]; then
    new_blocks=$((new_blocks + 1))
  elif ! cmp -s "$f" "$OUTPUT_DIR/blocks/$base" 2>/dev/null; then
    mod_blocks=$((mod_blocks + 1))
  fi
done

# 文档变化
for f in "$WORKSPACE"/docs/*; do
  [ -f "$f" ] || continue
  base=$(basename "$f")
  if [ ! -f "$OUTPUT_DIR/docs/$base" ]; then
    new_docs=$((new_docs + 1))
  elif ! cmp -s "$f" "$OUTPUT_DIR/docs/$base" 2>/dev/null; then
    mod_docs=$((mod_docs + 1))
  fi
done

# install.sh / MANIFEST.yaml
if [ -f "$WORKSPACE/install.sh" ] && [ -f "$OUTPUT_DIR/install.sh" ]; then
  cmp -s "$WORKSPACE/install.sh" "$OUTPUT_DIR/install.sh" 2>/dev/null || mod_install=1
fi

total_changes=$((new_scripts + mod_scripts + new_blocks + mod_blocks + new_docs + mod_docs + mod_install))

if [ $total_changes -eq 0 ]; then
  echo "  ⚠️  未检测到变更 (workspace 源 与 OUTPUT_DIR 一致)"
  echo "  → 不 bump 版本号"
  echo ""
  echo "=== [2.6/8] 跳过 (无变更) ==="
else
  echo "  检测到变更:"
  [ $new_scripts -gt 0 ] && echo "    + scripts: 新增 $new_scripts 个"
  [ $mod_scripts -gt 0 ] && echo "    ~ scripts: 修改 $mod_scripts 个"
  [ $new_blocks -gt 0 ] && echo "    + blocks: 新增 $new_blocks 个"
  [ $mod_blocks -gt 0 ] && echo "    ~ blocks: 修改 $mod_blocks 个"
  [ $new_docs -gt 0 ] && echo "    + docs: 新增 $new_docs 个"
  [ $mod_docs -gt 0 ] && echo "    ~ docs: 修改 $mod_docs 个"
  [ $mod_install -gt 0 ] && echo "    ~ install.sh 修改"
  echo ""

  # 智能 bump
  if [ -f "$OUTPUT_DIR/MANIFEST.yaml" ]; then
    local_ver=$(grep '^version:' "$OUTPUT_DIR/MANIFEST.yaml" | awk -F'"' '{print $2}')
    last_part=${local_ver##*.}
    major_part=${local_ver%.*}
    new_minor=$((last_part + 1))
    new_ver="${major_part}.${new_minor}"
    new_ts=$(date +%Y-%m-%dT%H:%M:%S+08:00)
    sed -i.bak \
      -e "s/^version:.*/version: \"$new_ver\"/" \
      -e "s/^last_updated:.*/last_updated: \"$new_ts\"/" \
      "$OUTPUT_DIR/MANIFEST.yaml"
    rm -f "$OUTPUT_DIR/MANIFEST.yaml.bak"
    echo "  $local_ver → $new_ver (last_updated → $new_ts)"
  fi
fi

# --- 3. 拷贝文档 ---
echo ""
echo "=== [3/8] 拷贝文档 ==="
SOP_FILES=(
  "SOP-iOS-Ubuntu-Development.md"
  "iPad-Screenshot-Recipe.md"
  "agent-collaboration-best-practices.md"
  "2026-2028-iOS-App-Up.md"
  "AGENTS-injection.md"
)

for f in "${SOP_FILES[@]}"; do
  if [ -f "$WORKSPACE/docs/$f" ]; then
    cp "$WORKSPACE/docs/$f" "$OUTPUT_DIR/docs/"
    echo "  ✅ docs/$f"
  else
    echo "  ⚠️  docs/$f 不存在，跳过"
  fi
done

# agent-onboarding-design.md
if [ -f "$WORKSPACE/docs/agent-onboarding-design.md" ]; then
  cp "$WORKSPACE/docs/agent-onboarding-design.md" "$OUTPUT_DIR/docs/"
  echo "  ✅ docs/agent-onboarding-design.md"
fi

# macmini-network-recipe.md (Mac mini 代理 + SSH 大文件传输操作卡, 2026-06-11)
if [ -f "$WORKSPACE/docs/macmini-network-recipe.md" ]; then
  cp "$WORKSPACE/docs/macmini-network-recipe.md" "$OUTPUT_DIR/docs/"
  echo "  ✅ docs/macmini-network-recipe.md"
fi

# v3.1.0-IAP-Plan.md (VitaMindGo IAP/订阅商业化方案, 2026-06-11)
if [ -f "$WORKSPACE/docs/v3.1.0-IAP-Plan.md" ]; then
  cp "$WORKSPACE/docs/v3.1.0-IAP-Plan.md" "$OUTPUT_DIR/docs/"
  echo "  ✅ docs/v3.1.0-IAP-Plan.md"
fi

# --- 4. 拷贝脚本 ---
echo ""
echo "=== [4/8] 拷贝脚本 ==="
SCRIPT_FILES=(
  "setup-ubuntu-ssh-client.sh"
  "setup-macos-ssh-host.sh"
  "setup-github-cred.sh"
  "ssh-macmini-build.sh"
  "ssh-macmini-upload.sh"
  "ssh-macmini-screenshot.sh"
  "onboard-new-ubuntu.sh"
  "setup-config.sh"
  "sop-822-check.sh"
  "asc-api-query.sh"
  "check-vitamindgo-review.sh"
  "check-vitamindgo-review-with-notify.sh"
  "check-vitamindgo-sales.sh"
  "com.openclaw.vitamindgo-review.plist"
  "sync-from-template.sh"
  "check-template-version.sh"
  "restore-from-backup.sh"
  "agent-bus.sh"
  "agent-bus-setup.sh"
  "agent-bus-poll.sh"
  "agent-bus-watch.sh"
  "agent-bus-test.sh"
  "distribute-sop.sh"
)

for f in "${SCRIPT_FILES[@]}"; do
  if [ -f "$WORKSPACE/scripts/$f" ]; then
    cp "$WORKSPACE/scripts/$f" "$OUTPUT_DIR/scripts/"
    chmod +x "$OUTPUT_DIR/scripts/$f"
    echo "  ✅ scripts/$f"
  else
    echo "  ⚠️  scripts/$f 不存在，跳过"
  fi
done

# --- 5. 拷贝 CI workflow 模板 ---
echo ""
echo "=== [5/8] 拷贝 CI workflow 模板 ==="
if [ -f "$WORKSPACE/examples/.github/workflows/ios-verify.yml" ]; then
  cp "$WORKSPACE/examples/.github/workflows/ios-verify.yml" \
     "$OUTPUT_DIR/examples/.github/workflows/"
  echo "  ✅ examples/.github/workflows/ios-verify.yml"
else
  echo "  ⚠️  ios-verify.yml 不存在，跳过"
fi

# --- 6. 拷贝 install.sh 和 blocks/ ---
echo ""
echo "=== [6/8] 拷贝 install.sh + blocks/ ==="
if [ -f "$WORKSPACE/install.sh" ]; then
  cp "$WORKSPACE/install.sh" "$OUTPUT_DIR/install.sh"
  chmod +x "$OUTPUT_DIR/install.sh"
  echo "  ✅ install.sh ($(wc -l < "$WORKSPACE/install.sh") 行)"
else
  echo "  ⚠️  install.sh 不存在，跳过"
fi

if [ -d "$WORKSPACE/blocks" ]; then
  cp "$WORKSPACE/blocks/"*.md "$OUTPUT_DIR/blocks/"
  blocks_count=$(ls "$OUTPUT_DIR/blocks/"*.md 2>/dev/null | wc -l | tr -d ' ')
  echo "  ✅ blocks/ ($blocks_count 个块文件)"
else
  echo "  ⚠️  blocks/ 不存在，跳过"
fi

# --- 7. 写 .gitignore ---
echo ""
echo "=== [7/8] 写 .gitignore ==="
cat > "$OUTPUT_DIR/.gitignore" << 'EOF'
# macOS
.DS_Store
*.swp
._*

# 编辑器
.vscode/
.idea/
*.swp
*~

# 敏感 (绝对不能 push)
*.pem
*.p8
*.p12
*.key
id_*
authorized_keys
*.env
.git-credentials

# Agent 配置 (每台 Ubuntu 唯一, 不入 git)
openclaw.config

# 临时
*.log
*.tmp
/tmp/
build/
DerivedData/
xcuserdata/

# Template sync状态文件
.template-version
.sync-log
.sync-failed
.install-state/
.backups/
EOF
echo "  ✅ .gitignore"

# --- 8. 完成摘要 ---
echo ""
echo "=== [8/8] 完成摘要 ==="
if [ -f "$OUTPUT_DIR/MANIFEST.yaml" ]; then
  ver=$(grep '^version:' "$OUTPUT_DIR/MANIFEST.yaml" | awk -F'"' '{print $2}')
  ts=$(grep '^last_updated:' "$OUTPUT_DIR/MANIFEST.yaml" | awk -F'"' '{print $2}')
  echo "  MANIFEST: v$ver ($ts)"
fi
echo "  scripts/: $(ls "$OUTPUT_DIR/scripts/"*.sh 2>/dev/null | wc -l | tr -d ' ') 个脚本"
echo "  docs/: $(ls "$OUTPUT_DIR/docs/"*.md 2>/dev/null | wc -l | tr -d ' ') 个文档"
echo "  blocks/: $(ls "$OUTPUT_DIR/blocks/"*.md 2>/dev/null | wc -l | tr -d ' ') 个块"

# --- 完成 ---
echo ""
echo "════════════════════════════════════════════════"
echo "  ✅ 打包完成"
echo "════════════════════════════════════════════════"
echo ""
echo "  Next:"
echo "    1. cd $OUTPUT_DIR && git add -A && git commit -m \"v$(grep '^version:' $OUTPUT_DIR/MANIFEST.yaml | awk -F'\"' '{print $2}')\""
echo "    2. git push origin main --force"
echo "    3. 新 Ubuntu agent 跑: curl -fsSL -H \"Authorization: token \$TOKEN\" \\"
echo "       https://raw.githubusercontent.com/lauer3912/openclaw-portable-template/main/install.sh | bash"
echo ""