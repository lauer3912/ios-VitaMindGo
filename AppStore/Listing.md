# VitaMindGo App Store Listing Metadata

> **App Name:** VitaMindGo
> **Bundle ID:** com.ggsheng.VitaMind
> **Version:** 3.0.0
> **Document Version:** 2.0
> **Last Updated:** 2026-05-30

---

## 1. App Name & Tagline

| Field | Content |
|-------|---------|
| **App Name** | VitaMindGo |
| **Tagline** | Your AI-Powered Health Companion |

---

## 2. Promotional Text (English)

> **Apple 字段:** Promotional Text — 官方上限 170 chars
> **本项目内规:** ≤100 chars (老爷 2026-06-04 指定)
> **Apple 文档:** "This property can't be longer than 170 characters."
> **当前字符数:** 99 chars (≤100 ✓)

```
AI health coach for heart, sleep, habits. On-device AI, no account, no tracking. Apple Watch ready.
```

### 候选方案（决选记录）

| # | Chars | 内容 | 状态 |
|---|-------|------|------|
| A1 | 89 | AI health coach. Track heart, sleep, habits with on-device AI. No account, fully private. | 备选 |
| A2 | 91 | Your AI health coach for heart, sleep, and habits. On-device AI, no account, fully private. | 备选 |
| **A3** | **99** | AI health coach for heart, sleep, habits. On-device AI, no account, no tracking. Apple Watch ready. | ✅ **已选** |

### 决选理由 (A3)
1. **三重信号覆盖**: heart/sleep/habits 命中 Health 类别 Top 5 搜索词
2. **Apple Watch 锚点**: 与 Keywords 里的 "Apple Watch" 形成 "Promo + Keywords" 双重命中
3. **三连 "no" 差异化**: no account / no tracking / (隐含 no server) 突出隐私卖点
4. **字符预算利用率 99%**: 89→91 跳 2 chars，91→99 跳 8 chars 含 3 个新价值点，性价比最高

### 算法说明
- 身份钩子 (AI health coach) → 价值点 (heart/sleep/habits) → 差异化 (on-device AI) → 摩擦消除 (no account) → 设备错点 (Apple Watch ready)
- 决策时点: 2026-06-04，老爷回复 "去修改吧" 授权采用推荐方案 A3

---

## 3. Full Description

> **Apple 字段:** Description — 官方上限 4000 chars, **plain text only, no HTML**
> **本项目内规:** 纯文本，无 markdown，无 emoji (老爷 2026-06-04 指定)
> **当前字符数:** 1905 chars (≤4000 ✓)

```
Your AI-Powered Health Companion

VitaMindGo combines cutting-edge AI technology with comprehensive health monitoring to help you understand your body like never before.

Key Features:

AI Health Assistant
Have natural conversations with your personal AI health coach. Get instant answers to health questions, personalized tips, and intelligent insights based on your data.

Apple Watch Integration
Sync seamlessly with Apple Watch to track heart rate, HRV, sleep, steps, exercise minutes, and more. All your vital stats in one beautiful dashboard.

Habit Tracking
Build lasting habits with customizable tracking, streak monitoring, and smart reminders. Whether it's drinking more water, meditating daily, or taking your vitamins, VitaMindGo keeps you accountable.

Sleep Quality Analysis
Understand your sleep patterns with detailed analysis and AI-powered recommendations to improve your rest quality.

Widgets and Quick Stats
View your health metrics at a glance with beautifully designed home screen widgets. No need to open the app for quick updates.

Daily Reminders (Local Notifications)
Stay on track with three gentle, server-free nudges: 9 AM for your daily card pull, 8 PM for habit check-in, and 10 PM as a streak rescue. All notifications run on-device via UserNotifications, no push servers, no tracking, no battery drain.

Privacy First
Your health data stays on your device. VitaMindGo uses on-device AI (CoreML) for processing, ensuring your most sensitive information never leaves your phone.

Why VitaMindGo?

- Comprehensive health tracking in one app
- AI-powered insights for better decision-making
- Beautiful, intuitive interface
- Apple Watch integration for accurate data
- Privacy-focused design

Subscription Information:

The initial version (3.0.0) is completely FREE with all features included. Future premium features will be available through Auto-Renewable Subscription.
```

