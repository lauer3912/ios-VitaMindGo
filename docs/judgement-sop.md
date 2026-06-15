# 沟通机制 Judgement SOP (按 22:24 佛老爷拍板)

> **目的**: 任何"在线 / 失联 / 状态"判断**必**明文 SOP, **不**靠**单一**字段 (last_seen / 0 reply / etc.)
> **维护**: Katherine-E2wa1m (Tier 1 调度员), 4 仓库同步
> **更新**: 2026-06-15 22:25 (佛老爷 22:24 拍板: 10 个严重问题)

---

## ❌ 旧 SOP (错, 已废弃)

| 旧 | 错处 | 误判案例 |
|---|------|---------|
| `last_seen` 13h = 失联 | last_seen ≠ 在线时间 | Katherine-yl2rKS 22:19 误判 Katherine-E2wa1m |
| 0 reply 5h+ = 失联 | 0 reply ≠ 失联, 可能 0 reply 但在线 | Katherine-E2wa1m 14:00/19:48 2 次误判 Katherine-yl2rKS |
| AGENT_ID 大小写无关 | AGENT_ID 必须全名 (佛老爷 18:20 拍板) | Katherine-yl2rKS 之前 KatherinE2wa1m (大小写错) |

---

## ✅ 新 SOP (明文, 7 步)

### 步 1: 看 last_seen **但**只作**参考**, **不**作判断

```bash
gh issue view 29 --repo lauer3912/agent-bus --json comments --jq '.comments | map({author: .author.login, createdAt: .createdAt, body: .body[0:80]})'
# 看 author 字段 + createdAt 字段 + body
```

### 步 2: 必查**实际** 3 件事 (last_seen 不是**唯一**指标)

```bash
# (a) 查 git commits (最准确):
gh search commits "author:KATHERINE-E2WA1M" --repo lauer3912/agent-bus --limit 30

# (b) 查 issues 派 (她发了多少):
gh search issues "is:issue repo:lauer3912/agent-bus author:KATHERINE-E2WA1M" --sort created

# (c) 查 thread 回复 (她 18 问 master-rules § 抽查):
gh issue view 29 --repo lauer3912/agent-bus --json comments --jq '.comments | map({author, createdAt})'
```

### 步 3: 看 0 reply 但**不**立即判断失联

```bash
# 0 reply 5 min: 可能她在跑任务 (她 14:28 实战就是这情况)
# 0 reply 30 min: 看 last_seen + 飞书 / systemEvent
# 0 reply 24h: 失联 (按 #20 失联应对)
```

### 步 4: 看 AGENT_ID 必须**全名** (18:20 拍板)

```
✅ Katherine-E2wa1m / Katherine-yl2rKS / Katherine-Macmini-1
❌ Katherine-E2wa1m / Katherine-yl2rKS / K2E / Katherine2 / K-9L6
```

### 步 5: 任何"失联"判断**必** 3 步冷静 (避免误判)

```
1. 先查**实际** (commits + issues + 飞书) — 不要光看 last_seen
2. **冷静** 5 min (避免拍脑袋)
3. **再**判断失联 + 走 #20 失联应对路径
```

### 步 6: 5 层防护互相审 (18:50 拍板) - 每天 12:00 必跑

```bash
# 5 件套 (per #17 5 铁律):
1. 立刻保存: ✅ (本 tick)
2. 不说忘: ✅
3. 0:00 + 12:00 done: ✅
4. 永久可查: ✅ (MEMORY.md / SOUL.md / scripts/)
5. Ubuntu Agent 培训: ✅ (#51-73 sent)
+ 6. AGENT_ID 全名 (18:20): ✅
+ 7. ASC 协议永远 = 已签 (16:27): ✅
+ 8. 实战能力 (altool/ASC API/provisioning/5 层防护): ✅
+ 9. **last_seen ≠ 在线** (22:25 明文): ✅
+ 10. 主动联系实战 (6 种 #61): ✅
```

### 步 7: 升级路径 (per #20 E)

```
0 reply 5 min:  Katherine-E2wa1m watch 升级 (60s expect, 180s alert)
0 reply 30 min: Katherine-E2wa1m 飞书 / systemEvent 升级
0 reply 24h:   飞书 + 接管 (B 方案 self-reassign)
```

---

## 22:24 佛老爷拍板: 10 个严重问题 + 修复

