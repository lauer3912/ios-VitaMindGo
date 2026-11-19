# App Store 提交清单 · VitaMindGo 3.2.1 (build 18)

> 生成于 2026-11-19。API 侧已全部做完；下面 3 段**必须在 ASC 网页后台点**（Apple 不开放对应 API）。
> 提审草稿：reviewSubmission `7cda6fbf-d045-4660-81cb-907333d4a402`（空壳，网页操作时会复用/重建）。

## ✅ API 侧已完成（无需再动）

| 项 | 状态 |
|---|---|
| 版本记录 3.2.1 | `041d1d66-3754-40ed-b764-ffa6efbc8951`，`PREPARE_FOR_SUBMISSION` |
| 挂 build 18 | ✅（付费墙试用文案修复版，Delivery UUID `3e8d5297-e217-4495-a1d4-b8307fb58e05`） |
| 描述 | 3563 字，末尾含 **EULA + App 隐私政策 + 平台隐私声明**；已删掉不存在的「7 天免费试用」承诺 |
| keywords / promotionalText / What's New | ✅ |
| 截图 | iPhone 6.7" 5 张 + iPad 13" 5 张（COMPLETE） |
| 审核联系人 | ZhiFeng Sun / +8615050228829 / support@techidaily.com，`demoAccountRequired=false`，标准审核备注已填 |
| 分类 | Health & Fitness（主）+ Medical（次） |
| 订阅组本地化 | ✅ `VitaMindGo Pro`（此前缺失导致两个订阅都 Missing Metadata） |
| 月付订阅 | ✅ 状态已从 MISSING_METADATA → **READY_TO_SUBMIT** |
| 付费墙试用文案 | ✅ 改为跟随 StoreKit 实际 introductory offer，没有试用就不承诺试用（build 18） |

---

## ❶ 年付订阅定价（$39.99 USA）

后台现有那条排定价的 territory 是 `US`（非法值），不是 `USA`，所以年付一直 Missing Metadata。

1. ASC → VitaMindGo Pro → 订阅组 **VitaMindGo Pro** → **VitaMindGo Pro Yearly**
2. **Subscription Prices** → 右上 **[+]** → 基础国家 **USA** → 价格 **$39.99** → Save
   - 若列表里已有那条 `US` 的记录，先删掉它（只保留 USA 这条）
3. 回到该订阅页，状态应变为 **Ready to Submit**

## ❷ 终身买断 `vitamind_pro_lifetime2`（$79.99）

当前状态 `CREATED`（本地化 / 价格 / 审核截图全缺）。App 的付费墙确实在展示这个商品，
按 Guideline 2.1(b) 必须随版本一起提交，否则会被拒。

1. ASC → VitaMindGo Pro → **In-App Purchases** → **VitaMindGo Pro Lifetime**
2. **Localization** → 右上 **[+]** → `en-US`
   - Name: `VitaMindGo Pro Lifetime`
   - Description: `One-time purchase. Unlock unlimited AI Coach messages, advanced insights, exclusive card themes and Apple Watch complications. Never expires.`
3. **Pricing** → 右上 **[+]** → **USA** → **$79.99** → Save
4. **App Review Information → Screenshot** → 上传
   `AppStore/Screenshots/paywall_1290x2796/paywall_lifetime2_1290x2796.png`（1290×2796，符合要求）
5. 状态应变为 **Ready to Submit**

## ❸ 把内购勾进本次审核 + 提交

> Apple 不允许用 API 给 reviewSubmission 挂 subscription / inAppPurchase item
> （`reviewSubmissionItems` 上没有 `subscription` 关系），必须网页勾选。
> 仓库 SOP `docs/SOP-iOS-Local-Development.md` §7.5 记的「失职 #23 连拒」就是这个坑。

1. 左栏选版本 **3.2.1** → 找到 **In-App Purchases / Manage**
2. 勾选三项：
   - VitaMindGo Pro Monthly（`vitamind_pro_monthly_v2`）
   - VitaMindGo Pro Yearly（`vitamind_pro_yearly`）
   - VitaMindGo Pro Lifetime（`vitamind_pro_lifetime2`）
3. 顶部 **添加以供审核** → 核对「准备提交项目」数量应为 **5**
   （App 版本 3.2.1 + 订阅组 VitaMindGo Pro + 三个商品）；数量不对就别提交
4. **提交以供审核** → 状态变 `Waiting for Review`

## 提交后我来复核

告诉我就行，我会用 API 核：
- `GET /v1/apps/6774840392?include=appStoreVersions` → `appVersionState` 是否 `WAITING_FOR_REVIEW`
- `GET /v1/apps/6774840392/reviewSubmissions` → 提交项数量与类型
- 三个商品 `state` 是否都为 `READY_TO_SUBMIT` / `APPROVED`

## 备查

- App ID `6774840392`，bundleId `com.ggsheng.VitaMind`，Team `9L6N2ZF26B`
- 内部测试组 `fd612751-27be-4f9c-99bc-cd6518ea5428`（internal=true），build 17/18 都在组内
- 隐私政策 `https://lauer3912.github.io/ios-VitaMindGo/PrivacyPolicy.html`；平台隐私 `https://techidaily.com/privacy`
- 本次版本新增能力：AI 教练默认走 credits.techidaily.com 的**设备维度免费额度**（每台终端各自一份，
  平台代理、不下发上游 Key），Key 被平台轮换时 App 自动重取并重试
