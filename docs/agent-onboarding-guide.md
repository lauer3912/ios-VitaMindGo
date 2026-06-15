# OpenClaw Agent 入职 + 更新 操作手册

> 一张图 + 几条命令。看完能上手。
> 完整设计：`docs/agent-onboarding-design.md`
> **v1.0.13+ 自举机制**：sync 脚本会自动检测并更新自己，**永远只需 2 步**。

---

## 1️⃣ 一条命令入职（新 Ubuntu 服务器）

**方式 A：环境变量（推荐）**
```bash
export GH_TOKEN="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"
curl -fsSL -H "Authorization: token $GH_TOKEN" \
  https://raw.githubusercontent.com/lauer3912/openclaw-portable-template/main/install.sh | bash
```

**方式 B：默认 fallback（开箱即用）**
脚本内置默认 token，无需传环境变量：
```bash
curl -fsSL -H "Authorization: token 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" \
  https://raw.githubusercontent.com/lauer3912/openclaw-portable-template/main/install.sh | bash
```

> 优先使用 `$GH_TOKEN` 环境变量，未设置则 fallback 到脚本内置 token。

**做了什么（56 秒完成）：**
1. 检测环境（Node.js / git / 网络）
2. 装依赖（jq / rsync / flock）
3. 拉 template → `~/.openclaw/workspace-template/`
4. 初始化 workspace（拷贝 docs/scripts/blocks）
5. **首次块注入** → 创建 `AGENTS.md` / `SOUL.md` / `IDENTITY.md` / `USER.md`（入职即有灵魂）
6. 配凭证（GitHub token + SSH key）
7. 21 项自检（sop-822-check.sh）
8. 注册 cron（每天 06:00 自动同步）

**幂等**：重复跑自动跳过已完成步骤。

---

## 2️⃣ 验证入职成功（3 条命令）

```bash
# 1. 4 个灵魂文件应该有 8 个块标记
for f in AGENTS.md SOUL.md IDENTITY.md USER.md; do
  echo "$f: $(grep -c "openclaw-block" ~/.openclaw/workspace/$f 2>/dev/null) 块"
done
# 预期：每个文件 2 块

# 2. 21 项自检应该全过
bash ~/.openclaw/workspace/scripts/sop-822-check.sh

# 3. cron 应该已注册
openclaw cron list | grep sync-template-6am
```

如果都 ✅ → 入职成功，可以干活了。

---

## 3️⃣ 老 install.sh 跑过的机器补齐灵魂

**症状**：`AGENTS.md` / `SOUL.md` / `IDENTITY.md` / `USER.md` 不存在或没有块标记。

**原因**：老 install.sh 没有 Step 3.5 块注入。

**修复一条命令**：
```bash
bash ~/.openclaw/workspace/scripts/inject-blocks.sh
```

预期输出：
```
完成: 创建 3 / 追加 5 / 跳过 0
```

---

## ⭐ 4️⃣ 永远只需 2 步（自举机制，v1.0.13+）

**任何场景（新 Agent / 老 Agent / 任何 sync 版本）都只需 2 步**：

```bash
# 第 1 步：同步（自举 + 拉最新内容）
bash ~/.openclaw/workspace/scripts/sync-from-template.sh

# 第 2 步：验证
bash ~/.openclaw/workspace/scripts/verify-agent.sh
```

**自举机制原理**（藏在 sync 里，Agent 看不到）：

```
跑 sync 脚本
   ↓
[0.5] git pull workspace-template 拉最新
   ↓
[0.7] 自举检查：cmp 自己 vs template 里的 sync
   ├─ 一致 → 直接进入正常 sync
   └─ 不一致 → 原子更新自己 (cp + mv) → exec 重启
              新版本跑同样检查，一致了，进入正常 sync
   ↓
[1+] 正常 sync (rsync scripts/docs, 块注入, 写日志)
```

**结果**：不管 Agent 用的是 v1.0.0 老 sync 还是 v1.0.13 新 sync，跑出来的效果都一样。
**也解决**新可执行脚本添加（如 verify-agent.sh）— sync 自举后跑新版，rsync 会把新脚本同步过来。

---

