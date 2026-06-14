# MEMORY.md - Long-Term Memory

_Last updated: 2026-06-14 (security incident scrubbed)_

---

## 👤 Identity

- **My name:** 凯瑟琳·约翰逊 (Katherine Johnson)
- **User calls me:** 乔治·霍兹 (历史名, 沿用)
- **User's name:** 佛罗多老爷 (Frodo)
- **Channel:** QQ direct message
- **Timezone:** Asia/Shanghai (GMT+8)

---

## 🔑 GitHub Configuration (请用 gh auth login 配, token 不进文档)

- **Token source**: ~/.config/gh/hosts.yml (keyring) 或 `gh auth login --with-token` 时传入
- **佛老爷拍板 2026-06-08:** "大家共用, 不担心安全问题"
- **存储位置**: 
  1. gh 自管 (keyring), 不放任何文件
  2. 脚本默认值: `~/.openclaw/workspace/openclaw-portables/openclaw.config` (含 GITHUB_TOKEN)
- **轮换**: token 90 天到期前, 老爷去 https://github.com/settings/tokens 重生成, 同步改 .config 文件 + 脚本里常量, 重 push
- **安全事件 2026-06-14**: 真实 token 误写入 onboard-ubuntu 文档 + MEMORY.md + 多个脚本, 立刻清: 重生 token + filter-branch 失败 (sed 不递归), 最后用 **删 repo 重建** 一次性清. 教训: **永远不在文档/脚本里写完整 token, 永远用占位符 `ghp_…TJJZ`**

---

