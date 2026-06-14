# Dev Agent 重做指令 — lauer3912/ios-StretchFlow

> **来源**: 佛罗多老爷 2026-06-13 21:14 拍板
> **触发事件**: Dev agent 上一条回答违反 SOP §0.9 Greenfield Bootstrap 7-phase (HR-94/95/93/96)
> **收件人**: Ubuntu 服务器的研发 Agent (dev OpenClaw)
> **作用**: 让 dev agent 撤回原回答, 严格按 SOP 7-phase 重做

---

## 0. 上下文 (给 dev agent 看)

老爷原任务:
> "https://github.com/lauer3912/ios-StretchFlow 这是一个老项目, 还没有提交审核通过. 你把它搞定"

Dev agent 上一条回答的**主要违规**:
1. ❌ 完全没走 Greenfield Bootstrap 7-phase
2. ❌ HR-95 违反 — 替 user 决定 action (列了 4 件"我会做"没问 user)
3. ❌ HR-94 违反 — 分 3 批问 user 3 件事 (Mac mini / 协议 / 截图)
4. ❌ Phase 4 深度诊断没做 (没跑 sop-822-check.sh, 没技术栈探查)
5. ❌ State 分类未做 (4 态 A/B/C/D)
6. ❌ 错误/假数据 (代码 3200 行没验证, ASC 已建说没建)
7. ❌ 问"你有 Mac mini 吗?" — 自己的 SOP 早配好 `ssh macmini` 通道
8. ❌ 错把 Listing.md 当待办清单
9. ❌ 缺持续汇报 (没 cron, 没早报)
10. ❌ 路径约束可能违反 (HR-93/96)

---

## 1. 重做指令 (复制发给 dev agent)

```
佛罗多老爷要求重做, 严格走 SOP-iOS-Ubuntu-Development.md §0.9
Greenfield Bootstrap 7-phase。上一条回答违反 HR-94/95, 撤回。

═══════════════════════════════════════════════════
Phase 0: 解析 URL
═══════════════════════════════════════════════════
URL: https://github.com/lauer3912/ios-StretchFlow
提取: owner/repo = lauer3912/ios-StretchFlow
写到当日 memory (追加, 不覆盖):
  echo "## $(date '+%H:%M') 收到重做任务: lauer3912/ios-StretchFlow" \
    >> ~/.openclaw/workspace/memory/$(date '+%F).md

═══════════════════════════════════════════════════
Phase 1: 验证访问 (1-2 min, 跑这 4 条, 贴输出)
═══════════════════════════════════════════════════
1) gh repo view lauer3912/ios-StretchFlow \
     --json name,description,defaultBranchRef,isPrivate,archived,pushedAt
2) gh api repos/lauer3912/ios-StretchFlow/contents/README.md \
     --jq .content | base64 -d
3) gh api repos/lauer3912/ios-StretchFlow/commits \
     --jq '.[].commit.message' | head -5
4) gh api repos/lauer3912/ios-StretchFlow \
     --jq '{default_branch,open_issues,size,stargazers_count}'

任一失败 → 4 种处理 (详见 SOP §0.9.3):
  404 Not Found  → 停, 问 user 链接是否正确, 是否 private
  403 Forbidden  → 看 message, 限流等 60s, scope 不足问 user 加 repo 权限
  archived: true → 警告 user, 建议 fork 再开发
  gh: not found  → 跳回 §0.1 补装

成功信号: Phase 1.1 返回 JSON + Phase 1.2 解出 README → 进入 Phase 2

═══════════════════════════════════════════════════
Phase 2: 浅克隆到 /tmp/intake-*/ (HR-93/96 硬性)
═══════════════════════════════════════════════════
cd /tmp
rm -rf /tmp/intake-lauer3912-ios-StretchFlow
git clone --depth 1 https://github.com/lauer3912/ios-StretchFlow.git \
  /tmp/intake-lauer3912-ios-StretchFlow
cd /tmp/intake-lauer3912-ios-StretchFlow

# 4 态分类 (贴 ls 输出 + 你的判断):
ls -la
cat AppStore/Listing.md | head -50
ls AppStore/Screenshots/
ls Sources/

你的分类: A 空仓 / B 半成品 / C 完整 iOS App / D 非 iOS?
提示: 仓库已建 xcodeproj + xcarchive + Listing.md 1.0.0 → 倾向 State C
验证依据: 项目根有 StretchGoGo.xcodeproj/ + StretchGoGo.xcarchive/ 吗?

═══════════════════════════════════════════════════
Phase 3: 一次问完 (HR-94 硬性, State C 跳过 1-5)
═══════════════════════════════════════════════════
**禁止分批问。必须一次发完 4 个问题:**

6. 这是新项目 (App Store 还没 listing) 还是已有项目继续?
7. 直接写代码 还是 先出 PRD + 功能清单?
8. 截止时间?
+ 1 件: 你想让我做什么? A 审计 / B 修 bug / C 加功能 / D 部署

(我等你 4 答一起回, 不接受 1+1+1+1)

═══════════════════════════════════════════════════
Phase 4: 深度诊断 (State C 必跑)
═══════════════════════════════════════════════════
# 21 项 iOS App 自检
cp ~/.openclaw/workspace/openclaw-portables/scripts/sop-822-check.sh \
   /tmp/intake-lauer3912-ios-StretchFlow/
cd /tmp/intake-lauer3912-ios-StretchFlow
WORKSPACE=$HOME/.openclaw/workspace \
  PROJECT=/tmp/intake-lauer3912-ios-StretchFlow \
  bash sop-822-check.sh

# 技术栈探查
grep IPHONEOS_DEPLOYMENT_TARGET Sources/**/*.pbxproj 2>/dev/null | head
grep SWIFT_VERSION Sources/**/*.pbxproj 2>/dev/null | head
grep -rh '^import ' Sources/ 2>/dev/null | sort | uniq -c | sort -rn | head -10
cat Sources/Resources/Info.plist 2>/dev/null | grep -E "NSHealth|aps-|NSUserActivity" | head
ls Sources/*.entitlements 2>/dev/null && cat Sources/*.entitlements

# 1 页纸 status report (贴出来)

═══════════════════════════════════════════════════
Phase 5: 决定 action (HR-95 必给 4 选项)
═══════════════════════════════════════════════════
State C 必给 4 选项:
  C1: 审计 (出 SOP 合规报告 + 改进建议)
  C2: 修 bug (sop-822-check 找问题)
  C3: 加新功能 (user 说加什么)
  C4: 部署 (走 §8 archive → upload → submit)

主动推荐 2-3 个方向 (HR-95 增强, 不沉默), 但 user 选哪个你才走哪个

═══════════════════════════════════════════════════
Phase 6: 按 user 拍的选项走对应 §X
═══════════════════════════════════════════════════

═══════════════════════════════════════════════════
Phase 7: 持续汇报
═══════════════════════════════════════════════════
注册 cron 每天 8:00 早报 (openclaw cron add)

═══════════════════════════════════════════════════
**绝对禁止** (HR 锁)
═══════════════════════════════════════════════════
- 替 user 决定 action (HR-95)
- 分批问 user 关键信息 (HR-94, 1 个问题发 1 次就是违规)
- 直接 git clone 到 ~/.openclaw/workspace/ (HR-93/96, 必走 /tmp/intake-*/)
- 跳过 Phase 0-4 任何步骤
- 给"代码 3200 行"这种没验证的假数据
```

