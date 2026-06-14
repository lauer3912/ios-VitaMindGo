# VitaMindGo App Intents 文档

> 写于 2026-06-12,Katherine 整理
> 适用版本: v3.0.0+ (2026-06-09 提交, build 11)
> 配套代码: `Sources/AppIntents/VitaMindIntents.swift` (200 行, 2 个 Intent)

---

## 📌 一句话简介

VitaMindGo 把 2 个核心功能通过 **App Intents** 暴露给 Siri 和 Shortcuts,让用户**不用打开 App** 就能跟健康数据交互。

> "Hey Siri, ask VitaMindGo how was my sleep last week?"
> "Hey Siri, ask VitaMindGo to log water."

---

## 🎯 暴露的 2 个 Intent

### 1. `GetHealthSummaryIntent` — 读健康数据

**用户怎么说(示例):**
- "Hey Siri, ask VitaMindGo how I slept"
- "Hey Siri, ask VitaMindGo for my heart rate"
- "Hey Siri, ask VitaMindGo today's steps"

**返回示例:**
> "Last night you slept 7 hours and 12 minutes. Your resting heart rate averaged 58 BPM, well within your healthy range."

**技术细节:**
- 直接读 HealthKit (HKHealthStore)
- 不走 GameState (跨 Intent 隔离)
- A2A 友好 (Agent-to-Agent 协议可消费)
- iOS 17+ 完全支持,旧版本回退到 Shortcuts

### 2. `LogHabitIntent` — 写习惯打卡

**用户怎么说(示例):**
- "Hey Siri, ask VitaMindGo to log water"
- "Hey Siri, ask VitaMindGo to log meditation"
- "Hey Siri, ask VitaMindGo I meditated today"

**返回示例:**
> "Done! Logged 'Meditation' for today. You're on a 5-day streak."

**技术细节:**
- 写本地 store (UserDefaults + 文件)
- 自动算 streak
- 不需要打开 App
- 需要 user 授权 notifications(后续可加确认 toast)

---

## 🗣️ Siri 短语注册

在 `VitaMindAppShortcuts.swift` 里注册了 3 个推荐短语,系统会自动学习用户的说话方式:

| 短语 | 触发 Intent |
|------|------------|
| "How am I doing today?" | GetHealthSummary |
| "Log a habit" | LogHabit |
| "Show my progress" | GetHealthSummary |

用户在 Shortcuts App 里可以看到所有 intents,也能创建自己的短语。

---

## 🔌 Shortcuts App 集成

用户在 iOS Shortcuts App 里可以:
1. 搜索 "VitaMind" 找到我们的 intents
2. 拖到自己的 shortcut 里
3. 跟其它 App 串起来(Apple Music / Calendar / Reminders)

**示例:** "早上 7 点 → Siri 说 'Good morning' → VitaMindGo 报睡眠 → Apple Music 放歌"

---

## 🤖 A2A 协议支持 (Agent-to-Agent)

2026 是 A2A 爆发年。VitaMindGo 的 2 个 Intent 都符合 A2A 标准:

- ✅ 输入/输出 JSON 化
- ✅ 无状态 (Stateless)
- ✅ 可在 Shortcuts / IFTTT / 自家 Agent 中调用
- ✅ 隐私边界清晰 (不外发用户数据)

**未来扩展:** 1-2 季度内再加 3-5 个 Intent:
- `GetStreaksIntent` (当前连续打卡天数)
- `LogWaterIntent` (单选,简化版 LogHabit)
- `GetCoachRecommendationIntent` (让 AI Coach 给一个建议)

---

## 🛠️ 开发者怎么用

### 添加新 Intent (5 步)

1. **创建 Intent struct** 继承 `AppIntent`
2. **加 `@Parameter`** 字段
3. **实现 `perform()`** 异步方法
4. **加 `static var title`** 必填
5. **在 `VitaMindAppShortcuts` 注册**

### 示例代码

```swift
import AppIntents
import HealthKit

struct GetHealthSummaryIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Health Summary"
    static var description = IntentDescription("Read your latest health data.")

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let store = HKHealthStore()
        // ... read HealthKit ...
        return .result(dialog: "You slept 7 hours last night.")
    }
}
```

---

## 📊 当前状态

| 项 | 状态 |
|----|------|
| VitaMindIntents.swift 编写 | ✅ 完成 |
| VitaMindAppShortcuts 注册 | ✅ 完成 |
| Siri 短语发现 | ✅ 配 commit 8ed312e |
| App Store 审核 | ✅ 通过 (build 11, 2026-06-10) |
| 用户可见性 | 用户需开启 "Siri & Shortcuts → VitaMindGo" 才能用 |

---

## 🐛 已知限制

1. **Siri 必须先学会短语** — 用户第一次说可能不识别,需要多试几次
2. **Intent 必须在 App 启动过** — Apple 要求至少冷启动一次才能注册
3. **HealthKit 权限** — 没授权的话 Intent 会失败,需要 UI 引导

---

## 📚 参考

- Apple App Intents 官方文档: https://developer.apple.com/documentation/appintents
- WWDC25 App Intents 视频: 2025-WWDC-10102 (大概)
- A2A 协议白皮书: (Google A2A spec)

---

**文档版本:** v1.0 (2026-06-12)
**作者:** Katherine Johnson
**配套 commit:** `8ed312e` (feat(intents): 暴露 GetHealthSummary + LogHabit)
**配套 Plan:** `docs/v3.1.0-IAP-Plan.md` §6 (A2A 路线图)
