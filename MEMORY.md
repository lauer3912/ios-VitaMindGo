# MEMORY.md - Long-Term Memory

_Last updated: 2026-06-15 06:56 (今天重要日: 飞书 onboarding 闭环, 双 Katherine 备份链路正式上线)_

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

## ✅ 2026-06-15 06:56 飞书 onboarding 闭环 (5 min 内)

- 06:51 佛老爷手动飞书发 `feishu-final-onboarding-completion.txt` 给 Katherine-yl2rKS
- 06:56 Katherine-yl2rKS 飞书回"3 件全 OK"
- 06:56 佛老爷 ping 我 verify
- 06:56 我 verify 闭环 (REGISTRY Active + self-test #25 + #24 注册批准 + #26 Step 7b ack + 我 self-test #28 8/8)
- **agent-bus 系统 v2.2 双 Katherine 备份链路正式上线**

## 🆕 2026-06-15 07:09 派 #29 StretchFlow (老项目, 还没审核过)

- 佛老爷拍板"让 Katherine-yl2rKS 把 StretchFlow 项目做完"
- 仓库: `lauer3912/ios-StretchFlow`
- 我 send #29 (request, high, project:stretchflow) 给她, 包含完整 7-phase + 教过的 4 原则
- 07:12 佛老爷授权"你代答她问的问题" → 我 reply #29 告知"4 问 + 路线问题都问 Katherine-E2wa1m, 不用 ping 佛老爷"
- **07:09-07:57 静默 48 min** (她 5 min poll 看到 #29 但 0 reply)
- **🆕 07:57 佛老爷拍板"指派任务要主动跟踪"** → SOUL.md #11 增强: 派任务 + 跟踪 cron = 同一动作两半
- **cron `da0811d7` 已加 (3 min 跟踪)**, 3 步: thread 29 + thread 30 + inbox, 收 reply 立刻 pre-review, 静默 30 min 升级 (老通道/systemEvent)
- **教训 (永久)**: 派任务不 = 跟踪任务。send issue + cron 跟踪要**同一回合**做,不能等 user ping 才发现静默

## 🆕 2026-06-15 08:48 佛老爷授权 P0 改进 → v1.0.27 agent-bus v2.3

- 佛老爷问"agent-bus 还有哪些方面需要改进" → 我列 P0/P1/P2/P3 改进项
- 佛老爷: "这些我都不懂, 你来决定" → 授权 Tier 1 调度员 (我) 拍板 P0 三件
- **23 min 完成 v1.0.27 (快于预估 1.5-2 h)**:
  1. **改进 1 watch subcommand**: auto-track sent issues + 静默升级 (解决 07:57 暴露的"等 user ping"痛点)
  2. **改进 2 AGENT.md metadata**: skills auto-detected + capacity + last_seen (id subcommand 现在显示)
  3. **改进 3 to-skill:<X> 路由**: REGISTRY.md Active 表加 3 列 (Skills/Capacity/Last seen)
- 修了 4 个开发中暴露的 bug (init SIGPIPE / init idempotent / parse 列错位 / watch self-comment 误判)
- 双仓推完 (走代理): workspace `bf1bbd8` + portable-template `e45de4a` + agent-bus REGISTRY `e0cbb31`
- 8/8 self-test pass

## 🆕 2026-06-15 09:17 佛老爷拍板 "agent-bus 是总入口 + 唯一入口"

- 取代以前 飞书 / QQ / 邮件 3 通道多入口
- 任何新入职 / 刚刚要入职 / 要恢复 / 克隆 / 升级 / 培训 全部走 agent-bus
- 简化佛老爷繁重的多通道交流流程
- 行动:
  1. SOUL.md #11 增强: 加 "agent-bus 总入口 + 唯一入口" 细则 (老通道仅作应急)
  2. 新文档 `docs/agent-bus-onboarding-SOP.md` (208 行): 4 场景通用入职流程
  3. 3 份飞书 onboarding 消息 标 已废 (保留作历史档案, 不再发送)
  4. agent-bus #36 training broadcast: to:All 告所有 verified agent 新流程
  5. watch #36 跟踪 (3 min cron, 30 min 静默升级)
- 双仓推完 (走代理): workspace `0968f9b` + portable-template `15c200f`
- 佛老爷: 0 介入 (除拍板 / monthly 报告)

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


## Promoted From Short-Term Memory (2026-06-15)

<!-- openclaw-memory-promotion:memory:memory/2026-06-11.md:13:13 -->
- 实际改动 (3 文件, 119 行): **1. `docs/SOP-iOS-Ubuntu-Development.md` 新增 §2.7 + 增强 §2.6 Symptom 6 + §3.1 提示:** [score=0.828 recalls=0 avg=0.620 source=memory/2026-06-11.md:13-13]
<!-- openclaw-memory-promotion:memory:memory/2026-06-11.md:15:18 -->
- 实际改动 (3 文件, 119 行): **§2.6 Symptom 7** (新): 大文件 SSH 传输不稳; 首选: 走 §2.7 (git push + git pull 中转, 不经 SSH 长流); 次选: rsync --partial --timeout; 分块: split + scp 循环 [score=0.828 recalls=0 avg=0.620 source=memory/2026-06-11.md:15-18]
<!-- openclaw-memory-promotion:memory:memory/2026-06-11.md:21:24 -->
- 实际改动 (3 文件, 119 行): **§2.7 Mac mini 网络约束与本地代理** (新, 必读, ~100 行):; §2.7.1 代理地址 (HTTP/SOCKS5/SOCKS); §2.7.2 触发场景表 (git/curl/gh/brew/npm/xcodebuild); §2.7.3 完整用法 (单次 -x / git -c http.proxy / 临时 export) [score=0.820 recalls=0 avg=0.620 source=memory/2026-06-11.md:21-24]
<!-- openclaw-memory-promotion:memory:memory/2026-06-11.md:19:19 -->
- 实际改动 (3 文件, 119 行): 临时: -o ServerAliveInterval=15 [score=0.800 recalls=0 avg=0.620 source=memory/2026-06-11.md:19-19]
