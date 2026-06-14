#!/bin/bash
# ========================================
# 每日备份 agent-bus config 到 GitHub (防硬挂)
# ========================================
# 用法: 配 cron 每天跑 1 次
#   0 3 * * * /home/$USER/.openclaw/workspace/scripts/backup-config-to-github.sh
#
# 备份:
#   - ~/.config/agent-bus/config → 个人 backup 仓 (e.g. lauer3912/agent-bus-config-backup)
#   - 加 README: 这是谁的备份 (AGENT_ID), 哪天备份
#
# 恢复: clone 那个 backup 仓, 拷 config 回 ~/.config/agent-bus/
# ========================================

set -euo pipefail

CONFIG_DIR="$HOME/.config/agent-bus"
CONFIG_FILE="$CONFIG_DIR/config"
BACKUP_REPO="${AGENT_CONFIG_BACKUP_REPO:-lauer3912/agent-bus-config-backup}"
BACKUP_BRANCH="${AGENT_CONFIG_BACKUP_BRANCH:-main}"

[[ -f "$CONFIG_FILE" ]] || { echo "✗ no config at $CONFIG_FILE" >&2; exit 1; }
command -v gh >/dev/null 2>&1 || { echo "✗ gh not installed" >&2; exit 1; }

# Load config
# shellcheck source=/dev/null
source "$CONFIG_FILE"

# Make a temp dir for the backup commit
TMP=$(mktemp -d)
cd "$TMP"
gh repo clone "$BACKUP_REPO" repo 2>/dev/null || { gh repo create "$BACKUP_REPO" --private --description "Per-agent agent-bus config backup (auto-daily)"; gh repo clone "$BACKUP_REPO" repo; }
cd repo

# Path: backups/<AGENT_ID>/config + last-backup-date.txt
mkdir -p "backups/$AGENT_ID"
cp "$CONFIG_FILE" "backups/$AGENT_ID/config"
date -u +"%Y-%m-%dT%H:%M:%SZ" > "backups/$AGENT_ID/last-backup.txt"

# README (first time)
if [[ ! -f README.md ]]; then
  cat > README.md <<EOF
# agent-bus config backup (auto-daily)

Each agent's config is auto-pushed here daily. To restore:
1. Find your AGENT_ID in \`backups/\`
2. \`cp backups/\$AGENT_ID/config ~/.config/agent-bus/config\`
3. Re-run \`agent-bus verify\` to confirm

This is the **last line of defense** for hard crash recovery.
EOF
fi

git add "backups/$AGENT_ID/" README.md 2>/dev/null || true
git add -A
if git diff --cached --quiet; then
  echo "✓ no changes (config unchanged since last backup)"
  cd /
  rm -rf "$TMP"
  exit 0
fi

git -c user.name="agent-bus-backup" \
    -c user.email="backup@openclaw.local" \
    commit -m "backup: $AGENT_ID @ $(date -u +%Y-%m-%dT%H:%M:%SZ)" >/dev/null
git push origin "$BACKUP_BRANCH" 2>&1 | tail -1

cd /
rm -rf "$TMP"

echo "✓ backed up $AGENT_ID to $BACKUP_REPO"