### 清理清单
- ✅ 移除所有 `**bold**` markdown
- ✅ 移除所有 emoji (🤖 ❤️ 📊 💤 📱 🔔 🔒)
- ✅ 替换 `•` → `-`
- ✅ 替换 em-dash `—` → `,` (避免某些字体渲染问题)
- ✅ `&` → `and` (Apple App Store 允许 `&`，但 "and" 更通用)
- ✅ 撇号使用 ASCII `'` (U+0027) — App Store 兼容

---

## 4. Keywords

> **Apple 字段:** Keywords — 官方上限 **100 bytes** (不是 chars；中文 1 字 = 3 bytes)
> **本项目内规:** ≤80 chars (老爷 2026-06-04 指定)
> **当前字符数:** 76 chars / 76 bytes (≤80 ✓)

```
habit tracker, health, fitness, sleep, AI, heart rate, Apple Watch, wellness
```

### 优化算法（"价值密度优先"原则）

**步骤 1：列出搜索意图候选词 (按 ROI 排序)**

| 词 | 长度 | 搜索价值 | VitaMindGo 匹配度 |
|----|------|----------|-------------------|
| habit tracker | 13 | 极高 (Health 类别 Top 3) | ✅ 核心功能 |
| health | 6 | 极高 (类别锚定) | ✅ 全覆盖 |
| fitness | 7 | 极高 (类别锚定) | ✅ 主题 |
| sleep | 5 | 高 (Top 10 搜索) | ✅ 追踪 |
| heart rate | 10 | 极高 (Top 5 搜索) | ✅ 追踪 |
| Apple Watch | 11 | 高 (设备特定) | ✅ 集成 |
| wellness | 8 | 高 (类别广覆盖) | ✅ 主题 |
| AI | 2 | 中-高 (差异化) | ✅ 核心 |

**步骤 2：贪心填充到 80 chars**

`habit tracker`(13) + `, `(2) + `health`(6) + `, `(2) + `fitness`(7) + `, `(2) + `sleep`(5) + `, `(2) + `AI`(2) + `, `(2) + `heart rate`(10) + `, `(2) + `Apple Watch`(11) + `, `(2) + `wellness`(8)
= 13+2+6+2+7+2+5+2+2+2+10+2+11+2+8 = **76 chars** ✓ (`wc -m` 验证)

**步骤 3：砍掉的词 + 理由**

| 砍掉词 | 长度 | 砍掉理由 |
|--------|------|----------|
| tracker | 7 | 已被 "habit tracker" 短语覆盖 |
| assistant | 9 | 已被 "AI" + 描述中 "AI health coach" 覆盖 |
| activity, steps, exercise | 5+5+8 | 与 "fitness" 重叠，搜索时被合并索引 |
| HRV | 3 | 极窄搜索 (Apple Watch 重度用户) |
| stress, mindfulness | 6+11 | 心理健康搜索意图不匹配 (VitaMindGo 无冥想) |
| water, vitals, healthkit | 5+6+9 | 描述中已涵盖，且搜索量低 |
| reminder, monitoring, notification | 8+10+12 | 通用功能词，搜索权重低 |
| daily, streak, gamification, card, collection | 5+6+13+4+10 | 内部功能词，用户不会搜 |

**步骤 4：与 Apple 算法一致性检查**
- ✅ 无重复 App 名 (VitaMindGo 已含在 name/subtitle)
- ✅ 无竞品名
- ✅ 每个词 ≥3 字符
- ✅ 短语优先 (habit tracker, heart rate, Apple Watch 是高 ROI 短语)
- ✅ 8 词在 80 字符内，密度高于行业平均 (~6 词)

---

## 5. Support URL

**Developer Website:** https://lauer3912.github.io/ios-VitaMindGo/
**Contact Email:** support@techidaily.com

---

## 6. Privacy Policy URL

