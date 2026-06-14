# VitaMindGo 液态玻璃 (Liquid Glass) 重设计计划

> **状态**: 设计阶段,等 iOS 27 SDK 发布 (预估 2026 年 9 月)
> **触发**: 2026-06-11 20:50 老爷 QQ 派工
> **写于**: 2026-06-11 21:00 北京时间
> **关联**: `2026-2028-iOS-App-Up.md` §二.1 (WWDC26 液态玻璃强制)
> **关联**: `docs/v3.1.0-IAP-Plan.md` (UI 部分要一起改)

---

## 🚨 强制时间线

| 日期 | 事件 |
|------|------|
| 2026-06-09 ~ 11 | WWDC26 发布 iOS 27 + 液态玻璃规范 |
| **2026 年 9 月** | **iOS 27 正式发布 + 液态玻璃强制适配期开始** |
| 2026 年 12 月 | Apple 大概率开始 reject 不适配的更新 |
| 2027 年 3 月+ | 完全强制 (新提交必须适配) |

**我们还有 ~3 个月 (90 天)准备时间**。必须在 9 月前完成重设计 + 测试。

---

## 🪟 当前 Xcode 状况 (2026-06-11 实测)

```bash
$ xcodebuild -version
Xcode 26.5  Build 17F42
$ xcrun simctl list runtimes | grep iOS
iOS 18.6 (com.apple.CoreSimulator.SimRuntime.iOS-18-6)
iOS 26.5 (com.apple.CoreSimulator.SimRuntime.iOS-26-5)
```

- iOS 27 SDK: **未发布** (预估 9 月随 iOS 17 GM 一起出)
- 当前 SDK: iOS 26.5
- 当前项目 deployment target: iOS 17.0 (兼容性好, 不动)

**今晚能做的**: 设计计划 + 当前 UI 审计 + 占位 API stub
**做不到的**: 实际运行液态玻璃效果 (需要 iOS 27 模拟器)

---

## 🎨 液态玻璃设计规范 (来自文档)

### 核心特征
- **半透明 (translucent)**: App 元素有玻璃质感, 透出背后内容
- **圆角化 (rounded)**: 所有控件圆角更大, 符合 iOS 27 设计语言
- **轻盈动态 (light motion)**: Metal 4 引擎优化, 自然光影过渡
- **折射 (refraction)**: 多层元素之间产生光学折射效果
- **动态模糊 (dynamic blur)**: 背景实时模糊, 跟用户操作联动

### 系统级要求
- ✅ **全局透明度调节**: 3 档 (高通透 / 标准 / 高对比度磨砂)
- ✅ **图标多层材质**: 多层液态玻璃, 折射效果
- ✅ **状态栏圆润化**: WiFi/电池/信号图标无边框圆润
- ✅ **Metal 4 渲染**: 自动应用, 大部分透明效果 GPU 加速
- ⚠️ **开发者必须**: 确保在所有透明度档位下文字可读

---

## 📋 VitaMindGo 当前 UI 审计 (2026-06-11)

### 必须改的 (透明背景组件)
| 位置 | 当前 | 改后 | 复杂度 |
|------|------|------|--------|
| Tab Bar (5 Tab) | 实体背景色 | 液态玻璃 material | 中 |
| Navigation Bar | 标准 SwiftUI 默认 | `.toolbarBackground(.ultraThinMaterial)` | 低 |
| Card (HealthCard, HabitCard) | 实体 surface 颜色 | 玻璃材质 + backdrop blur | 中 |
| Coach Chat 气泡 | 实体背景 | 玻璃 + 微透明 | 低 |
| Settings 列表 | Form 默认 | 玻璃 section 背景 | 中 |
| Paywall 卡片 (新增) | 已用 surface | 改玻璃材质 | 低 |

### 必须改的 (动态效果)
| 位置 | 当前 | 改后 |
|------|------|------|
| 卡片翻转/闪光 | SwiftUI 基础动画 | Metal 4 shader 增强 |
| 状态过渡 | 标准 transition | 动态模糊 + 折射 |
| 滚动行为 | 标准 | 弹性 + 玻璃化 header |

### 不用改的
- 数据内容 (文字/数字) — 保持清晰可读
- 功能按钮 (核心交互) — 保持 tap target 大小
- HealthKit 数据展示 — 数据为先, 美观次之

---

## 🔧 实施计划 (等 9 月 SDK)

