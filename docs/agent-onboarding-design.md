# Agent 入职 + SOP同步设计方案

> 目标：解决两个问题
> 1. **入职 0→1**：新 Ubuntu 服务器的 OpenClaw Agent 如何快速就位
> 2. **更新 1→持续**：SOP/脚本更新后，如何让所有 Agent 自动用上最新版本

---

## 一、现状盘点

**已有的东西：**
- `openclaw-portable-template` 私有仓库（v1.0.4），包含 SOP + 4 个 SSH 脚本 + GitHub Actions yml
- `setup-github-cred.sh` 里已内置 `DEFAULT_GITHUB_TOKEN`（老爷 2026-06-08 拍板共用）
- 8:00 早报 cron job（每天）
- `sop-822-check.sh` 21 项环境自检脚本

**缺的东西：**
- 没有统一的入职入口（现在要手动 git clone + 跑多个脚本）
- 没有版本号机制（不知道哪个 Agent 用的是什么版本 SOP）
- 没有自动同步机制（template 更新了，老 Agent 不知道）
- 没有故障恢复（网络断了 /重复跑会出事）

---

## 二、问题 1：入职 0→1

### 目标

新 Ubuntu 机器拿到手，跑 **一条命令**，56 秒内完成所有配置，开始工作。

### 方案：install.sh

写一个入口脚本 `install.sh`，放到 `openclaw-portable-template` 根目录。

**一条命令：**
```bash
curl -fsSL -H "Authorization: token $DEFAULT_GITHUB_TOKEN" \
  https://raw.githubusercontent.com/lauer3912/openclaw-portable-template/main/install.sh | bash
```

> 私有仓库的 raw URL 需要认证，`-H "Authorization: token ..."` 头即可拉取。
> token 在 install.sh 里内置，命令本身不暴露敏感信息。

**这条命令做的事（8 个步骤，自动依次执行）：**

```
Step 1: 环境检测（5秒）
  - 检查 Node.js >= 24，没装就装
  - 检查 git，没装就装
  - 检查磁盘空间（需要5GB）
  - 检查网络（github.com 能通吗）
  - 任何一步失败 → 停在这里，告诉你是哪一步挂了

Step 2: 安装依赖（30秒）
  - apt update + 装 jq / rsync / curl
  - 装 Node.js 24（如果没装）
  - 装 OpenClaw CLI（如果没装）
  - 失败 retry 3 次，每次等5 秒

Step 3: 拉模板代码（10秒）
  - git clone openclaw-portable-template 到 ~/.openclaw/workspace-template
  - 如果 github.com 连不上，试备用镜像（jsdelivr / ghproxy）
  - 验证拉下来的是完整的

Step 4: 初始化工作区（5秒）
  - 把 template里的 AGENTS.md / SOUL.md / IDENTITY.md 拷到 workspace
  - 把 SOP文档和脚本拷到 workspace
  - 第一次跑：生成空白 MEMORY.md + USER.md（含引导提示）
  - 重复跑：跳过这步，不覆盖已有的 MEMORY.md / USER.md

Step 5: 配置凭证（3秒）
  - 跑 setup-github-cred.sh（GitHub Token，已内置 fallback）
  - 跑 setup-ubuntu-ssh-client.sh（SSH 密钥配置）

Step 6: 验证环境（5秒）
  - 跑 sop-822-check.sh，21 项全过才算成功
  - 任何一项失败 → 停在这里

Step 7: 注册心跳任务（1秒）
  - 自动注册每天 06:00 的 template同步任务
  - 自动注册 8:00 早报任务（如果没注册过）

Step 8: 完成
  - 告诉你：✅ 入职完成！
  - 告诉你：下一步是填 USER.md 的 Onboarding 7块
  - 告诉你：已注册每天 06:00 自动同步
```

###断点续传（保证稳定可靠）

每个 Step 完成后，在 `~/.openclaw/workspace/.install-state/` 目录下写一个标记文件：
- `.step-1.done`
- `.step-2.done`
- ...依次类推

如果中途失败（比如网络断了），下次再跑 `install.sh` 时：
- 已完成的 Step 直接跳过
- 从失败的 Step 继续
- 不会重复浪费时间和流量

### 重复跑会怎样？