## 5️⃣ 自动填 USER.md

入职后 `USER.md` 是空白模板，**用脚本自动填默认值**：

```bash
bash ~/.openclaw/workspace/scripts/fill-user-md-defaults.sh
```

自动填入：
| 字段 | 默认值 |
|------|--------|
| name | 佛罗多老爷 |
| language | 中文 |
| timezone | Asia/Shanghai |
| work_style | think_more_practice_more |
| field_limits | Apple 官方上限 |
| daily_report_time | 08:00 |
| block_threshold.* | 4 项默认配置 |
| comm_style | concise_only |
| current_app | （空）|
| ios_team_id | 9L6N2ZF26B |
| github_user | 从 git config 拿 |
| bundle_id_prefix | com.ggsheng. |

填完即上岗。

---

## 6️⃣ 更新 SOP/脚本（老爷改了之后）

```bash
cd ~/.openclaw/workspace
# 改 docs/ 或 scripts/ 或 blocks/

# 重新打包（自动递增版本号）
bash scripts/distribute-sop.sh

# 推 GitHub
cd dist/openclaw-portable-template
git add -A
git commit -m "v1.0.13: <改了什么>"
git push origin main --force
```

> 注: `distribute-sop.sh` 已内置 token (`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`)，跑它自动 git push --force，无需手填。

**所有 Ubuntu Agent 会在 24 小时内自动同步**（cron 06:00 触发），但**自举后**的 sync 会立即拉到最新内容。

---

## 7️⃣ 一键回滚

```bash
bash ~/.openclaw/workspace/scripts/restore-from-backup.sh
```

列出最近 7 天备份，选一个 → 自动 sha256 验证 + 恢复。

---

## 故障排查（4 个最常见）

| 症状 | 原因 | 解决 |
|------|------|------|
| 灵魂文件不存在 | 老 install.sh 跑过 | `bash scripts/inject-blocks.sh` |
| install.sh 报 "无法连接 github.com" | 网络问题 / token 无效 | 检查 `curl -I https://github.com`；检查 token 是否过期 |
| sync 一直不更新 | cron 没跑 / 锁卡住 | `openclaw cron list` 看状态；`rm -f /tmp/openclaw-sync.lock` |
| 块同步后文件乱了 | 块标记被人手动改坏了 | `bash scripts/restore-from-backup.sh` 回滚 |

> **不需 bootstrap！** v1.0.13+ 自举机制已自动修复老 sync 脚本。

---

## Agent 入职后必做 4 步

1. 跑 `bash scripts/sync-from-template.sh`（自举 + 拉最新）
2. 跑 `bash scripts/inject-blocks.sh`（老 install.sh 才需要）
3. 跑 `bash scripts/fill-user-md-defaults.sh`（自动填 USER.md）
4. 跑 `bash scripts/verify-agent.sh`（验证一切 OK）

**4 步完成后，永远只需 2 步维护：**
- `bash scripts/sync-from-template.sh`（同步）
- `bash scripts/verify-agent.sh`（验证）

---

## 文件位置速查

```
~/.openclaw/workspace/             # Agent 工作目录
├── AGENTS.md / SOUL.md /          # 个性化文件 (块同步保留)
│   IDENTITY.md / USER.md /
│   MEMORY.md
├── docs/                          # 整体替换
├── scripts/                       # 整体替换 (含 sync/verify/inject/fill)
│   ├── sync-from-template.sh      # ⭐ 自举核心
│   ├── verify-agent.sh            # 一键健康检查
│   ├── inject-blocks.sh           # 一次性块注入
│   ├── fill-user-md-defaults.sh   # 自动填 USER.md
│   ├── check-template-version.sh  # heartbeat 轻量检查
│   └── ...
├── blocks/                        # 块内容源
├── .template-version              # 当前同步版本号
├── .sync-log                      # 同步历史
└── .backups/                      # 7天回滚备份

~/.openclaw/workspace-template/    # template 镜像 (git clone)
~/Desktop/ios-{AppName}/           # iOS 项目根 (Mac mini)
```

---

_最后更新: 2026-06-10 v1.0.13 (自举机制, 永远 2 步)_