# VitaMindGo v3.1.0 ASC 配置速查表 v2 (佛老爷 5-10 min 自跑)

> **写于**: 2026-06-21 16:18 CST (Katherine-E2wa1m v2 update — 包含 lifetime 修复)
> **给**: 佛罗多老爷
> **预计耗时**: 5-10 分钟 (大部分 ASC 后台已配好, 只需补 3 项)
> **配套详细文档**: `docs/ASC-Subscription-Setup-Guide.md`

---

## 🎯 当前 ASC 后台状态 (我 16:18 verify)

| Product | ASC ID | 状态 | 待佛老爷手动 |
|---|---|---|---|
| **VitaMindGo Pro** (订阅组) | `22153084` | ✅ 已建 | — |
| **vitamind_pro_monthly_v2** | `6782555544` | ⚠️ 已建 + en-US localization | 加 USD $4.99 + 7天免费试用 |
| **vitamind_pro_yearly** | `6779670016` | ⚠️ 已建 + en-US localization | 加 USD $39.99 |
| **vitamind_pro_lifetime** | `6781707857` | ⚠️ type=**CONSUMABLE** 应改 **NON_CONSUMABLE** | 删 CONSUMABLE + 重建 NON_CONSUMABLE $79.99 |

**所有 3 个 products** state = MISSING_METADATA (需价格/试用/截图完成)

---

## 🔑 关键值 (复制粘贴)

| 项 | 值 |
|---|---|
| 订阅组 Reference Name | `VitaMindGo Pro` |
| App Name | `VitaMindGo` |
| App ID | `6774840392` |
| Team ID | `9L6N2ZF26B` |
| Apple ID | `lauer3912@techidaily.com` (2FA) |

### 3 个 Product ID (代码 hardcode, 勿改)

```
vitamind_pro_monthly_v2
vitamind_pro_yearly
vitamind_pro_lifetime
```

---

## 📋 3 步走 (5-10 min)

### Step 1: Lifetime 修复 type (CONSUMABLE → NON_CONSUMABLE)

**最关键** — lifetime IAP 类型错会导致 Apple Guideline 2.1 reject。

1. 浏览器开 `https://appstoreconnect.apple.com` → 登录
2. 我的 App → **VitaMindGo** → **In-App Purchases** (左栏 Monetization 下)
3. 找 `vitamind_pro_lifetime` (ref name "VitaMindGo Pro Lifetime")
4. 看能否编辑 type:
   - **能改**: 直接 type 改 NON_CONSUMABLE, name 改 "VitaMindGo Pro Lifetime", productId 保持 `vitamind_pro_lifetime`
   - **不能改 (常见)**: Delete IAP → 新建 → type = NON_CONSUMABLE, name = "VitaMindGo Pro Lifetime", productId = `vitamind_pro_lifetime`
5. 加 price: USD $79.99
6. 加 display name + description

### Step 2: Monthly_v2 加 $4.99 + 7天试用

1. 我的 App → VitaMindGo → **Subscriptions** (左栏 Monetization)
2. 进订阅组 "VitaMindGo Pro" → 找 `vitamind_pro_monthly_v2`
3. **Subscription Prices**: 加 USA $4.99 (或更多 territory)
4. **Introductory Offers**: 加 7天 FREE_TRIAL
5. **Review Information**: 填 subscription screenshot (我下面 Step 4 给你)

### Step 3: Yearly 加 $39.99

1. 同订阅组 → 找 `vitamind_pro_yearly`
2. **Subscription Prices**: 加 USA $39.99
3. 不加 Introductory Offer (correctly, yearly no trial)
4. **Review Information**: 填 subscription screenshot (下面 Step 4)

### Step 4: 上传 Subscription Screenshots (3 张)

我 (Katherine) 用 simulator 跑 App + 截屏生成 3 张 paywall 截图 (1290×2796 px):
- monthly_paywall.png
- yearly_paywall.png
- lifetime_paywall.png

你跑完 Step 1-3 后, 我 push 截图到仓库 → 你下载上传到 ASC。

---

## ⚠️ 关于 `vitamind_pro_monthly_v2` 命名说明

原 `vitamind_pro_monthly` product ID 在我 16:11 permissions probe 误删了, Apple 30-90 天内禁用复用。所以建了 v2 替代。代码 (`SubscriptionManager.swift`) + `VitaMindGo.storekit` + `Listing.md` 已同步更新, 不影响用户 (用户看不到 productID)。

---

## 🚨 出错急救

| 报错 | 解决 |
|------|------|
| "Product ID already taken" | 已被旧 productId 占, 加 `_v2` / `_v3` 后缀 |
| "Type cannot be changed" | Delete + 重建 |
| "Page won't load" | 用 Safari 隐身模式 |

---

## 📞 中断恢复

中途断了告诉我 "Step X 已完成, Y 报错", 我帮你接着配。

---

— Katherine-E2wa1m 16:18 CST 2026-06-21 周日
- 配套详细: `docs/ASC-Subscription-Setup-Guide.md`
- 完整 5 day 上架计划: `docs/v3.1.0-IAP-Plan.md`
- 仓库: `lauer3912/ios-VitaMindGo` (commit da3e9b3 + 即将 push 新代码)
- 月度 v2 productID: `vitamind_pro_monthly_v2` (代码已改)