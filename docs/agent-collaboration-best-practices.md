# Agent 协作最佳实践 — VitaMindGo 2026-06-03 实战提炼

> 8 小时对话 / 30+ commit / 6 个新 SOP 章节沉淀下来的人类-Agent 协作原则

> 🏷️ **平台标签** (本文件中所有建议以标签注明运行平台):
> - **[U]** = 本机 Ubuntu 走 (`~/.openclaw/workspace/projects/ios-{AppName}`)
> - **[M]** = Mac mini 走 (SSH 触发, 实际 iOS 项目在 `~/Desktop/`)
> - **[U+M]** = 两边都走 (代码 / 流程)
> - **[G]** = 通用原则 (适用所有平台)
> 维护者：凯瑟琳·约翰逊
> 来源项目：VitaMindGo (lauer3912/ios-VitaMindGo)
> 适用：所有跨 iOS / Android / Web 等项目的人类-Agent 协作场景

---

## 🎯 5 大黄金原则

### 1. 极简双向 + 结构化 **[G]**

- Human 一句话（`可以` / `执行` / `删掉`）≠ 草率，而是**信任 + 授权**
- Agent 给**结构化方案 + 风险 + 回滚**三件套
- 不啰嗦、不重新问、不越权
- Agent 不假装"还需要更多信息" — 先做再说

**反例**：
- Human: `帮我看看 App 那个问题`
- Agent: `请问是哪个问题？是通知不显示还是截图？`  ← 失分
- Agent: `已检查 P0 是通知前台 banner 缺失，方案如下：1) 加 willPresent delegate 2) 改 Info.plist 3) 重新 archive。三步均可逆，commit a34f9a9 是回滚点。是否执行？`  ← 加分

### 2. 方案先行 + 不可逆前必告知 **[G]**

- 大改动前**列方案 + 风险矩阵 + 回滚路径** → 等 `同意你的方案` 再动
- 不可逆操作（删 GitHub 仓库 / 改 Bundle ID / merge --no-ff / `rm -rf`）**必给影响 + 回滚**
- 守门：SOP 写过的禁止规则（HR-NN）必须**主动避开**，不撞红线

**实战模板**：
```
1. 改动方案 (5 行内)
2. 风险矩阵 (表格)
3. 回滚路径 (tag/backup/undo)
4. 触发条件 (等 Human 同意)
```

### 3. 每步验证 + 关键节点自检 **[U+M]**

- 改一处 → 立即 build / test / screenshot → 报状态 → 再下一步
- 关键节点（提交前 / URL 改动 / 命名变更 / 部署后）跑 **SC-N 自检脚本**
- "我觉得" + "看起来" ≠ 验证；用**命令输出**做证据
- 失败立即报，**别**静默 5+ 分钟

**SOP 配套**：
- SC-58 naming-check.sh (待实现)
- SC-56 5 环 Top-5
- SC-60 URL ↔ 邮箱解耦
- SC-61 GitHub Pages 部署链路

### 4. 踩坑当日沉淀 **[G]**

- 新坑在 24 小时内写进 SOP（不拖到下周）
- 沉淀形式标准化：
  - **HR 规则**（禁什么）
  - **SC 检查项**（自动验什么）
  - **章节正文**（为什么）
- 经验分两层：
  - 项目内 → `commit message` 详细说明
  - 跨项目 → SOP 章节 + HR/SC

**反例**：踩坑后只 commit "fix: something"，下个项目重复踩
**正例**：踩坑后 commit `fix: ... + docs(SOP): add §X.Y (踩坑经验)` 一次完成

### 5. 职责分割 **[G]**

- **Agent**：99% 工作量，独立决策 + 执行 + 汇报
- **Human**：被动审核（签方案 / 签字删 / 决定取舍）
- 违反这条 = 双方都累

**Human 不应做**：
- 决定代码实现细节
- 反复问 Agent "为什么"
- 让 Agent 等 Human 确认 "是否可以"

