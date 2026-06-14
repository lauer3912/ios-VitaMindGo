# VitaMindGo v3.1.0 — App Store Connect 订阅配置文档

> **给佛罗多老爷的保姆级手把手教程**
> 
> 写于 2026-06-12,Katherine 亲手整理。
> 这份文档是给"完全没碰过 App Store Connect 订阅后台"的人看的。每一步都告诉你点哪里、填什么、完了之后长什么样。

---

## 📋 你要做的事(一句话)

在 App Store Connect (后面简称 ASC) 后台,**创建 1 个订阅组 + 2 个产品 + 给月付加 7 天免费试用**。
完成后,App 才能让用户买订阅。

---

## ⏱️ 预计耗时

**15-25 分钟**(第一次操作,加上页面加载)

---

## 🎯 关键事实(读一遍再开始)

| 项 | 值 | 备注 |
|----|----|------|
| **产品 1 ID** | `vitamind_pro_monthly` | ⚠️ 必须**逐字**打对,代码里硬编码 |
| **产品 2 ID** | `vitamind_pro_yearly` | ⚠️ 同上 |
| **产品 1 价格** | $4.99 / 月 |  |
| **产品 2 价格** | $39.99 / 年 |  |
| **产品 1 试用** | 7 天免费 | **只有月付有试用**,年付**没有** |
| **产品 2 试用** | ❌ 无 |  |
| **订阅组名** | VitaMindGo Pro | 内部参考名 |
| **App 名称** | VitaMindGo | 找这个,别找 VitaMind |
| **App ID** | 6774840392 |  |
| **Bundle ID** | com.ggsheng.VitaMind |  |
| **Team ID** | 9L6N2ZF26B |  |

---

## 🚪 入口:打开 ASC

1. 打开浏览器(Safari 或 Chrome 都行)
2. 访问 **https://appstoreconnect.apple.com**
3. 用你的 **Apple ID** 登录(就是你的开发者账号,9L6N2ZF26B 那个 Team 的 owner 或 admin 权限)

> 💡 **登录不上去?** 找你 Team 的 Admin 加权限,需要 "App Manager" 或 "Admin" 角色。

---

## 📍 Step 0:进入 VitaMindGo 的订阅管理页

登录后你会看到 ASC 首页。跟着下面 5 步点:

| 步骤 | 操作 | 你应该看到 |
|------|------|-----------|
| 0.1 | 点顶部 **"我的 App"** (My Apps) | App 列表 |
| 0.2 | 在列表里找 **"VitaMindGo"**(注意不是 VitaMind,不是 VitaPocket)| App 详情页 |
| 0.3 | 看左侧或顶部标签栏,找 **"订阅"** (Subscriptions) | 订阅管理界面 |
| 0.4 | 如果提示"尚未配置订阅",正常,继续 |  |
| 0.5 | 如果你已经看到 "VitaMindGo Pro" 这个组,说明**已经创建过**了,跳到 Step 3 |  |

> 🔍 **找不到 "订阅" 标签?**
> - 老版 ASC:左侧栏 → "功能" (Features) → "订阅"
> - 新版 ASC:左侧栏 → "盈利" (Monetization) → "订阅"
> - **重点**:别进 "App 内购买项目" (In-App Purchases),那是消耗型/非消耗型产品,不是订阅

---

## 📦 Step 1:创建订阅组 (Subscription Group)

订阅组 = 放订阅产品的"文件夹"。一个 App 可以有多个组,但 VitaMindGo 只需要 1 个。

### 1.1 找到 "Manage" 按钮

在订阅页面,你会看到:

```
订阅组 (Subscription Groups)
[ + 创建新订阅组 ]  或  [ Manage ]  ← 点这个
```

> 不同 ASC 版本按钮长得不一样,可能叫 "+"、叫 "Create Group"、叫 "Manage" 都点进去。

### 1.2 填写订阅组信息

| 字段 | 填什么 | 说明 |
|------|--------|------|
| **参考名称 (Reference Name)** | `VitaMindGo Pro` | 内部名,**只有你/Apple 看到** |
| **App Store 显示名 (Display Name)** | `VitaMindGo Pro` | 用户在订阅管理看到的名字(2024+ ASC 才有的字段,如果看不到就跳过)|

### 1.3 点 "存储" / "Create" / "Save"

成功后你会跳到组详情页,里面是空的(还没产品)。

> ✅ **检查点 1**:你应该看到标题 "VitaMindGo Pro",里面说"0 个订阅"或 "No subscriptions yet"。
> 
> ❌ 报错 "Name already exists"?换个名字试试(加个 "v1" 后缀),但要同步告诉我。

---

## 🌙 Step 2:创建第一个产品 — 月付 (Monthly)

回到订阅组详情页,你会看到空的订阅列表。开始加月付产品。

### 2.1 点 "+" 或 "Create Subscription"

### 2.2 第一屏:基本信息

