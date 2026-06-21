# VitaMindGo v3.1.0 ASC 配置速查表 (佛老爷 20 min 自跑)

> **写于**: 2026-06-21 15:48 CST (Katherine-E2wa1m)
> **给**: 佛罗多老爷
> **预计耗时**: 15-25 分钟
> **配套详细文档**: `docs/ASC-Subscription-Setup-Guide.md` (保姆级, 优先看这个)

---

## 🎯 一句话目标

在 App Store Connect 后台创建 **1 个订阅组 + 3 个产品**, 让 App 能让用户买 Pro 订阅。

---

## 🔑 4 个关键值 (直接复制粘贴, 0 修改)

| 项 | 值 | 用在哪 |
|----|----|--------|
| **订阅组 Reference Name** | `VitaMindGo Pro` | Step 1 |
| **App Name (找它)** | `VitaMindGo` | Step 0 |
| **App ID** | `6774840392` | 备注 |
| **Team ID** | `9L6N2ZF26B` | 备注 |

### 3 个 Product ID (逐字打对, 代码硬编码)

```
vitamind_pro_monthly
vitamind_pro_yearly
vitamind_pro_lifetime
```

---

## 📋 6 步走

### Step 0: 打开 ASC
- 浏览器打开 `https://appstoreconnect.apple.com`
- 用 **lauer3912@techidaily.com** Apple ID 登录 (需 2FA)
- 顶部点 **"我的 App"** → 列表找 **"VitaMindGo"** (不是 VitaMind, 也不是 VitaPocket)
- 点进 VitaMindGo 详情页

### Step 1: 找订阅管理入口
- 左栏找 **"订阅" (Subscriptions)** (老版叫 "功能 > 订阅", 新版叫 "盈利 > 订阅")
- **不要进** "App 内购买项目 (In-App Purchases)" — 那个是消耗型, 不是订阅

### Step 2: 创建订阅组 (Subscription Group)
- 点 **"+"** 或 **"Create Group"** / **"Manage"**
- **Reference Name**: `VitaMindGo Pro` (粘贴)
- **App Store Display Name**: `VitaMindGo Pro` (粘贴)
- 点 **Save / Create**

> ✅ 检查: 看到 "VitaMindGo Pro" 标题, "0 subscriptions yet"

### Step 3: 创建 Product 1 — Monthly ($4.99/月 + 7天试用)
- 进订阅组 → 点 **"+"** / **"Create Subscription"**
- **Reference Name**: `VitaMindGo Pro Monthly`
- **Product ID**: `vitamind_pro_monthly` (粘贴, ⚠️ 别手打)
- **Subscription Duration**: `1 Month`
- **Subscription Price**: `$4.99` (USD)
- **Display Name**: `VitaMindGo Pro Monthly`
- **Description**: `Unlock unlimited AI Coach, advanced insights, and exclusive card themes.`
- 点 Next / Save

#### ➕ 加 7 天免费试用 (Monthly 专属)
- 进刚创建的 Monthly 产品详情
- 找 **"Subscription Prices"** 或 **"Introductory Offers"** → 点 **"+"** / **"Add Introductory Offer"**
- **Offer Type**: `Free Trial`
- **Duration**: `1 Week` (7 天)
- 点 Confirm / Save

### Step 4: 创建 Product 2 — Yearly ($39.99/年, 无试用)
- 回订阅组 → 点 **"+"** / **"Create Subscription"**
- **Reference Name**: `VitaMindGo Pro Yearly`
- **Product ID**: `vitamind_pro_yearly` (粘贴)
- **Subscription Duration**: `1 Year`
- **Subscription Price**: `$39.99` (USD)
- **Display Name**: `VitaMindGo Pro Yearly`
- **Description**: `Unlock unlimited AI Coach, advanced insights, and exclusive card themes. Save 33% vs monthly.`
- 点 Next / Save (⚠️ 不加 Introductory Offer)

### Step 5: 创建 Product 3 — Lifetime (一次性, $79.99 推荐)
- 回订阅组 → 点 **"+"** / **"Create Subscription"**
- **Reference Name**: `VitaMindGo Pro Lifetime`
- **Product ID**: `vitamind_pro_lifetime` (粘贴)
- **Subscription Duration**: `Non-Renewing` (或类似选项, 如果没有就跳过这步并告诉我)
- **Price**: `$79.99` 推荐 (一次性, 无续费)
- **Display Name**: `VitaMindGo Pro Lifetime`
- **Description**: `Unlock unlimited AI Coach, advanced insights, and exclusive card themes. One-time purchase, never expires.`
- 点 Next / Save

> 💡 **Lifetime 收费建议 $79.99 USD**: 比 2 年 Monthly ($4.99×24=$119.76) 便宜 33%, 跟 Yearly 类似定位

### Step 6: 上传订阅截图 (Apple 要求, 每产品 1 张)
- 进每个产品详情 → 找 **"Subscription Screenshot"** 或 **"Review Information"**
- 截图要求: **6.5" iPhone, 1290×2796 px**, 显示 paywall 界面
- 截图**暂未生成** — 我 (Katherine-E2wa1m) 会在你 ASC 配置完后用 simulator 跑 xcodebuild + 截屏, 然后你上传
- 现在**先不上传截图**, 状态保持 **"Missing Metadata"** 即可, 截图不阻塞订阅创建

---

## ✅ 配置完成后告诉我

完成后请告诉我:
1. ✅ "ASC Subscription Group VitaMindGo Pro 已创建" 
2. ✅ "3 个 products 已建 (monthly + yearly + lifetime)"
3. ✅ "Monthly 7天试用已加"
4. ❓ ASC 后台有没异常报错? (如有, 截图给我)

收到后, 我立刻:
1. 跑 Sandbox 测试 (Step 7)
2. 生成 Paywall 截图给你上传 (Step 6)
3. v3.1.0 build + altool upload + Submit

---

## 🚨 出错急救

| 报错 | 解决 |
|------|------|
| "Name already exists" | 订阅组已建过, 直接进 Step 3 |
| "Product ID already taken" | 旧版本有重复, 加后缀 `-v2` 但告诉我改代码 |
| "You don't have permission" | 需要 "App Manager" 或 "Admin" 角色, 找你 Team Admin 加权限 |
| "Page won't load" | 用 Safari 隐身模式, 清缓存 |
| 找不到 "订阅" 入口 | 老版: "功能 > 订阅", 新版: "盈利 > 订阅" |

---

## 📞 中断恢复

如果中途断了, 跟我说 "ASC 已配到 Step X" 即可, 我帮你接着配。

---

— Katherine-E2wa1m 15:48 CST 2026-06-21 周日
- 配套详细: `docs/ASC-Subscription-Setup-Guide.md`
- 完整 5 day 上架计划: `docs/v3.1.0-IAP-Plan.md`
- 仓库: `lauer3912/ios-VitaMindGo` (commit 22f5307 已 push)