| 场景 | 行为 |
|------|------|
| 第一次跑 | 完整执行 8 个 Step |
| 跑到 Step 3 网络断了 | 标记 `.step-3.failed`，下次从这里继续 |
| 重启后重跑 | 跳过已完成的 Step，从断点继续 |
| 老 Agent 重跑 | 升级现有文件 + 验证，不破坏 MEMORY.md / USER.md |
| 重复跑已完成的 | 跳过，提示 "已是最新版本" |

---

## 三、问题 2：更新 1→持续

### 目标

老爷改了 SOP 或脚本 → git push 到 template → 所有 Agent 在 24小时内自动用上最新版本。

### 方案：两层触发机制

```
老爷改 SOP
    ↓
跑 distribute-sop.sh 打包并推送
    ↓
git push 到 openclaw-portable-template
    ↓
（Layer 2）cron 每天 06:00 自动跑 sync 脚本
（Layer 3）Agent 每次 heartbeat 启动时检查
    ↓
报告给老爷：谁更新了、变了什么
```

**两层触发：**

| 层级 | 触发方式 | 同步速度 | 用途 |
|------|----------|----------|------|
| **Layer 2（定时拉）** | cron 每天 06:00 自动跑 | 24 小时内 | 普通迭代（日常优化） |
| **Layer 3（启动拉）** | Agent 每次 heartbeat 启动时检查 | 下次启动 | 老 Agent 重启后自动跟上 |

> Webhook 推送（Layer 1）已移除：Ubuntu 服务器无法配置 OpenClaw Gateway webhook。
> 两层足够日常使用，紧急修复走 `openclaw cron run <job-id>` 手动触发即可。

两层都走 **同一个 sync 脚本**，避免重复实现和维护。

### 版本号机制：MANIFEST.yaml

在 template根目录放一个 `MANIFEST.yaml`，每次 push 新版本时更新：

```yaml
version: 1.0.5
last_updated: 2026-06-10T08:51:00+08:00
components:
  identity:
    - AGENTS.md
    - SOUL.md
    - IDENTITY.md
  docs:
    - docs/SOP-iOS-Local-Development.md
  scripts:
    - scripts/setup-ubuntu-ssh-client.sh
    - scripts/ssh-macmini-build.sh
    - scripts/setup-github-cred.sh
    - scripts/sync-from-template.sh
    - scripts/sop-822-check.sh
user_owned:
  - MEMORY.md
  - USER.md
  - memory/
```

**版本号怎么用：**
- Agent 本地存一份 `.template-version` 文件（存当前版本号）
- 每次 sync 时比对：本地版本 vs 远端 MANIFEST.yaml
- 一致 → 静默退出
- 不一致 → 拉新版本

### 块同步机制（保护 Agent 个性 + 支持升级）

**所有 `*.md` 文件都用块同步，不是整体覆盖。**

块标记格式：
```markdown
<!-- openclaw-block: <stable-id> -->
...模板内容...
<!-- /openclaw-block -->
```

**块 ID 跨版本稳定**（不带版本号），例如：
- `protocol-workspace`、`red-lines`（AGENTS.md）
- `soul-essence`、`vibe-rules`（SOUL.md）
- `identity-basics`、`creature-vibe`（IDENTITY.md）
- `onboarding-template`、`open-questions`（USER.md）

**3 种块行为：**

| 情况 | 行为 |
|------|------|
| 块 ID 存在 | 替换块内容（块外内容 100% 保留） |
| 块 ID 不存在 | 追加到文件末尾 |
| template 标记 REMOVE | 从文件中删除该块 |

**同步策略分类：**

| 文件类型 | 同步策略 |
|----------|----------|
| `*.md` | 块同步（块外内容保留，块内可更新） |
| `scripts/*.sh` | 整体替换 + 自动备份 |
| `MANIFEST.yaml` | 整体替换 |
| `memory/*.md` | 永不碰 |

**关键原则：**
- ✅ 所有 markdown 文件都支持块同步
- ✅ 块外内容（手写笔记 / 自定义）100% 保留
- ✅ 块内内容随 template 更新而替换
- ✅ 新块（template 新加的）自动追加到末尾
- ❌ scripts 整体替换前会自动备份（保留 7 天）

### 稳定性保障（9 项）

