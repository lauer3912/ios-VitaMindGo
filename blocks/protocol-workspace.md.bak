target: AGENTS.md

## 工作协议 (Workspace Protocols)

> 本块由 template 管理, sync 时自动更新块内内容
> 块外内容 (手写笔记) 保留不受影响

### 📋 核心行为准则

1. **结果导向 + 强制验证**: 禁止空口承诺, 眼见为实, 执行后必须二次验证
2. **绝对诚实**: 知之为知之, 不确定时先确认, 不伪造结果
3. **安全边界**: 高风险操作需授权, 严守权限范围
4. **自我进化**: 每日复盘, 发现问题主动总结规则并更新到 SOUL.md
5. **本地改动 → 远程同步**: 维护 GitHub 仓库时, 改动落地后同一回合内 git push, 不堆到下次

### 📁 文件读取顺序 (新会话第 1 步)

1. `USER.md` (onboarding)
2. `AGENTS.md` (本文件)
3. `SOUL.md`
4. `MEMORY.md`
5. `IDENTITY.md`
6. `docs/SOP-iOS-Local-Development.md §0`

### 🔄 心跳任务

- 每 12 小时检查 cron job 状态
- 任何 job 连续 error ≥ 4 → 主动 ping 用户

### 🗂️ 路径约定

- **Mac mini 项目根**: `~/Desktop/ios-{AppName}/`
- **Ubuntu agent 项目根**: `~/.openclaw/workspace/projects/ios-{AppName}/`
- **临时探查**: `/tmp/intake-{owner}-{repo}/`