### Phase 1 (D1-D7 SDK 发布后立即)
- [ ] D1: 升级 Xcode 到 iOS 27 GM
- [ ] D2: 升级 deployment target 17.0 → 18.0 (或保留向后兼容)
- [ ] D3: 跑全部测试, 找出 iOS 27 编译警告
- [ ] D4: 启用 SwiftUI `.glassEffect()` (推测 API) + Material 升级
- [ ] D5: 改 Tab Bar + Navigation Bar
- [ ] D6: 改所有 Card 组件
- [ ] D7: 全局 3 档透明度测试

### Phase 2 (D8-D14)
- [ ] D8: 改 Paywall 玻璃化
- [ ] D9: 改 Chat 气泡
- [ ] D10: 改 Settings section
- [ ] D11: 改 Onboarding 流程
- [ ] D12: 改 Widget + Lock Screen
- [ ] D13: 改 App Icon 多层材质
- [ ] D14: 性能 profile (Metal 4 GPU usage)

### Phase 3 (D15-D21)
- [ ] D15: 沙盒 3 档透明度全测试
- [ ] D16: iPhone + iPad 多端一致性
- [ ] D17: Apple Watch 重新适配 (液态玻璃 也要)
- [ ] D18: 截图重做 (8 张 iPhone + 4 张 iPad)
- [ ] D19: App Store 描述加 "Designed for iOS 27 + Liquid Glass"
- [ ] D20: 提交审核 + 标 "适配液态玻璃"
- [ ] D21: 监控审核结果

### 风险 & 对策
| 风险 | 对策 |
|------|------|
| iOS 27 SDK 推迟发布 | 当前 3 个月准备, 即使推迟 1 个月也够 |
| 液态玻璃在低端设备掉帧 | 启用 "Reduce Transparency" 自动降级 |
| 现有深色/浅色主题兼容 | VitaTheme 已经有完整 Light/Dark, 加 glass 变体 |
| Apple Watch 也要重设计 | Watch 单独 workstream, 不跟 iPhone 混 |
| EU AI Act 重新审核 | 液态玻璃是 UI, 不影响 AI Act 风险等级 |
| 审核员拒 (说"不完整") | 提交前用 3 档透明度全跑一遍截图, 证据齐全 |

---

## 🧪 透明度 3 档测试矩阵

每档必须验证:
| 档位 | 文字可读性 | 颜色对比度 | Tap target |
|------|------------|-----------|-----------|
| 高通透 (高 transparent) | 必须 | WCAG AA | 44pt+ |
| 标准 (默认) | 必须 | WCAG AA | 44pt+ |
| 高对比度磨砂 (磨砂加重) | 必须 | WCAG AAA | 44pt+ |

---

## 📦 今晚占位 (SDK 不可用, 只能准备)

### 已写 (今晚):
- `docs/liquid-glass-redesign-plan.md` (本文件)

### 待写 (SDK 发布后):
- `~/Desktop/ios-VitaMind/Sources/Core/Theme/LiquidGlassTheme.swift`
  - 3 档透明度 token
  - Glass material 封装
  - 自动降级 (低端设备)
- `~/Desktop/ios-VitaMind/Sources/Core/Theme/AdaptiveBackground.swift`
  - 监听系统透明度设置
  - 动态切换 material

### 不用现在写 (SDK 没有, 写也跑不起来):
- 任何调用 iOS 27 API 的代码
- 任何 Metal 4 shader
- 任何液态玻璃视觉效果

---

## 🆘 紧急应对 (如果 9 月前没准备好)

1. **最少适配方案**: 只改 Tab Bar + Navigation Bar (2 处), 其他保持
   - 9 月强制前能通过审核最低限度
   - 30 天冲刺, 1 个工程师就够
2. **延后版本**: v3.1.x 维持, v3.2.0 (10 月) 完整适配
   - 风险: 9 月后 v3.2.0 才出, 中间新功能提交可能拒
3. **外包设计**: 把 Theme 整包给设计师做
   - 钱: $5k-10k
   - 时间: 2-3 周
   - 适配: 需要 iOS 27 SDK 发布后, 否则设计师也跑不起来

**我的判断**: 现在准备 + 9 月后 4 周冲刺 = 12 周总时间, 够用。
**风险点**: iOS 27 SDK 发布是否准时 (WWDC 之后通常 3 个月 GM, 应该稳)。

---

## 📂 关联文档

- `2026-2028-iOS-App-Up.md` §二.1 (WWDC26 液态玻璃强制)
- `docs/v3.1.0-IAP-Plan.md` (IAP/订阅, 期间 UI 一起改)
- `docs/app-intents-plan.md` (A2A 趋势, 跟液态玻璃并行)

---

**计划版本**: v1.0 (2026-06-11 21:00 起草)
**下次更新**: iOS 27 SDK 发布后 (预估 9 月) 启动 Phase 1
**维护者**: Katherine (凯瑟琳·约翰逊)