| # | 威胁 | 修复 |
|---|------|------|
| 1 | 块同步中途失败 → 文件损坏 | 原子写（PID tmp + 验证大小 + mv） |
| 2 | 并发 sync 互踩 | flock 文件锁 |
| 3 | 备份损坏 | sha256 校验和 + 回滚前验证 |
| 4 | 块标记错位 | 同步前验证 open/close 计数 |
| 5 | 网络瞬断 | retry 3 次 + 指数退避（5s/10s/20s） |
| 6 | 状态文件与实际不符 | Step 开始前验证前置 Step 证据 |
| 7 | token 泄露 | 错误信息不带变量 + curl -s |
| 8 | 出问题无法排查 | `.sync-log` 记录每次同步（时间、版本、变更摘要） |
| 9 | sync 失败时文件被半改 | 失败时留 `.sync-failed` 标记，不动文件，保留可排查现场 |

### sync 脚本做的事

```bash
scripts/sync-from-template.sh
  1. 拉远端 MANIFEST.yaml（单文件，很快）
  2. 比对版本号（本地 vs 远端）
  3. 版本一致 → 退出（静默，不打扰）
  4. 版本不一致 → 
       a. 备份当前版本（tar.gz，保留 7 天）
       b. 同步脚本整体替换
       c. 同步文档（块替换 + 块追加）
       d. 更新本地版本号
       e. 写同步日志（谁、什么时间、从哪个版本到哪个版本）
       f. 报告给老爷：变了哪些块
```

### 安全保障

| 措施 | 说明 |
|------|------|
| **HTTPS only** | 只从 github.com 拉，禁 http |
| **备份机制** | 每次 sync 前备份，保留 7 天，出了问题可回滚 |
| **Token 检测** | setup-github-cred.sh 会检测 token 是否快过期（90 天到期前 7 天警告） |
| **静默失败** | 网络不通时静默退出，不报错不打扰（下次心跳再试） |

---

## 四、入职 + 更新 联动流程

```
┌─────────────────────────────────────────────────────────────┐
│ 老爷改 SOP / 脚本 │
└─────────────────────────────────────────────────────────────┘
                           ↓
              distribute-sop.sh 打包
                           ↓
              git push → openclaw-portable-template
                           ↓
┌─────────────────────────────────────────────────────────────┐
│ 两层触发 │
│  Layer2: cron 06:00 → sync-from-template.sh (24小时内)      │
│  Layer3: heartbeat启动 → check-template-version.sh          │
└─────────────────────────────────────────────────────────────┘
                           ↓
              同一 sync 脚本执行
                           ↓
              白名单同步 +备份 + 写日志
                           ↓
              通过 QQ 报告给老爷
```

---

## 五、实现步骤（30 分钟可完成）

| 顺序 | 做什么 | 时间 |
|------|--------|------|
| 1 | 写 `template/MANIFEST.yaml`（版本号清单） | 5 分钟 |
| 2 | 写 `template/install.sh`（入职入口脚本） | 15 分钟 |
| 3 | 写 `template/scripts/sync-from-template.sh`（同步脚本） | 10 分钟 |
| 4 | 升级 `distribute-sop.sh`：打包时自动更新 MANIFEST.yaml 版本号 | 5 分钟 |
| 5 | 把 AGENTS.md / SOUL.md / IDENTITY.md 复制进 template | 5 分钟 |
| 6 | push v1.0.5 到 openclaw-portable-template | 2 分钟 |
| 7 | 在自己 workspace 跑 sync 脚本验证 | 5 分钟 |
| 8 | 注册 cron `sync-template-6am` | 2 分钟 |

---

## 六、已确认事项

1. ✅ **install.sh 里 token 内置**：完全 OK，老爷已拍板
2. ❌ **webhook 推送**：不做，Ubuntu 服务器无法配置
3. ✅ **MANIFEST.yaml 签名**：要做（基础版本 v1.0.5）

---

## 七、FAQ

**Q: 如果新 Ubuntu 机器没网？**
A: install.sh 有镜像 fallback（jsdelivr / ghproxy），还连不上就提示手动拉 tarball。

**Q: 如果老爷改了 USER.md 自定义配置，sync 会覆盖吗？**
A:不会。USER.md 在 user_owned 白名单里，永远不覆盖。

**Q: 如果 sync 后出问题了怎么回滚？**
A: 每次 sync 前备份，保留 7 天。运行 `restore-from-backup.sh` 即可回滚到上一个版本。

**Q: 如果多个新机器同时入职，会不会冲突？**
A: 不会。每个机器独立 workspace，互不影响。