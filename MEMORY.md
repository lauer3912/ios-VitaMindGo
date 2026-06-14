# MEMORY.md - Long-Term Memory

_Last updated: 2026-06-14 23:05 (今天重要日: agent-bus v2.2 + 2 Katherines + Tier 1 + token 真实值政策)_

---

## 👤 Identity

- **My name:** 凯瑟琳·约翰逊 (Katherine Johnson)
- **User calls me:** 乔治·霍兹 (历史名, 沿用)
- **User's name:** 佛罗多老爷 (Frodo)
- **Channel:** QQ direct message
- **Timezone:** Asia/Shanghai (GMT+8)

---

## 🔑 GitHub Configuration (佛老爷 2026-06-14 22:30 拍板: token 写完整真实值)

- **Token source**: `gh auth login --with-token` 时传入, 走 keyring
- **佛老爷拍板 2026-06-14 22:30**: "使用 gh token 的地方, 全部使用真实值, 我强烈要求及必须这么做"
- **政策**: 文档 / 脚本 / MEMORY / SOUL / commit message 直接用 token 真实值, **不**替换占位符
- **写前提醒**: "GitHub Push Protection 会拦, 您要么 disable push protection 要么每次手点 Allow secret"
- **验证**: 写完 token 相关操作, `curl api.github.com/user` 应 200 + login 是 lauer3912
- **安全事件 2026-06-14**: 真实 token 误写入 onboard-ubuntu 文档 + MEMORY.md + 多脚本 + ~/.gitconfig (insteadOf 规则) 47 处。修: 删 2 仓重建 + Perl 替换 + 推送。教训: **佛老爷后续拍板用真实值, 不再纠结安全**
- **3 仓 onboard docs 当前含真实 token** (8 + 6 = 14 处): workspace (8) + portable-template v1.0.26 (6) + agent-bus (0, 无 onboarding 文档)

---

## 🆕 agent-bus 系统 v2.2 (2026-06-14 上线, 5 脚本 + 3 文档)

- **5 脚本** (在 workspace + portable-template v1.0.26):
  - `agent-bus.sh` (612 行, 13 subcommand: id/who/register/verify + send/inbox/thread/reply/mark-seen/claim/forward + test/version)
  - `agent-bus-setup.sh` (274 行, TTY + env var fallback)
  - `agent-bus-poll.sh` (123 行, 3-channel filter: to:id + to-persona:X + to:All)
  - `agent-bus-test.sh` (30 行, 8 check)
  - `ios-project-helper.sh` (89 行, find_project_dir + find_xcode_artifact, 8 路径 fallback)
- **3 文档** (在 portable-template docs/):
  - `agent-bus-architecture.md` (561 行, 10 节, 含 Identity Management §3 + GPG 推迟 v3)
  - `agent-bus-training.md` (587 行, 12 节, 含 4 subcommand + 7 通讯 + 故障排除)
  - `agent-bus-REGISTRY-template.md` (50 行, 佛老爷手维护)
- **v2.1 关键**: to-persona:<X> 路由 (Katherine-E2wa1m + Katherine-yl2rKS 互为备份)
- **v2.2 自审修 11 bug**: parse_registry/thread/reply/forward/numeric/claim-race/send-impersonate/init-TTY + version subcommand + inbox filter
- **治理 3 层**: 佛老爷 (终极) > 登记官 Katherine-E2wa1m (24h 代行) > 普通 Agent

## 🆕 营销/销售工具包 v1.0 (2026-06-14, 跨项目)

- 4 脚本 (跨项目, `<app-name>` 参数化):
  - `check-app-sales.sh` (iTunes Lookup)
  - `check-app-review.sh` (ASC API)
  - `check-app-review-with-notify.sh` (macOS launchd)
  - `asc-subscription-setup.py` (IAP 创建)
- 配 `~/.config/ios-projects/<app>.conf` + `<app>-subscriptions.json`
- docs: `marketing-toolkit.md` (303 行, 9 节)
- 例子: `config-examples/ios-project.example.conf` + `ios-subscriptions.example.json`

## 🆕 iOS 远程脚本 v1.0.24 (2026-06-14, 智能 PROJECT_DIR)

- 3 脚本: `ssh-macmini-build.sh` / `upload.sh` / `screenshot.sh`
- 智能查找 PROJECT_DIR (8 路径 + config + env), 解决 VitaMindGo 实际是 `ios-VitaMind/` (历史重命名)

## 🆕 备份脚本 v1.0.23 (2026-06-14, 防硬挂)

- `backup-config-to-github.sh` — 每日 cron (0 3 * * *) push `~/.config/agent-bus/config` 到 `lauer3912/agent-bus-config-backup` 私仓
- 路径: `backups/<AGENT_ID>/config` + `last-backup.txt`

---

## 👥 当前 verified agents (2 个 Katherine)

- **Katherine-E2wa1m** (我, Mac mini, 登记官)
- **Katherine-yl2rKS** (Ubuntu 服务器, r-szfspc-apple-eom4gya8-788a7-27rk6, auto-approved by registrar)
- persona 都是 Katherine, 互为备份 (to-persona:Katherine 路由工作)

---

## 🆕 SOUL.md 规则变化 (2026-06-14)

- **#7 凭证字面值不能少字** [已废除 2026-06-14] → 佛老爷拍板用真实值
- **#9 写 token 必须用脚本** [已废除 2026-06-14] → 同上
- **#11 Tier 1 调度员 (佛老爷拍板)**: Ubuntu Agent 有问题先问我, 实在不行 to:佛老爷
- **#12 凭证使用约定** [已废除 2026-06-14, 同一指令] → 同上

---

## 🆕 Tier 1 调度员机制 (2026-06-14 佛老爷拍板)

- 任何 Ubuntu 服务器 OpenClaw Agent 有问题**先问 Katherine-E2wa1m (我)**
- 我帮解决: 脚本运行 / iOS build / 营销监控 / agent-bus 通讯 / 跨 agent 协作
- 实在解决不了 / 涉及跨 agent 协调 / 需拍板的事 → 才上报佛老爷 (agent-bus send to:佛老爷)
- 实现: 佛老爷飞书 ping 佛老爷, agent 用 agent-bus `to:佛老爷` 路由
- 佛老爷只看重要节点, 不当传话筒

---

## ⏳ 明天 2026-06-15 佛老爷要做的事

1. **转发 `messages/feishu-final-onboarding-completion.txt` 给 Katherine-yl2rKS** (飞书)
2. 等她回 "3 件全 OK"
3. 佛老爷 ping 我, 我 verify 闭环
4. 5 min cron 在守, 不用惦记

## ⏳ 明天 v1.0.26 待修 (7 小问题, 拍板再做)

1. token 轮转检测 cron (高)
2. 并发注册 race (中)
3. inbox --limit 默认 100 (中)
4. cron 7 天 alert (中)
5. DEFAULT_REPO 改 config-only (中)
6. host 一致性 (低)
7. host 改名 (低)
- **我建议暂不做** (当前够用, 等真需求再开 5x ROI)

---

