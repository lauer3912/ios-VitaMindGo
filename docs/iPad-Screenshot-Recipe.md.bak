# iPad Screenshot Recipe

> 跨 iOS 项目可复用的"在 iPad Pro 13" 模拟器上自动截全 tab 截图"速查卡
> 来源:VitaPocket 2026-06-03 实战沉淀(见 SOP `§8.17`)
> 维护者:凯瑟琳·约翰逊

> 🏷️ **平台标签** (本文件所有步骤以标签注明运行平台):
> - **[M]** = Mac mini 上跑 (iOS 项目在 `~/Desktop/ios-{AppName}/`, xcodebuild 在 macOS)
> - **[U]** = 本机 Ubuntu 跑 (调试脚本, 拉回截图到本地 `~/.openclaw/workspace/screenshots/ios-{AppName}`)

---

## 🎯 目标

用 XCUITest 自动遍历 iPad 上所有 tab,截 5-6 张 2048×2732 PNG 用于 App Store 截图。

**核心难点**(5 分钟踩坑清单):

1. iPad `TabView` 默认 `.automatic` style = **page-style**(不是 tab bar)
2. `swipeLeft` 切 tab **不可靠** + 会触发 Pocket tab 内 Daily Pull 卡片
3. `app.alerts` 抓不到 iOS **系统通知权限弹窗**(只能抓 app 内 alert)
4. `app.tap()` 点屏幕中心会 hit 各种 app UI(Daily Pull / NavigationLink)
5. `addUIInterruptionMonitor` **必须在 setUp() 注册**,且需 user gesture 触发

---

## ✅ 解决方案:5 步

### Step 1: ContentView 读 launch env 决定初始 tab **[M]** (iOS 项目源, 在 Mac mini `~/Desktop/ios-VitaMind/`)

```swift
// Sources/App/ContentView.swift
struct ContentView: View {
    @State private var selectedTab: Int = {
        let raw = ProcessInfo.processInfo.environment["VITA_INITIAL_TAB"] ?? "0"
        return Int(raw) ?? 0
    }()
    // ...
}
```

> **不污染产品代码**:env var 不存在时默认 0,App Store 用户完全感知不到。

### Step 2: UI test 注册 interruption monitor(在 setUp) **[M]**

```swift
// UITests/AppStoreScreenshotIPadTests.swift
override func setUp() {
    super.setUp()
    continueAfterFailure = false

    // ⚠️ 必须在 setUp 注册,不在 test method 里
    addUIInterruptionMonitor(withDescription: "Notification Permission") { alert in
        if alert.buttons["Allow"].exists {
            alert.buttons["Allow"].tap()
            return true
        }
        return false
    }
}
```

### Step 3: 每个 tab 独立启动 App(不用 swipe) **[M]**

```swift
func testCaptureAllTabsIPad() throws {
    let outDir = "<OUT_DIR>"
    let tabs: [(index: Int, label: String, file: String)] = [
        (0, "Pocket",     "ipad_tab1.png"),
        (1, "Habits",     "ipad_tab2.png"),
        (2, "Coach",      "ipad_tab3.png"),
        (3, "Collection", "ipad_tab4.png"),
        (4, "Settings",   "ipad_tab5_settings.png"),
    ]

    for tab in tabs {
        let app = XCUIApplication()
        app.launchArguments += ["--uitesting"]
        app.launchEnvironment = ["VITA_INITIAL_TAB": String(tab.index)]

        app.launch()
        sleep(2)

        // 角落 tap 触发 interruption monitor(避开 app UI)
        let window = app.windows.firstMatch
        let topLeft = window.coordinate(withNormalizedOffset: CGVector(dx: 0.01, dy: 0.01))
        topLeft.tap()
        sleep(2)

        // 截图
        let path = "\(outDir)/\(tab.file)"
        try? app.screenshot().pngRepresentation.write(to: URL(fileURLWithPath: path))
        print("📸 \(tab.label) → \(path)")

        app.terminate()
    }
}
```

> **为什么角落 tap**:interruption monitor 需要 user gesture 才能触发,但屏幕中心会 hit app UI(Daily Pull 按钮 / NavigationLink row)。屏幕左上 1% 永远不会有控件。

### Step 4: 跑测试(Release config) **[M]** (Mac mini 跑 xcodebuild, ssh-macmini-screenshot.sh 触发)

```bash
xcodebuild test -project YourApp.xcodeproj -scheme YourApp \
  -configuration Release \
  -destination "platform=iOS Simulator,id=<IPAD_DEVICE_UUID>" \
  -only-testing:<YourUITests>/<YourScreenshotTestClass>
```

> **必须 Release config**:Debug vs Release 在没有 `#if DEBUG` 的代码下渲染一致,但用 Release 更接近最终 archive build。

### Step 5: 验证截图 **[M]** (Mac mini 上 ~/Desktop/.../AppStore/Screenshots/ 检查)

```bash
# 查尺寸
sips -g pixelWidth -g pixelHeight AppStore/Screenshots/iPad*/ipad_tab1.png
# → 期望: pixelWidth=2048 pixelHeight=2732 (iPad Pro 13" M4 @2x)

# 找 iPad Pro 13" M4 UUID
xcrun simctl list devices | grep "iPad Pro 13-inch (M4)" | head -1
```