---

## 2. 给 dev agent 的 Phase 5 推荐话术 (HR-95 增强)

State C 4 选项的主动推荐 (让 dev agent 写 Phase 5 时参考):

```
我推荐 C1 审计先走一遍. 原因:
1. 这项目 6-10 最后 push, Listing.md 1.0.0, 但还没审核通过
2. 不知道上次卡在哪, 先看完整状况再决定动什么
3. C1 审计 = sop-822-check + SC-1~70 全过 + 列改进项, 不动代码, 风险最低
4. 审计完你可以选 C2 修发现的 bug, 或 C4 部署
5. 也可能 C1 完发现需要先 C3 加功能 (比如订阅 backend 还没接), 但先看清

C4 部署不建议先做: 1.4.1 / 1.4.2 风险未知, 跑了也是拒.
C2 修 bug 除非你明确知道 bug 是什么.
C3 加功能 除非你明确说加什么.
```

---

## 3. Katherine 帮跑 Phase 1+2+4 证据 (5 分钟)

如果老爷让 Katherine 跑, 输出会贴在下面 `## 4. 预跑证据` 段, dev agent 可直接复用 (但 SOP 严格要求她跑, 所以这是备用方案, 不是默认)。

---

## 4. 预跑证据 (待 Katherine 跑后填, 或 dev agent 自己跑)

### Phase 1 输出

> (待填)

### Phase 2 输出

> (待填)

### Phase 4 输出 (sop-822-check.sh 结果)

> (待填)

---

## 5. 时间线

- 21:14 老爷拍板"按方案 A"
- 21:15 Katherine 写完本文件
- 21:XX 老爷复制发 dev agent
- 21:XX dev agent 跑 Phase 0/1/2 (10-15 min)
- 21:XX 老爷一次性答 Phase 3 4 问
- 21:XX dev agent 跑 Phase 4 (5 min)
- 21:XX 老爷选 Phase 5 4 选项
- 21:XX+ dev agent 跑 Phase 6 + 7

---

_最后更新: 2026-06-13 21:15 by Katherine_
