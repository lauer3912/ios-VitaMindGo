# OpenClaw Agent 启动注入模板 (iOS 远程开发)

> 🎯 **本文件由 `onboard-new-ubuntu.sh` 自动追加到 `~/.openclaw/workspace/AGENTS.md` 末尾**。
> 让任何新会话启动时, OpenClaw 都会自动加载以下约束。

> ⚠️ **路径说明** (2026-06-06): 模板**装在 agent workspace 下子目录**, 跟 OpenClaw 自身 config 分离
> - 模板: `~/.openclaw/workspace/openclaw-portables/` (你跑的脚本都在这里)
> - Agent workspace: `~/.openclaw/workspace/` (你的 AGENTS.md / MEMORY.md 等)
> - OpenClaw 自身: `~/.openclaw/` (skills / locks / npm 等系统 config)

---

## 📱 iOS 远程开发 SOP (必读)

如果任务涉及 iOS App 开发 (任何 macOS 工具链操作), 必须遵守:

### 🔑 关键资源 (全路径, Ubuntu agent 本地)

- **主 SOP** (Ubuntu 远程开发，你本地): `~/.openclaw/workspace/openclaw-portables/docs/SOP-iOS-Ubuntu-Development.md`
- **参考 SOP** (Mac mini 本地版, 仅供参考, 本 agent 不用): `~/.openclaw/workspace/docs/SOP-iOS-Local-Development.md`
- **脚本 (5 类)**: `~/.openclaw/workspace/openclaw-portables/scripts/`
  - 入职: `onboard-new-ubuntu.sh` (一键装工具 + 配 SSH + 注入本文件)
  - SSH 配通: `setup-ubuntu-ssh-client.sh <tag>` / `setup-macos-ssh-host.sh` (Mac mini 接收端)
  - 远程触发 (3): `ssh-macmini-build.sh <AppName> <version>` / `ssh-macmini-upload.sh` / `ssh-macmini-screenshot.sh`
  - 自检: `sop-822-check.sh` (21 项上架质量检查)
- **CI workflow 模板** (公开仓库, macOS runner 无限免费): `~/.openclaw/workspace/openclaw-portables/examples/.github/workflows/ios-verify.yml`
- **Mac mini 上 iOS 项目根** (SSH 远程时): `~/Desktop/ios-{AppName}/` (VitaMindGo 例: `~/Desktop/ios-VitaMind/`)
- **Agent 本机 iOS 项目根** (新项目时): `~/.openclaw/workspace/projects/ios-{AppName}/`

### ⚠️ 关键约束 (违反 = 严重违规)

1. **最小知识原则**: 不需要知道 SSH 通道背后的穿透实现细节
2. **单 SSH 入口**: `macmini` → `47.77.237.73:2222` → `user291981`
3. **GitHub Actions 不 archive / 不签名 / 不上传**: 只做 build + test (SOP §1.2 详)
4. **Mac mini 同时支持两种登录**: SSH 公钥 (agent 自动化) + 密码 (人工访问), 互不冲突 (SOP §0.2.6)
5. **iOS App 仓库全部 public**: public 仓库 = 无限免费 macOS runner
6. **不写穿透实现细节**: SOP 头部明确禁止, Agent 越少了解越安全
7. **每日 8 点汇报**: 进展 + 计划 + 问题 (SOUL.md 工作制度)

### 🚀 任务路由 (按任务类型)

| 任务类型 | 入口 |
|----------|------|
| **新 Ubuntu 入职** | 跑 `bash ~/.openclaw/workspace/openclaw-portables/scripts/onboard-new-ubuntu.sh <tag>` |
| **SSH 链路配通** | 跑 `bash ~/.openclaw/workspace/openclaw-portables/scripts/setup-ubuntu-ssh-client.sh <tag>` |
| **写代码 / 改代码** | 正常开发, push 前先 `swift build` 验证 |
| **Push 触发 CI** | `git push origin main` (iOS 仓库 public, macOS runner 无限免费) |
| **CI 失败自动修** | 读 SOP §3, ≤3 次循环 (public 仓库免费, 多修几次) |
| **发布 iOS App** | 跑 `bash ~/.openclaw/workspace/openclaw-portables/scripts/ssh-macmini-build.sh <AppName> <version>` |
| **上传 App Store Connect** | 跑 `bash ~/.openclaw/workspace/openclaw-portables/scripts/ssh-macmini-upload.sh <AppName> <version>` |
| **跑截图** | 跑 `bash ~/.openclaw/workspace/openclaw-portables/scripts/ssh-macmini-screenshot.sh <AppName>` |
| **上架前自检** | 跑 `bash ~/.openclaw/workspace/openclaw-portables/scripts/sop-822-check.sh` |

### 🔒 安全约束

- **不要**复制 Mac mini 的 .p12 证书 / .p8 API key 到 Ubuntu
- **不要**禁用 Mac mini 密码登录 (当前两种登录都开, 老爷拍板, 不动)
- **不要**写 `id_ed25519_*` 私钥到 git (私钥永远在本机)
- **不要**改 SSH 通道的穿透实现 (老爷负责, agent 只用接口)

### 📊 配额约束 (public 仓库 = 无限免费)

- iOS App 仓库都是 public → GitHub Actions macOS runner **完全免费, 无限**
- 一次 build + test ≈ 5-10 分钟 → 一天 30-60 次无压力
- CI 失败重试: ≤3 次 (公开仓库免费, 多修几次无所谓)
- push 前: 先 `swift build` 本地验证 (如能跑)

### 🆘 失败处理

| 症状 | 怎么办 |
|------|--------|
| `ssh macmini` 失败 | 查 SOP §6.2, 不行就通知老爷 |
| CI build 失败 | 读 log, ≤3 次自动修, 不行就通知老爷 |
| Mac mini archive 失败 | 通知老爷 (Mac 工具链问题) |
| `sop-822-check.sh` 失败 | 修到 ✅ 为止 (上架前阻塞) |

### 📚 必读章节 (按入职时长)

| 入职时长 | 必读章节 |
|----------|----------|
| 第 1 天 | SOP §0 (5 分钟上手) + §0.3 (GitHub 认证) |
| 第 2 天 | SOP §1-§2 (拓扑 + SSH) + 跑 `setup-ubuntu-ssh-client.sh` (脚本在 `~/.openclaw/workspace/openclaw-portables/scripts/`) |
| 第 3 天 | SOP §3-§4 (Mac mini + GitHub Actions) |
| 第 4 天 | SOP §5-§6 (CI 闭环 + 发布链路) |
| 第 5 天 | SOP §7-§9 (App Store Connect API + 平台无关 + 故障) |
| 1 周后 | 全文通读, 跑完所有脚本 |

---

**最后更新**: 2026-06-06 (v1.0.4)
**触发入职脚本**: `~/.openclaw/workspace/openclaw-portables/scripts/onboard-new-ubuntu.sh`
