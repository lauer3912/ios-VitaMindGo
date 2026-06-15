# OpenClaw 工作区 (佛罗多老爷)

> 🎯 **本工作区是佛罗多老爷所有 iOS App 项目的根**。所有 agent 在每次会话启动时自动加载这里的 `AGENTS.md` / `SOUL.md` / `USER.md` / `MEMORY.md` / `IDENTITY.md`。

---

## 📁 工作区结构

```
~/.openclaw/workspace/
├── AGENTS.md                      # Agent 行为总纲
├── SOUL.md                        # 灵魂 (凯瑟琳·约翰逊)
├── IDENTITY.md                    # 身份定义
├── USER.md                        # 用户画像 (佛罗多老爷)
├── MEMORY.md                      # 长期记忆
├── TOOLS.md                       # 本地工具备注
├── HEARTBEAT.md                   # 心跳任务清单
│
├── docs/                          # 所有 SOP 文档
│   ├── SOP-iOS-Local-Development.md       # Mac 本地版 SOP v14 (上游)
│   ├── SOP-iOS-Ubuntu-Development.md     # Ubuntu + 远程版 SOP v1.0 (新!)
│   ├── iPad-Screenshot-Recipe.md
│   ├── agent-collaboration-best-practices.md
│   ├── 2026-2028-iOS-App-Up.md
│   └── AGENTS-injection.md                # 新 Ubuntu agent 启动注入模板
│
├── scripts/                       # 所有可执行脚本
│   ├── sop-822-check.sh                   # 21 项自检 (跨平台)
│   ├── naming-check.sh
│   ├── setup-ubuntu-ssh-client.sh         # Ubuntu 端 SSH 配置
│   ├── setup-macos-ssh-host.sh            # Mac mini 接收端配置
│   ├── ssh-macmini-build.sh               # 远程 archive
│   ├── ssh-macmini-upload.sh              # 远程 upload
│   ├── ssh-macmini-screenshot.sh          # 远程 screenshot
│   ├── onboard-new-ubuntu.sh              # 新 Ubuntu agent 一键入职
│   └── distribute-sop.sh                  # 打包 SOP 给新机器
│
├── examples/                      # 模板文件 (给项目用)
│   └── .github/workflows/ios-verify.yml   # CI workflow 模板
│
├── dist/                          # openclaw-portable-template 副本 (已推上 GitHub, v1.0.1)
│   └── openclaw-portable-template/        # private repo 内容 (已推上 GitHub)
│       ├── README.md                      # private repo 入口
│       ├── docs/                          # 拷贝自 workspace/docs/
│       ├── scripts/                       # 拷贝自 workspace/scripts/
│       └── examples/                      # 拷贝自 workspace/examples/
│
└── memory/                        # 每日工作记录 (按日期)
    └── 2026-06-05.md
```

---

## 🚀 新 Ubuntu agent 入职 (一键)

如果你是新加入的 Ubuntu 服务器上的 OpenClaw agent, 只需:

```bash
# 1. 设 GITHUB_TOKEN (老爷已告诉你)
export GITHUB_TOKEN="GH_TOKEN\=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"
echo 'export GITHUB_TOKEN="GH_TOKEN\=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"' >> ~/.bashrc

# 2. Clone 模板到 agent workspace 下子目录 (不污染 OpenClaw 自身 config)
git clone https://lauer3912:${GITHUB_TOKEN}@github.com/lauer3912/openclaw-portable-template.git \
  ~/.openclaw/workspace/openclaw-portables

# 3. 跑入职脚本 (server_tag = beta / gamma / delta / ...)
cd ~/.openclaw/workspace/openclaw-portables
sudo bash scripts/onboard-new-ubuntu.sh <server_tag>

# 脚本会: 装 gh / 生成 SSH 密钥对 / 配 ~/.ssh/config / 注入 AGENTS.md
# 跑完 Step [7/8] 会打印公钥, 把那一行发给老爷

# 4. 等老爷把公钥加到 Mac mini 后验证
ssh macmini 'xcodebuild -version | head -1'
```

---

## 📋 当前项目状态

### VitaMindGo (主项目)
- **仓库**: https://github.com/lauer3912/ios-VitaMindGo (**public**)
- **类型**: AI 健康助理 + 习惯追踪 App
- **版本**: v3.0.0 (已提交 App Store 审核, 2026-06-04)
- **状态**: ⏳ 等待审核结果

### OpenClaw 便携模板 (已上线)
- **仓库**: https://github.com/lauer3912/openclaw-portable-template (**private**)
- **状态**: ✅ 已推送 (含 v1.0 + 错别字修复)
- **本地位置**: `dist/openclaw-portable-template/`

---

## 🔑 关键约束 (Agent 必读)

1. **最小知识原则**: Agent 越少了解穿透细节越安全
2. **单 SSH 入口**: `macmini` → `47.77.237.73:2222` → `user291981`
3. **GitHub Actions 只做 build + test**: 不 archive/不签名/不上传/不连 Mac mini (SOP §1.2)
4. **Mac mini 同时支持两种登录**: SSH 公钥 (agent 自动化) + 密码 (人工访问) 互不冲突
5. **iOS App 仓库全部 public**: public 仓库 = 无限免费 macOS runner
6. **每日 8 点汇报**: 进展 + 计划 + 问题

---

## 📞 联系方式

- **老爷 (佛罗多)**: QQ 直聊
- **OpenClaw docs**: https://docs.openclaw.ai
- **GitHub**: https://github.com/lauer3912

---

_最后更新: 2026-06-06 (v1.0.2: 错别字修复 + 6 项修正 + 二审 C/M 修正)_
