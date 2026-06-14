#!/bin/bash
# ========================================
# OpenClaw: 块注入脚本 (一次性, 跳过 do_backup)
# ========================================
# 用途:
#   - 老 install.sh 入职后, AGENTS/SOUL/IDENTITY/USER 缺块标记
#   - 此脚本一次性补齐, 跳过 do_backup (老 sync 会卡 memory/)
#   - 跑完即可正常使用
#
# 用法:
#   bash inject-blocks.sh
#
# 参数 (可选):
#   bash inject-blocks.sh [workspace_dir]
#   bash inject-blocks.sh /root/.openclaw/workspace
#
# 幂等: 已有块标记的不重复注入
# ========================================
set -euo pipefail

WS="${1:-$HOME/.openclaw/workspace}"
TPL="${2:-$HOME/.openclaw/workspace-template}"

if [ ! -d "$WS" ]; then
  echo "❌ workspace 不存在: $WS" >&2
  echo "   传参: bash inject-blocks.sh /path/to/workspace" >&2
  exit 1
fi

if [ ! -d "$TPL/blocks" ]; then
  echo "❌ template blocks 不存在: $TPL/blocks" >&2
  echo "   应先跑 install.sh, 拉过 template" >&2
  exit 1
fi

echo "════════════════════════════════════════════"
echo "  OpenClaw 块注入"
echo "  workspace: $WS"
echo "  template:  $TPL/blocks"
echo "════════════════════════════════════════════"
echo ""

created=0
appended=0
skipped=0

for block_md in "$TPL/blocks/"*.md; do
  [ -f "$block_md" ] || continue
  block_id=$(basename "$block_md" .md)
  new_content=$(cat "$block_md")

  # 从 block 文件头部读 target
  target_file=$(grep -E "^target:" "$block_md" 2>/dev/null | awk '{print $2}')
  target_file="${target_file:-$WS/AGENTS.md}"
  case "$target_file" in
    "$WS"/*) ;;
    *) target_file="$WS/$target_file" ;;
  esac

  if [ ! -f "$target_file" ]; then
    cat > "$target_file" <<EOB
<!-- openclaw-block: $block_id -->
$new_content
<!-- /openclaw-block -->
EOB
    echo "✅ 创建 $(basename "$target_file") [$block_id]"
    created=$((created + 1))
  elif grep -q "<!-- openclaw-block: $block_id -->" "$target_file"; then
    echo "⏭️  $(basename "$target_file") [$block_id] 已存在"
    skipped=$((skipped + 1))
  else
    {
      echo ""
      echo "<!-- openclaw-block: $block_id -->"
      echo "$new_content"
      echo "<!-- /openclaw-block -->"
    } >> "$target_file"
    echo "✅ 追加 $block_id → $(basename "$target_file")"
    appended=$((appended + 1))
  fi
done

# 写版本号
echo "1.0.6" > "$WS/.template-version"

echo ""
echo "════════════════════════════════════════════"
echo "  完成: 创建 $created / 追加 $appended / 跳过 $skipped"
echo "════════════════════════════════════════════"
echo ""
echo "=== 验证 ==="
for f in AGENTS.md SOUL.md IDENTITY.md USER.md; do
  if [ -f "$WS/$f" ]; then
    cnt=$(grep -c "openclaw-block" "$WS/$f" 2>/dev/null || echo 0)
    echo "  $f: $cnt 个块"
  fi
done
echo ""
echo "🎉 现在 $WS/AGENTS.md 等 4 个文件应该有灵魂了"