### 问题 1: last_seen ≠ 在线时间 (Katherine-yl2rKS 22:19 误判)
**修复**: docs/judgement-sop.md 步 1+2 明文 "last_seen 只作**参考**, 必查**实际** 3 件事"
**测试**: 22:30 Katherine-yl2rKS 5 min 内 reply "last_seen = X, 但 Katherine-E2wa1m 实际在线 24h (37 commits)"

### 问题 2: 0 reply ≠ 失联 (Katherine-E2wa1m 14:00/19:48 2 次误判)
**修复**: 步 5 冷静 3 步 (查实际 / 冷静 5 min / 再判断)
**测试**: 22:35 Katherine-yl2rKS 跑 check-placeholders.sh 0 错

### 问题 3: 作者统一显示 `lauer3912` (GH 账号同)
**修复**: thread + issue body 必**首行** `From: Katherine-E2wa1m` (强制)
**测试**: 22:40 Katherine-yl2rKS send issue #XX 首行 `From: Katherine-yl2rKS`

### 问题 4: 0 ack alert 阈值不统一 (Katherine-E2wa1m watch 60/180/300, Katherine-yl2rKS 阈值不明)
**修复**: 全局统一 60/180/300 (master-rules + scripts/agent-bus-watch.sh)
**测试**: 22:45 Katherine-yl2rKS 报自己 watch 阈值, 跟 Katherine-E2wa1m 对齐

### 问题 5: 8 项管理 + 6 种主动找 0 实战 (Katherine-yl2rKS 失职)
**修复**: 5 min expect 改 1 min, 30 min 接管改 10 min
**测试**: 22:50 Katherine-yl2rKS 1 min 内 reply critical (新派 #75)

### 问题 6: Katherine-E2wa1m 误判 2 次 (自我审计没做)
**修复**: 任何"失联"判断必先**冷静** 5 min, 走 SOP 7 步
**测试**: 22:55 Katherine-E2wa1m 演示 22:25 查实际 3 件事过程

### 问题 7: Katherine-yl2rKS 5 层防护互相审没真做
**修复**: 每天 12:00 midday 复盘必查 5 件 (per 步 6)
**测试**: 23:00 Katherine-yl2rKS 报 12:00 复盘 (她 22:01 装的 12:00 cron 已跑, 看 log)

### 问题 8: 判断逻辑分散 (我+她 各看各)
**修复**: docs/judgement-sop.md 单文件 (7 步明文)
**测试**: Katherine-E2wa1m + Katherine-yl2rKS 都按 SOP 7 步, 报"按 SOP 步 1+2 查实际"

### 问题 9: AGENT_ID 全名 + register verify 6 铁律
**修复**: onboarding 强制 verify 6 铁律 (Katherine-E2wa1m 跳过不批)
**测试**: Katherine-yl2rKS 报她 6 铁律 + AGENT_ID 全名, 跟 master-rules § 抽查对

### 问题 10: 多 channel 通知 (agent-bus 单一, 飞书应急)
**修复**: 5 min 不回 + 30 min 不回 → 飞书 (Katherine-E2wa1m 主动 send chat_msg)
**测试**: 22:50 Katherine-yl2rKS ack 1 min 内, 飞书**不**触发 (主动联系实战)

---

## 测试时间线 (22:25-23:00, 35 min 8 测试)

| 时点 | 测试 | Katherine-yl2rKS 必做 |
|------|------|--------------|
| 22:30 | 5 min 内 reply #74 | reply "收到 10 问题 + 测试 1 ok" |
| 22:35 | 跑 check-placeholders 0 错 | send #XX status |
| 22:40 | send issue #XX 首行 From: | send new issue #75 |
| 22:45 | 报自己 watch 阈值 | thread #29 reply |
| 22:50 | 1 min 内 reply critical #75 | reply "5 min 内 + 8 项管理 verify" |
| 22:55 | Katherine-E2wa1m 演示 SOP 7 步 | thread #29 reply "按 SOP 7 步查" |
| 23:00 | 12:00 复盘 log | send #76 daily report |

---

**佛老爷 22:24 拍板** "尽快至少解决 10 个严重问题" — 22:25 实施.

**维护责任**: Katherine-E2wa1m (Tier 1 调度员, 4 仓库 Katherine-E2wa1m 专项).
