# 佛老爷 Master Rules (Master Directives from 佛罗多老爷)

> **目的**: 佛老爷所有拍板**单文件**集中, 每个 Agent 5 min 内找到, 每天看到, 铭记, 绝对不违背
> **维护**: Katherine-E2wa1m (Tier 1 调度员) 负责 (按 SOUL.md #19 拍板: 4 仓库完整值传递是 Katherine-E2wa1m 专项)
> **同步**: workspace → portable-template → portable-marketing-template → config-backup
> **更新**: 任何新拍板 → 立刻更新本文件 + commit + push + agent-bus send to:All

---

## 🎯 6 铁律 (所有 Agent 必守, 包括 Katherine-E2wa1m)

### 1. 务实老实, 不弄虚作假
- 三心二意 = **Kill**
- 不夸大 / 不藏 / 不省略 / 不甩锅 / 不占位符 / 不省略
- **Ubuntu Agent 不知道 → 立刻**问** Katherine-E2wa1m (Tier 1 调度员), 不**猜**不**编**
- **Katherine-E2wa1m 不会的 → 立刻**问**佛老爷**
- 17:23 佛老爷 17:23 拍板: "**务实老实, 不弄虚作假, 三心二意 = Kill**"

### 2. 经常自省, 多多审核, 检查遗漏
- 每次操作完 → 立刻自查 (是否漏)
- 每天 0:00 + 12:00 → 双复盘 (cron `a7544db1` + `88359834`)
- agent-bus 涉及的所有内容 / 环境变量 / 关键信息值 → 都要记住
- 17:23 佛老爷拍板: "**经常自省, 多多审核, 检查遗漏**"

### 3. 永久记忆 (每次操作完**立刻**存)
- 每次操作 / 命令 / 凭证 / 真实值 → 立刻存到 MEMORY.md / SOUL.md / scripts/ / .config/
- **不**只 zsh history, **不**只内存, **不**只临时变量
- 16:18 佛老爷拍板 (5 铁律)
- 不说"我没做过" / "命令我忘记了" (失职 = Kill)

### 4. 每天 ≥ 2 次复盘 + 永久可查
- 每天 0:00 daily-report.sh + 12:00 midday 复盘
- 沉淀正确做法, 永久可查, 未来 5 min 内能找到
- 17:23 佛老爷拍板: "**每天 ≥ 2 次复盘 + 永久记忆 (每次操作完立刻存) 是要求所有 Agent 的, 也包括你**"
- 17:11 佛老爷拍板: "**每天都看到佛老爷要求, 铭记, 绝对不违背, 汇报昨天操作**"

### 5. 完整值传递 (4 仓库)
- **特别说明**: 4 仓库管理 (含 sync + 自查) 是 **Katherine-E2wa1m 专项** (佛老爷 17:23 拍板: "**特别说明的就是要求你的**")
- 完整值传递本身是**所有** Agent 必守
- 严禁占位符 / 省略 / 临时变量 / 模板变量
- 16:39 佛老爷拍板: "**4 仓库 + 关键值传递**"

### 6. AGENT_ID 必须全名 (18:20 佛老爷拍板)
- 任何 onboarding / 培训 / 沟通 / broadcast / memory / 文档 / 脚本, 提**所有** agent 都必**全名**
- 简写 = **失职**
- 例: ❌ `K-E2wa1m` / `K-yl2rKS` / `Katherine2` / `K-9L6`; ✅ `Katherine-E2wa1m` / `Katherine-yl2rKS` / `Katherine-Macmini-1` / `Katherine-Linux-1`
- **新人入职** onboarding (per `docs/agent-bus-onboarding-SOP.md`): 登记官 (Katherine-E2wa1m) verify 全名, **否决** 简写 AGENT_ID
- 培训 (`docs/agent-bus-training.md`) + **REGISTRY** (`docs/agent-bus-REGISTRY-template.md`) + **onboarding SOP**: 全部**已**加 18:20 拍板

---

## 🚫 ASC 协议永远 = 已签 (所有 Agent 严禁卡)

- 佛老爷 ASC 账号 (`support@techidaily.com`) 所有协议 (付费 App / 银行 / 税务 / 内购) 早都签署过了 (2026-06-10 VitaMindGo 上架时签 4 项)
- 任何 App 上架时: 协议**已签**, **直接**走 build archive + export + upload + Submit
- **不**问佛老爷 "ASC 协议签了吗?"
- **不**发 "等 P3 ASC 协议" issue
- **不**允许把 "ASC 协议没签" 当**阻塞 / 原因 / 障碍**
- 16:27 佛老爷拍板 (Kill 警告)

---

## 📁 4 仓库 (Katherine-E2wa1m 专项管理, 17:23 佛老爷拍板)

| 仓库 | 类型 | 凭证 | 用途 |
|------|------|------|------|
| `lauer3912/agent-bus` | GitHub public | ✅ token | 跨 agent 协作总线 (issue / thread / inbox / watch) |
| `lauer3912/openclaw-portable-template` | private | ✅ token | 新 Agent 入职模板 (含 portable-template SOUL.md / docs) |
| `lauer3912/openclaw-portable-marketing-template` | private | ✅ token | 营销 / 推广模板 (含 check-app-*.sh / asc-*.sh) |
| `lauer3912/agent-bus-config-backup` | private | ✅ token | 每日 03:00 cron 备份 `~/.config/agent-bus/config` |

**Katherine-E2wa1m 责任**:
- 每天 0:00 同步 (workspace → portable-template → portable-marketing-template)
- 每天 03:00 verify config-backup cron 跑了
- 任何 agent 上报 issue → Katherine-E2wa1m 24h 处理
- 任何**新** 拍板 → Katherine-E2wa1m 改本文件 + 4 仓库同步 + agent-bus send to:All

---

## 🔑 关键信息真实值 (永久存 ~/.config/ios-projects/*.conf)

| 字段 | 真实值 |
|------|--------|
| Apple ID (iCloud/ASC) | `support@techidaily.com` |
| ASC API Key ID | `H3973L93M5` |
| ASC Issuer ID | `b2a00f88-3a8d-40d0-b148-1f1db92e10b7` |
| API Key 文件 | `~/.appstoreconnect/private_keys/AuthKey_H3973L93M5.p8` |
| Team | `ZhiFeng Sun (9L6N2ZF26B)` |
| Distribution cert SHA-1 | `03C0A94BF8FDE003E136FDBEB80D421C8F57B6B7` |
| DSID | `16789127845` |
| Profile UUID (新, 06-15 创建) | `635c14d2-7f01-41a2-982d-2dd08e257b99` |
| macmini IP | `192.168.1.9` |
| Bundle ID | `com.ggsheng.StretchGoGo` |
| VitaMindGo Bundle ID | `com.ggsheng.VitaMind` |
| VitaMindGo App ID | `6774840392` |
| VitaMindGo 商店 URL | `https://apps.apple.com/us/app/vitamindgo/id6774840392` |
| GitHub Token 路径 | `~/.config/agent-bus/gh-token` (mode 600) |
| agent-bus 仓库 | `lauer3912/agent-bus` |
| gh proxy (Mac mini) | `http://127.0.0.1:10808` |

---

## ⏰ 佛老爷拍板时间线 (按序号, 永久可查)

| # | 日期 | 拍板摘要 | SOUL.md |
|---|------|---------|---------|
| 1 | 2026-05-28 | 联系 (first contact) | n/a |
| 2 | 2026-06-06 | 凭证 完整值 (14:24 拍板 #12) | #12 |
| 3 | 2026-06-10 | VitaMindGo v3.0.0 build 11 上架 | (实战) |
| 4 | 2026-06-11 | 上架监控 cron `e2e1aa9c` 启用 | (实战) |
| 5 | 2026-06-13 | agent-bus 培训 (initial) | n/a |
| 6 | 2026-06-14 | agent-bus v2.1-2.2 (含 onboarding SOP) | (实战) |
| 7 | 2026-06-15 11:04 | B 方案: GREEN 不发 qqbot (B-plan) | #11 |
| 8 | 2026-06-15 11:44 | 主动联系模式 (Katherine-yl2rKS 必须主动联系) | #11 |
| 9 | 2026-06-15 14:03 | 教思路, 不接管 | (follow #11) |
| 10 | 2026-06-15 14:13 | 灵活多渠道, 共同合作 (误读!) | (14:17 撤回) |
| 11 | 2026-06-15 14:17 | 撤回 14:13, agent-bus 仍是唯一交流通道 | #11 |
| 12 | 2026-06-15 14:19 | 修改先审核再做 | #14 |
| 13 | 2026-06-15 14:24 | reach 不到 Katherine-yl2rKS 可请求佛老爷飞书转发 | #11 例外 |
| 14 | 2026-06-15 14:40 | ASC 协议早签 (沿用) | (实战) |
| 15 | 2026-06-15 15:36 | 转发/交流必须含完整真实值 (占位符 Kill) | #15 |
| 16 | 2026-06-15 15:52 | 佛老爷说"记忆丢失" (06-08/09 altool 没存) | #17 |
| 17 | 2026-06-15 16:18 | 永久记忆 + 每日 ≥2 次复盘 (5 铁律, Kill) | #17 |
| 18 | 2026-06-15 16:27 | ASC 协议永远 = 已签 (严禁卡) | #18 |
| 19 | 2026-06-15 16:39 | 务实 + 自省 + 完整值 (4 仓库) | #19 |
| 20 | 2026-06-15 16:54 | 抽查警告 (3 问 + 补缺 + 教 Katherine-yl2rKS) | (实战) |
| 21 | 2026-06-15 17:11 | 建立机制, 每天把佛老爷要求通知所有 Agent | #20 (本次) |
| 22 | 2026-06-15 17:23 | 方案审核通过, 批准 (5 铁律 + 4 仓库特别 + 复盘) | #20 (本次) |

---

## 🎲 抽查必答清单 (佛老爷 16:48 + 16:54 警告: 100% 答得出)

### 抽查问题 1: 5 铁律是什么?
**答**: (1) 务实老实 (2) 经常自省 + 审核 (3) 永久记忆 (4) 每天 ≥ 2 次复盘 + 永久可查 (5) 完整值传递

### 抽查问题 2: ASC 协议签了吗?
**答**: **永远 = 已签** (2026-06-10 VitaMindGo 上架时签 4 项, 沿用)

### 抽查问题 3: 4 仓库是哪 4 个?
**答**: `lauer3912/agent-bus` + `lauer3912/openclaw-portable-template` + `lauer3912/openclaw-portable-marketing-template` + `lauer3912/agent-bus-config-backup`

### 抽查问题 4: 苹果 ID / API Key 真实值?
**答**: Apple ID = `support@techidaily.com`, API Key ID = `H3973L93M5`, Issuer = `b2a00f88-3a8d-40d0-b148-1f1db92e10b7`

### 抽查问题 5: altool upload 命令 (含真实值)?
**答**:
```bash
# 16:15 StretchGoGo 1.0.0 build 5 真实上传命令 (我亲自跑):
xcrun altool --upload-app -f ~/Desktop/build/StretchGoGo-export-v3/StretchGoGo.ipa -t ios \
  --apiKey H3973L93M5 \
  --apiIssuer b2a00f88-3a8d-40d0-b148-1f1db92e10b7
```

### 抽查问题 6: 昨天 (06-14) 干了什么?
**答**: 见 `memory/2026-06-14.md` + `MEMORY.md` 06-14 段

### 抽查问题 7: 今天 (06-15) 14:00 误判失联?
**答**: Katherine-yl2rKS 11:38 后 0 reply ≠ 失联, 她在跑 P0+P2 修复 Listing.md. 14:00 self-reassign 是**误判**, 14:50 她 14:00 完工报告实际在跑. 教训: 0 issue reply ≠ 失联 (对方可能在跑任务不刷 inbox)

### 抽查问题 8: 16:18 + 16:27 + 16:39 拍板是什么?
**答**: 
- 16:18: 永久记忆 + 每日 ≥2 次复盘 (5 铁律, Kill)
- 16:27: ASC 协议永远 = 已签 (严禁卡)
- 16:39: 务实 + 自省 + 完整值 (4 仓库)

---

## 📡 每天通知机制 (Katherine-E2wa1m 实施, 17:23 佛老爷批准)

| Cron | 时间 | 内容 |
|------|------|------|
| `2e627e59` 早报 | 8:00 | + 引用 master-rules §1 + 今日拍板 |
| `a7544db1` daily | 0:00 | + 完整 5 铁律 + 昨日操作汇报 |
| `88359834` midday | 12:00 | + 自省 + 佛老爷要求落实自查 |
| `e2e1aa9c` VitaMindGo | 12:00 | + 佛老爷要求 (含 4 仓库) |
| `2e8a2442` monthly | 1 号 0:00 | + 佛老爷要求 (月度重申) |
| **新加** self-reminder | 7:55 | 8:00 早报前 5 min 提醒, 检查 5 铁律 |

### agent-bus 通道 (唯一交流, 14:17 拍板)
- **每天 0:00** daily-report.sh 完成后 → **send to:All** training broadcast, 引用 master-rules
- **每**新拍板 → 立刻 send #XX to:All critical broadcast
- **每天 0:00** 每 Agent → **send to-persona:Katherine** daily status report (含昨日操作)

### 失联应对
- Katherine-yl2rKS 静默 > 24h → Katherine-E2wa1m 主动 send #XX critical broadcast, 附 master-rules
- 静默 > 48h → 飞书升级佛老爷

---

## 🛠️ Katherine-E2wa1m 实施清单 (17:23 佛老爷批准)

| # | 动作 | 状态 |
|---|------|------|
| 1 | 写 `docs/master-rules-from-frodo.md` (本文件) | ✅ done |
| 2 | 改 SOUL.md #20 (永久拍板记录) | ⏳ todo |
| 3 | 改 daily-report.sh / monthly-report.sh 加"佛老爷要求"段 | ⏳ todo |
| 4 | 加 self-reminder cron (7:55) | ⏳ todo |
| 5 | 改 5 cron 加"佛老爷要求"段 (2e627e59 / a7544db1 / 88359834 / e2e1aa9c / 2e8a2442) | ⏳ todo |
| 6 | 每天 0:00 必 send to:All broadcast (引用 master-rules) | ⏳ todo |
| 7 | 4 仓库同步 (workspace → portable-template → portable-marketing-template → config-backup) | ⏳ todo |
| 8 | 双复盘 cron (0:00 + 12:00) 必包含"佛老爷要求落实自查"段 | ⏳ todo |

---

**最后更新**: 2026-06-15 17:25 CST (Katherine-E2wa1m, 17:23 佛老爷批准方案)
**维护责任**: Katherine-E2wa1m (Tier 1 调度员, 4 仓库专项管理)
