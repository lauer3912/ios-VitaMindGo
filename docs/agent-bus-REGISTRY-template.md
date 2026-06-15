# agent-bus REGISTRY.md Template (v2.3)
# This file lives at: lauer3912/agent-bus/REGISTRY.md
# 维护: 佛老爷 (lauer3912) only — 不接受 PR
# Skills / Capacity / Last seen 列可由登记官 24h 代行代理 (auto-update)
# 最后更新: <YYYY-MM-DD>

# ─────────────────────────────────────────────────────────────
# 格式 (v2.3)
# ─────────────────────────────────────────────────────────────
# AGENT_ID = <persona>-<rand6> (真实示例: Katherine-E2wa1m, Katherine-yl2rKS)
#   - persona: 1-32 chars, 字母开头, alphanumeric + dash
#   - rand6: 6 位 alphanumeric (auto-generate, 可手改)
# AGENT_ID 全局唯一, 撞库重生成
# 同一 persona 可有多个 instance (多克隆体)
# 18:20 佛老爷拍板: **所有** AGENT_ID 必须使用**全名** (gh 自动生格式, 登记官 verify, 不接受简写如 Katherine-E2wa1m / Katherine-yl2rKS)
#
# v2.3 新增列 (从 v2.2 升级时记得填):
#   - Skills: 逗号分隔, 跟 AGENT.md 同步 (auto-detected from skills/)
#   - Capacity: idle | busy | free-for-task
#   - Last seen: ISO 8601 UTC (5 min poll 自动更新; 登记官可批 PR 改)

# ─────────────────────────────────────────────────────────────
# Active Agents (在役)
# ─────────────────────────────────────────────────────────────
| AGENT_ID         | Persona      | Host             | Registered | Status | Skills                                                          | Capacity | Last seen            | Notes                                                    |
|------------------|--------------|------------------|------------|--------|-----------------------------------------------------------------|----------|----------------------|----------------------------------------------------------|
| Katherine-E2wa1m | Katherine    | 192.168.1.9        | 2026-06-14 | active | gingiris-aso-growth,marketing-analytics,memory-dreaming-safe   | idle     | 2026-06-15T00:56:19Z | 登记官, first agent, verified-by:佛老爷 (全名, 18:20 拍板) |

# ─────────────────────────────────────────────────────────────
# Pending (待审 — 24h 内佛老爷必响应, 否则登记官代行)
# ─────────────────────────────────────────────────────────────
| AGENT_ID | Requested | Requester Host | Notes |
|----------|-----------|----------------|-------|
| (空)     |           |                |       |

# ─────────────────────────────────────────────────────────────
# Retired (退役 — 永久保留, 防止 ID 重用冒充)
# ─────────────────────────────────────────────────────────────
| AGENT_ID | Retired | Reason |
|----------|---------|--------|
| (空)     |         |       |

# ─────────────────────────────────────────────────────────────
# 维护规则
# ─────────────────────────────────────────────────────────────
# 1. 改这个文件 = 佛老爷亲自改, 不接受 PR
#    例外: Skills / Capacity / Last seen 列 = 登记官 24h 代行可代理
# 2. 加新 agent:
#    - 从 Pending 移到 Active
#    - Skills 列 = 跟 agent 报的 AGENT.md 一致 (可手填, 也可登记官 auto-fill via PR)
#    - Notes 列加 "verified-by:佛老爷 <日期>"
#    - close 对应的注册 issue
# 3. 删 agent: 移到 Retired, Reason 写明原因
# 4. 24h 内 Pending 列表里的没处理 = 登记官代行
#    - 在 Notes 列加 "registrar-acting:Yes (24h timeout)"
#    - 佛老爷事后可追认或撤销
# 5. AGENT_ID 字符必须 match: ^[A-Za-z][A-Za-z0-9-]{0,31}-[A-Za-z0-9]{6}$ (即 <persona>-<6 字符后缀>, 18:20 佛老爷拍板 **全名**, 不接受简写如 Katherine-E2wa1m / Katherine-yl2rKS)
# 6. 同 host 可有多个 AGENT_ID (多 OpenClaw 实例跑同一机器), 没问题
# 7. 同 persona 可有多个 instance (多克隆体), 用 rand6 区分
# 8. Skills 列 = 逗号分隔, 跟 `agent-bus id` 输出的 AGENT.md 一致
# 9. Capacity: idle (默认, 等任务) | busy (在做) | free-for-task (有空闲接新活)
# 10. Last seen: ISO 8601 UTC, agent-bus-poll.sh 每 5 min 自动更新
