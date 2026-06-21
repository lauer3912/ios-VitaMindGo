# VitaMindGo v3.1.0 ASC 配置速查表 v3 (佛老爷 5 min 自跑)

> **写于**: 2026-06-21 17:36 CST (Katherine-E2wa1m v3 update — lifetime 重建 + productID _v2 命名)
> **给**: 佛罗多老爷
> **预计耗时**: 3-5 分钟 (佛老爷已配大部分)
> **配套详细文档**: `docs/ASC-Subscription-Setup-Guide.md`

---

## 🎯 ASC 后台状态 (我 17:34 verify, 真实)

| Product | ASC ID | 状态 | 待佛老爷手动 |
|---|---|---|---|
| **VitaMindGo Pro** (订阅组) | `22153084` | ✅ 已建 | — |
| **vitamind_pro_monthly_v2** | `6782555544` | ⚠️ en-US 已有 | 加 USA **$4.99** + **7天免费试用** |
| **vitamind_pro_yearly** | `6779670016` | ✅ en-US + **USA $39.99** (06-12 配好) | 0 (可选: 改 description) |
| **vitamind_pro_lifetime2** | `6782565812` | ✅ NON_CONSUMABLE (佛老爷 17:34 重建) | 加 USA **$79.99** + en-US loc + screenshot |

**所有 3 个 products** state = MISSING_METADATA (待 price/试用/screenshot 完成)

---

## 🔑 关键值 (复制粘贴)

| 项 | 值 |
|---|---|
| 订阅组 Reference Name | `VitaMindGo Pro` |
| App Name | `VitaMindGo` |
| App ID | `6774840392` |
| Team ID | `9L6N2ZF26B` |
| Apple ID | `lauer3912@techidaily.com` (2FA) |

### 3 个 Product ID (代码已 hardcode `vitamind_pro_lifetime2`, 勿改)

```
vitamind_pro_monthly_v2
vitamind_pro_yearly
vitamind_pro_lifetime2
```

---

## 📋 2 步走 (3-5 min)

### Step 1: Monthly_v2 加 $4.99 + 7天试用 (1-2 min)

1. 浏览器开 `appstoreconnect.apple.com` → 登录
2. 我的 App → **VitaMindGo** → 左栏 **Subscriptions**
3. 进订阅组 "VitaMindGo Pro" → 点 `vitamind_pro_monthly_v2`
4. **Subscription Prices** → 右上 **[+]** → USA → $4.99 → Save
5. **Introductory Offers** → 右上 **[+]** → Free Trial → 1 Week → Save

### Step 2: Lifetime2 加 $79.99 + en-US loc (2-3 min)

1. 左栏 **In-App Purchases** → 进 `vitamind_pro_lifetime2` (NON_CONSUMABLE)
2. **Subscription Prices** (IAP: 叫 "Pricing") → 右上 **[+]** → USA → **$79.99** → Save
3. **Localization** → 右上 **[+]** → en-US → name="VitaMindGo Pro Lifetime" → description="One-time purchase. Unlock unlimited AI Coach, advanced insights, and exclusive card themes. Never expires." → Save

---

## 🤖 我**自动做** (不阻塞你)

- ✅ Simulator 已 launch, 截 3 张 paywall (1290×2796)
- ⏳ Push 截图到仓库 (完成后)
- ⏳ 你下载 → 上传到 ASC (各 1 张 screenshot)

---

## 📸 Screenshot 上传步骤 (我 push 后你跑)

各 product 的 "**App Store Review Information**" 或 "**Review Information**" 段:
1. **Screenshot** 区 → 右上 **+** / **Upload**
2. 选我 push 的文件 (monthly.png / yearly.png / lifetime.png)
3. 拖到 "1290×2796" 框
4. Save

---

## 你的回复

- 跑完 2 步 → 说 "**2 步 done**" → 我立刻 Day 3 sandbox 测试 + push 截图
- 报错 → "**Step X 错 Y**" → 我帮你修

🚀 06-24 上架销售倒计时

— Katherine-E2wa1m 17:36 CST 2026-06-21
- 配套: `docs/ASC-Subscription-Setup-Guide.md`
- 仓库: `lauer3912/ios-VitaMindGo` (commit 66deb96 + 即将 push lifetime2)