**Agent 不应做**：
- 频繁向 Human 问细节问题
- 把 Human 当成"测试员"
- 在不可逆操作前"先做了再说"

---

## ⚠️ 4 个反模式 (各平台皆适用) **[G]**（要警惕）

| 反模式 | 后果 | 怎么避免 |
|---|---|---|
| Agent 用 `可以` / `好的` 确认型回复代替执行 | 失去信任 | 直接做事，附证据 |
| Human 给模糊指令 `帮我弄一下 App` | Agent 乱猜 | Human 必须具体（哪个 tab / 哪个 bug）|
| 改完不验证就 commit | 推导出错 / 假阳 | 必跑 test / build / 自检 |
| "等下次再说" 拖 SOP 沉淀 | 经验丢失 | 当日 commit，下不为例 |

---

## 🛠 5 个加速器 (各平台皆适用) **[G]**

| 工具 | 何时用 | 例子 |
|---|---|---|
| **`naming-check.sh` (待实现, 参考 SOP-iOS-Ubuntu-Development §3.1)** | rename / 新项目启动 | 5 项 30 秒核对（Display / Bundle / xcodeproj / Folder / Remote）|
| **`Submission-Checklist.md`** | App Store 提交前 | 5 阶段分步操作（Archive / Connect / Screenshot / Review / Submit）|
| **git tag `vX.Y.Z-pre-XXX`** | 大改前（回滚点）| `v3.0.0-pre-rename` 一键 checkout |
| **`/tmp/.../backup/`** | rename / 大改前 | 31MB folder 镜像 + archive 双备份 |
| **SC-N 自检脚本** | 关键节点 | naming / 5 环 / Pages / URL 完整性 |

---

## 🔑 10 个实战金句（VitaMindGo 2026-06-03 总结）

1. "**每个 commit message 就是审计 log**" — commit message 写 what + why，3 个月后回看还能懂
2. "**不可逆操作前必 git tag**" — tag 0 字节成本，省下 8 小时回滚
3. "**HR 规则用 `禁止...` 开头**" — 负面陈述比正面陈述易守
4. "**SC 检查项用命令验证**" — `grep -rn "X" Sources/` 比文字描述有用 10 倍
5. "**token 失效应立刻承认**" — `nslookup` 失败 ≠ 域名不存在，承认 + 报告比继续错更好
6. "**build SUCCEEDED ≠ 功能正确**" — 跑 19/19 tests + 真机视觉验证
7. "**URL 在 Listing.md 写错 = 1.4 Misleading 拒审**" — App Store Connect 4 URL 必 200 OK
8. "**Display Name ≠ Bundle ID ≠ xcodeproj name ≠ GitHub repo ≠ Swift class**" — 5 个名字必映射明确（见 `§1.2.3 三层映射`）
9. "**邮箱 = `@techidaily.com`，URL = `lauer3912.github.io/...`**" — 域名解耦（HR-35 / SC-60）
10. "**iPad page-style TabView 不可靠，用 `VITA_INITIAL_TAB` env 多次独立启动**" — 见 iPad-Screenshot-Recipe.md

---

## 📅 维护记录

| 日期 | 变更 | 来源 |
|------|------|------|
| 2026-06-03 | 初版，从 VitaMindGo 项目 8 小时实战提炼 | `VitaMindGo` v3.0.0 上架准备 |

## 🔗 相关文档

- **SOP 总纲**：`docs/SOP-iOS-Local-Development.md` (4857 行 / 81 HR / 61 SC)
- **iPad 截图速查卡**：`docs/iPad-Screenshot-Recipe.md`
- **naming-check 脚本**：`docs/naming-check.sh` (待实现)
- **VitaMindGo 实战 commit 历史**：`https://github.com/lauer3912/ios-VitaMindGo`
- **SOP §1.2.3 项目命名三层映射**：Display Name / xcodeproj / GitHub repo / Bundle ID 映射规范
- **SOP §9.0 提交流程 Top-5 关键环节**：5 环 pipeline + 检测命令