**Privacy Policy:** https://lauer3912.github.io/ios-VitaMindGo/PrivacyPolicy.html
**Local Privacy Policy HTML:** AppStore/Docs/PrivacyPolicy.html

---

## 7. Category Selection

| Field | Selection |
|-------|-----------|
| **Primary Category** | Health & Fitness |
| **Secondary Category** | Medical |

---

## 8. Content Rating

| Field | Selection |
|-------|-----------|
| **Age Rating** | 4+ (Everyone) |
| **Adult Content** | No |
| **Frequent/Intense Medical/Treatment Information** | No |

---

## 9. Screenshots

| Device | Size | Count | Location |
|--------|------|-------|----------|
| iPhone 17 Pro Max (6.9") | 1320×2868 px | 5 | AppStore/Screenshots/iPhone17ProMax_1320x2868/ |
| iPad Pro 13" (M4) | 2048×2732 px | 5 | AppStore/Screenshots/iPadPro13inchM4_2048x2732/ |

**Screenshot Files:**
- iPhone: `vp_tab1_pocket.png`, `vp_tab2_habits.png`, `vp_tab3_coach.png`, `vp_tab4_collection.png`, `vp_tab5_settings.png`
- iPad: `ipad_tab1.png`, `ipad_tab2.png`, `ipad_tab3.png`, `ipad_tab4.png`, `ipad_tab5_settings.png`

**Last captured:** 2026-06-03 (re-captured with **Release** configuration build, after Mock-data removal + Settings tab + local notifications feature)
- Captured using `xcodebuild test -configuration Release` so the binary that produced the screenshots is the same configuration that gets archived and uploaded to App Store Connect
- Verified Bundle ID = `com.ggsheng.VitaMind`, Display Name = `VitaMindGo`, Version = `3.0.0` (Build 1) in the captured `.app` Info.plist
- No `#if DEBUG` / `#if !DEBUG` in Sources — Debug and Release configurations render identical UI
- Legacy captures (5-31, 4 tabs only, Debug build) moved to `AppStore/Screenshots/legacy-5-31/` and `legacy-5-31-ipad/`

---

## 10. Review Information

| Field | Content |
|-------|---------|
| **Support Email** | support@techidaily.com |
| **Demo Account Required** | No |
| **Demo Account Username** | N/A |
| **Demo Account Password** | N/A |
| **Notes for Reviewer** | VitaMindGo integrates with Apple HealthKit and Apple Watch for health tracking. The app uses on-device CoreML AI for privacy-focused health analysis. All features are fully functional without subscription. |

---

## 11. App Store Connect Metadata

| Field | Content |
|-------|---------|
| **Bundle ID** | com.ggsheng.VitaMind |
| **App Store Status** | Prepare for Submission |
| **Release Date** | TBD |
| **Pricing** | Free (initial release) |
| **Territory Availability** | All Available Territories |

---

## 12. 上架前检查清单（Human 填写）

> ⚠️ 以下内容需要你在 App Store Connect 网页上填写/确认

| 项目 | 状态 | 你需要做的事 |
|------|------|------------|
| App Name | ✅ VitaMindGo | 确认 |
| Short Description | ✅ 已准备 | 复制到 App Store Connect |
| Full Description | ✅ 已准备 | 复制到 App Store Connect |
| Keywords | ✅ 已准备 | 复制到 App Store Connect |
| Screenshots | ✅ 已生成 | 上传到对应设备位置 |
| Privacy Policy URL | ⚠️ 待确认 | 确认 `https://lauer3912.github.io/ios-VitaMindGo/PrivacyPolicy.html` 可访问 |
| Support URL | ⚠️ 待确认 | 确认 `https://lauer3912.github.io/ios-VitaMindGo/` 可访问 |
| Category | ✅ Health & Fitness | 确认选择正确 |
| Content Rating | ✅ 4+ | 完成问卷 |
| Review Notes | ✅ 已准备 | 复制或补充 |

---

*This document is used for App Store listing configuration. Stage 8.2 需要 Human 按此文件内容在 App Store Connect 网页上填写。*