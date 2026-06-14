#!/bin/bash
# ========================================
# OpenClaw 一键回滚脚本 v1.0.5
# ========================================
# 用法:
#   bash restore-from-backup.sh
#
# 行为:
#   - 列出最近 7 天备份
#   - 用户选一个
#   - 校验 sha256
#   - 解压恢复 scripts/docs/MANIFEST
# ========================================
set -euo pipefail

WORKSPACE="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
BACKUP_DIR="$WORKSPACE/.backups"

echo "═══════════════════════════════════════════════"
echo "OpenClaw 一键回滚"
echo "═══════════════════════════════════════════════"

if [ ! -d "$BACKUP_DIR" ]; then
  echo "❌ 无备份目录: $BACKUP_DIR"
  exit 1
fi

mapfile -t backups < <(ls -t "$BACKUP_DIR"/pre-sync-*.tar.gz 2>/dev/null)

if [ ${#backups[@]} -eq 0 ]; then
  echo "❌ 没有备份 (7 天内)"
  exit 1
fi

echo ""
echo "可用备份 (最近 7 天):"
echo ""
for i in "${!backups[@]}"; do
  local ts=$(stat -c '%y' "${backups[$i]}" 2>/dev/null | cut -d. -f1 \
    || ls -l --time-style=+%Y-%m-%d\ %H:%M "${backups[$i]}" | awk '{print $6, $7}')
  echo "  [$i] $(basename "${backups[$i]}")  ($ts)"
done
echo ""
read -p "选哪个? [0-${#backups[@]}-1] (输入 q退出) " idx
echo ""

if [ "$idx" = "q" ] || [ "$idx" = "Q" ]; then
  echo "取消"
  exit 0
fi

if ! [[ "$idx" =~ ^[0-9]+$ ]] || [ "$idx" -ge ${#backups[@]} ]; then
  echo "❌ 无效选择: $idx"
  exit 1
fi

backup="${backups[$idx]}"

# 校验 sha256
if [ -f "${backup}.sha256" ]; then
  echo "校验备份..."
  if ! sha256sum -c "${backup}.sha256" 2>/dev/null; then
    echo "❌ 备份损坏 (sha256 不一致)，请手动处理"
    exit 1
  fi
  echo "✅ 校验通过"
fi

# 解压
echo "恢复中..."
tar xzf "$backup" -C "$WORKSPACE" \
  scripts docs MANIFEST.yaml \
  AGENTS.md SOUL.md IDENTITY.md USER.md MEMORY.md \
  2>/dev/null && chmod +x "$WORKSPACE/scripts"/*.sh 2>/dev/null || true

echo ""
echo "✅ 已恢复到: $(basename "$backup")"
echo "📝 如需恢复 workspace根目录的其他文件，请手动解压备份文件"