---

## 🐛 5 个常见症状 → 一句话诊断

| 症状 | 原因 | 修复 |
|---|---|---|
| 5 张截图都是同一个 tab | swipeLeft 不可靠,被 in-tab gesture 拦截 | 改用 VITA_INITIAL_TAB 多次独立启动 |
| 截图里有"NEW CARD!" 抽卡弹窗 | `app.tap()` 击中 Daily Pull 按钮 | 用 `coordinate(normalizedOffset: 0.01, 0.01)` 角落 tap |
| 截图是 Settings 但显示 Google provider 子页 | iPad page-style + List 第一个 NavigationLink 被 auto-push | 让 Settings 启动时 selectedTab=4,避免先经过 0-3 触发 push |
| 通知弹窗挡住 tab 内容 | `app.alerts` 抓不到 system alert | `addUIInterruptionMonitor` + 角落 tap 触发 |
| Tab 切换到一半卡死 | `swipeLeft` swipeLeft 触发 Pocket tab 内的 Pull 抽卡 | 彻底放弃 swipe,改用 env var 启动 |

---

## 🔗 完整可复制模板

```swift
// UITests/<YourIPadScreenshotTests>.swift
import XCTest

final class <YourIPadScreenshotTests>: XCTestCase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        addUIInterruptionMonitor(withDescription: "Notification Permission") { alert in
            if alert.buttons["Allow"].exists {
                alert.buttons["Allow"].tap()
                return true
            }
            return false
        }
    }

    func testCaptureAllTabs() throws {
        let outDir = "<OUTPUT_DIR>"
        let tabs: [(index: Int, label: String, file: String)] = [
            (0, "<Tab1>", "<tab1>.png"),
            (1, "<Tab2>", "<tab2>.png"),
            (2, "<Tab3>", "<tab3>.png"),
            (3, "<Tab4>", "<tab4>.png"),
            (4, "<Tab5>", "<tab5>.png"),
        ]

        for tab in tabs {
            let app = XCUIApplication()
            app.launchArguments += ["--uitesting"]
            app.launchEnvironment = ["VITA_INITIAL_TAB": String(tab.index)]

            app.launch()
            sleep(2)

            let window = app.windows.firstMatch
            let topLeft = window.coordinate(withNormalizedOffset: CGVector(dx: 0.01, dy: 0.01))
            topLeft.tap()
            sleep(2)

            let path = "\(outDir)/\(tab.file)"
            try? app.screenshot().pngRepresentation.write(to: URL(fileURLWithPath: path))
            print("📸 \(tab.label) → \(path)")

            app.terminate()
        }
    }
}
```

---

## 📐 iPad 截图规格速查

| 设备 | 物理像素 (px) | 比例 |
|---|---|---|
| iPad Pro 13" (M4 / M5) | 2048 × 2732 | 3:4 |
| iPad Pro 11" (M4 / M5) | 1668 × 2388 | 3:4 |
| iPad Air 13" (M4) | 2048 × 2732 | 3:4 |
| iPad Air 11" (M4) | 1668 × 2388 | 3:4 |
| iPad mini (A17 Pro) | 1488 × 2266 | 3:4 |
| iPad (A16) | 1640 × 2360 | 3:4 |

> App Store 接受任意 iPad 尺寸,**推荐用 12.9" 或 13"**(最大尺寸,覆盖更多用户群)。

---

## 🧪 跑前 checklist

- [ ] ContentView 加了 `VITA_INITIAL_TAB` env var 读取
- [ ] UI test 的 setUp 注册了 `addUIInterruptionMonitor`
- [ ] UI test 用 launch env 多次独立启动,不用 swipe
- [ ] 跑测试前 `xcrun simctl erase <device>` 干净状态
- [ ] 截完查 `sips -g pixelWidth` 确认是 2048×2732
- [ ] 截完查 `sips` 输出 PNG 字节数 < 1.5 MB(如果有 PNG > 2MB 说明有无关层)
- [ ] `xcodegen generate`(如果改了 project.yml)
- [ ] 测试用 `-configuration Release`(与 archive 一致)

---

## 🔗 相关引用

- **SOP 详细原理**:`docs/SOP-iOS-Local-Development.md` §8.17
- **HR/SC 规则**:SOP §8.17.5(HR-59/60 + SC-45/46)
- **VitaMindGo 实战 commit** (历史, 仓库名是重命名后的):
  - [`385e112`](https://github.com/lauer3912/ios-VitaMindGo/commit/385e112) — first iPad screenshot setup
  - [`66ae11a`](https://github.com/lauer3912/ios-VitaMindGo/commit/66ae11a) — re-capture with Release config
  - [`b55d246`](https://github.com/lauer3912/ios-VitaMindGo/commit/b55d246) — submission check-list
- **示例截图产物**:`~/Desktop/ios-VitaMind/AppStore/Screenshots/iPadPro13inchM4_2048x2732/`

---

## 📅 维护记录

| 日期 | 变更 |
|------|------|
| 2026-06-03 | 首次创建,从 VitaPocket 2026-06-03 实战经验沉淀 |