| 字段 | 填什么 | ⚠️ 注意 |
|------|--------|----------|
| **参考名称 (Reference Name)** | `VitaMindGo Pro Monthly` | 内部名,你以后在 ASC 列表里认它用 |
| **产品 ID (Product ID)** | `vitamind_pro_monthly` | 🔴 **这一步最容易错!复制粘贴下面这串,别手打:**<br><br>`vitamind_pro_monthly`<br><br>不能有空格,不能大写,不能有中文,不能漏下划线 |

### 2.3 第二屏:订阅时长

| 字段 | 填什么 |
|------|--------|
| **订阅时长 (Subscription Duration)** | `1 Month` (从下拉选) |

> ⚠️ 选 "1 Month" **不是** "1 Year",**不是** "1 Week"。

### 2.4 第三屏:订阅价格

| 字段 | 填什么 |
|------|--------|
| **价格 (Price)** | `4.99` (USD) |

ASC 会自动选对应价格档。**确认弹出的下拉里是 "$4.99 USD"**。

### 2.5 第四屏:本地化信息 (Localization)

| 字段 | 填什么 |
|------|--------|
| **显示名称 (Display Name)** | `VitaMindGo Pro Monthly` |
| **描述 (Description)** | `Unlock unlimited AI Coach, advanced insights, and exclusive card themes.` |

> 💡 **只填 en-US 就行**(就是默认那个美国英语),其他语言以后再加。**不要**为图省事啥都不填,Apple 会卡审。

### 2.6 第五屏:审核信息 (Review Information)

| 字段 | 填什么 |
|------|--------|
| **截图 (Screenshot)** | **(可选,先跳过)** 如果你手边有 paywall 的截图可以传,没有就空着,后面补 |

### 2.7 点 "Create" / "保存"

成功后跳到产品详情页。

> ✅ **检查点 2**:产品详情页应该看到:
> - 标题: VitaMindGo Pro Monthly
> - Product ID: vitamind_pro_monthly
> - 价格: $4.99 / 1 month
> 
> ❌ 如果显示的是 "$0.00 / 1 month",说明 Step 2.4 价格没保存成功,**回头重设**。

---

## ☀️ Step 3:创建第二个产品 — 年付 (Yearly)

回到订阅组详情页(**VitaMindGo Pro** 组),重复 Step 2,字段不同:

| 字段 | 填什么 | 区别说明 |
|------|--------|----------|
| **参考名称** | `VitaMindGo Pro Yearly` | |
| **产品 ID** | `vitamind_pro_yearly` | 🔴 **复制粘贴,别手打:**<br><br>`vitamind_pro_yearly` |
| **订阅时长** | `1 Year` | **不是** 1 Month |
| **价格** | `39.99` (USD) | |
| **显示名称** | `VitaMindGo Pro Yearly` | |
| **描述** | `Unlock unlimited AI Coach, advanced insights, and exclusive card themes. Save 33% vs monthly.` | 多了一句 "Save 33% vs monthly" |

> ✅ **检查点 3**:订阅组里现在应该**有 2 个产品**:
> 1. VitaMindGo Pro Monthly - $4.99/mo
> 2. VitaMindGo Pro Yearly - $39.99/yr

---

## 🎁 Step 4:给月付加 7 天免费试用 (Introductory Offer)

> ⚠️ **只给月付加试用**。年付不试用(代码里就是这么设计的,跟 Apple 商业惯例一致:年付买的就是"省 33%",不再叠免试用)。

### 4.1 进入月付产品详情

在订阅组里点 **VitaMindGo Pro Monthly**,打开它的详情。

### 4.2 找到 "订阅价格" 区块

往下滚,找 **"Subscription Prices"** 区域。
你会看到当前价格 `$4.99`。
旁边或下面有 **"Add Introductory Offer"** 按钮,点它。

### 4.3 填写试用信息

| 字段 | 填什么 | ⚠️ |
|------|--------|----|
| **类型 (Type)** | `Free Trial` (从下拉选) | 不是 Pay As You Go,不是 Pay Up Front |
| **时长 (Duration)** | `1 Week` | **不是** 1 Day,**不是** 1 Month,**不是** 7 Days(没有 7 Days 这个选项,选 1 Week = 7 天)|
| **国家/地区 (Countries)** | 选 **"所有国家/地区"** (All Countries) | 默认就行,个别国家以后再说 |

### 4.4 点 "保存" / "Add"

成功后会看到 "$4.99 / 1 month" 旁边多了一行 **"$0.00 / 1 week (Introductory)"**。

> ✅ **检查点 4**:月付产品页面,价格区域应该看到:
> ```
> Subscription Price
>   $4.99 / 1 month
>   $0.00 / 1 week (Introductory)   ← 刚加的
> ```

---

## 🔍 Step 5:验证清单 (做完一起检查)

回到订阅组 **VitaMindGo Pro** 详情页,确认:

| # | 检查项 | 期望 | ✓/✗ |
|---|--------|------|-----|
| 1 | 订阅组存在 | 看到 "VitaMindGo Pro" 标题 | |
| 2 | 月付产品 | VitaMindGo Pro Monthly | |
| 3 | 月付 Product ID | `vitamind_pro_monthly` | |
| 4 | 月付价格 | $4.99 USD | |
| 5 | 月付试用 | "$0.00 / 1 week (Introductory)" | |
| 6 | 年付产品 | VitaMindGo Pro Yearly | |
| 7 | 年付 Product ID | `vitamind_pro_yearly` | |
| 8 | 年付价格 | $39.99 USD | |
| 9 | 年付试用 | ❌ 不应该有试用 | |
| 10 | 状态 | 2 个产品都是 "Ready to Submit" 或类似绿色状态(不是黄色 "Missing Metadata" 警告) | |

---

## 📸 Step 6:截图给我(强制!)

做完后,**用手机或 Cmd+Shift+4 截 4 张图**,发给我:

1. 订阅组列表页(看到 2 个产品)
2. 月付产品详情页(看到价格 + 试用)
3. 年付产品详情页(看到价格,**无试用**)
4. 订阅组顶部信息(看到 Group ID)

> 为什么:Apple 后台有 Bug,有时产品看着对但实际是 "Missing Metadata" 状态。截图我好一眼看出问题。

---

## 📨 Step 7:发完截图后,接下来发生什么

| 阶段 | 谁做 | 干什么 |
|------|------|--------|
| 1 | 老爷(已完成) | ASC 后台配 2 个产品 + 1 个试用 |
| 2 | **Katherine(我做)** | 验证 Product ID 跟代码匹配 + 拉取产品看价格正确 |
| 3 | Katherine | Xcode 加 In-App Purchase capability |
| 4 | Katherine | 跑 sandbox 测试(用自己的 Apple ID 当测试用户)|
| 5 | Katherine | 截图 + 提审 v3.1.0 |

预计 2-3 天。

---

## ❓ 常见问题 (FAQ)

### Q1: 找不到 "Subscriptions" 标签
**A:** 试这 3 个入口:
- 左侧 → "功能" (Features) → "订阅"
- 左侧 → "盈利" (Monetization) → "订阅"
- App 详情页 → 顶部 tab → "订阅"

如果都没有,说明你的 Apple ID 没 "App Manager" 权限,**找 Team Admin 加权限**。

### Q2: 创建时提示 "Product ID already exists"
**A:** 你之前建过同名产品。在订阅组里搜 `vitamind_pro_monthly`,如果找到了,**不要新建**,告诉我**用现有的还是先删后建**。

### Q3: 月付创建了,但找不到 "Add Introductory Offer" 按钮
**A:** 可能产品状态是 "Missing Metadata"。先把:
- 本地化信息(显示名 + 描述)**填完整**(en-US 必须有)
- 审核信息(截图)可以**先空着**
然后按钮就会出来。

### Q4: 试用时长选 "1 Week" 还是 "7 Days"?
**A:** 选 **"1 Week"**。Apple 系统里没有 "7 Days" 选项,1 Week = 7 天,跟代码里 `P1W` 匹配。

### Q5: 选了 "Pay As You Go" 试用了 1 周,还能改吗?
**A:** 能。进产品详情 → Subscription Prices → 点已有的试用 → Edit / Delete 重来。

### Q6: 年付要不要也加 7 天试用?
**A:** **不加**。代码里只给月付加了试用(看 `SubscriptionManager.swift` 第 18-19 行注释)。年付卖点是"省 33%",**商业上不叠试用**。

### Q7: 浏览器一直转圈 / 报错
**A:**
- Safari 试试(Apple 官方支持最好)
- 关 VPN
- 无痕模式(Cmd+Shift+N)登录
- 还是不行就换电脑

### Q8: 创建完了但 App 里买订阅还是 "找不到产品"
**A:** 95% 是 **Product ID 打错了**。回 ASC 对照:
- `vitamind_pro_monthly` ←→ `vitamind_pro_yearly`
- 注意下划线位置、字母大小写

**给我截图我看一眼**。

### Q9: ASC 显示 "Waiting for Review" 状态
**A:** 创建完是正常状态,不用审。Apple 内部审核是 **1-48 小时**,**会自动过**。

---

## 🔒 关键 Product ID 速查(收藏这一节)

> 复制粘贴时反复对照下面这 2 行,**错一个字符 = 整个订阅功能废**。

```
vitamind_pro_monthly    ← 月付    $4.99/月    7 天试用
vitamind_pro_yearly     ← 年付    $39.99/年   无试用
```

验证方法(对每个 ID 检查 3 件事):
1. ✅ 全部小写
2. ✅ 只有 1 个下划线(在 `pro` 和 `monthly`/`yearly` 之间)
3. ✅ 没有空格、连字符、点

---

## 📞 卡住了?

直接 QQ 跟我说:
- "Step X 找不到按钮" → 我截图给你看/写更细的指引
- "Product ID 提示已存在" → 我帮你查 ASC
- "试用按钮不出现" → 我教你填缺哪些字段

---

**文档版本:** v1.0 (2026-06-12)
**作者:** Katherine Johnson
**适用项目:** VitaMindGo v3.1.0 IAP
**对应代码:** `Sources/Core/Subscription/SubscriptionManager.swift:18-19`
**对应 Plan:** `docs/v3.1.0-IAP-Plan.md` §4
