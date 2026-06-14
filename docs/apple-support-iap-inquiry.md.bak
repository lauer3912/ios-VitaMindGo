# Apple App Review 问询邮件 — IAP 审核

> 草稿,2026-06-12,Katherine 起草,老爷亲审亲发
> 状态: **未发**。请复制 → 改 → 亲手发。

---

## 📧 收件人

`appreview@apple.com` (App Review 团队官方邮箱)

**CC:**
- `developer-support@apple.com` (Developer 关系,问题类问询)
- 你自己的 Apple ID 邮箱 (留底)

**主题 (Subject):**
```
VitaMindGo (App ID 6774840392) — IAP submission review inquiry for v3.1.0
```

---

## 📝 邮件正文 (英文,Apple 内部用)

```
Dear App Review Team,

I'm reaching out regarding VitaMindGo (App ID 6774840392) ahead of our v3.1.0 
submission, which will add auto-renewable subscriptions.

App Information:
- App Name: VitaMindGo
- App ID: 6774840392
- Bundle ID: com.ggsheng.VitaMind
- Team ID: 9L6N2ZF26B
- Current Version: 3.0.0 (live since 2026-06-10)
- Planned Version: 3.1.0 (targeting late June 2026)

What we're adding in v3.1.0:
- Auto-renewable subscriptions via StoreKit 2
  - Monthly: $4.99 USD with 7-day free trial
  - Yearly: $39.99 USD (no trial)
- Paywall UI for upsell
- Restore purchases button (App Store guideline 3.1.5 compliance)

Background context for review:
Our v3.0.0 went through 3 rejections under Guideline 1.4.1 (Safety - Physical 
Harm) before approval. We addressed concerns by:
- Adding medical disclaimer (front and center in app)
- Adding citation system for AI Coach responses (sources: CDC, WHO, NIH, Mayo Clinic)
- Adding in-app alert on first launch

All 39 unit tests and 13 UI tests are passing. We've configured the subscription 
products in App Store Connect:
- Subscription Group: VitaMindGo Pro (id: 22153084)
- vitamind_pro_monthly ($4.99, 7-day trial)
- vitamind_pro_yearly ($39.99, no trial)

Questions for the review team:
1. Are there any new Guideline 1.4.1 risks specific to subscription paywall UI 
   (e.g., does the medical disclaimer need to appear on the paywall too)?
2. For our free-tier daily message limit (5/day) before showing paywall — is 
   this acceptable, or do we need to allow all messages free with ads/IAP 
   alternative?
3. Any other concerns for a health/wellness app transitioning to freemium model?

We want to get v3.1.0 right the first time and would appreciate any guidance. 
We are happy to schedule a brief call or async Q&A if that would help.

Thank you for your time.

Best regards,
[Your Name]
VitaMindGo Developer
lauer3912
```

**邮件长度:** ~1600 字符 — 适中,Apple 团队会读

---

## ✉️ 发送方式 (3 选 1)

### 选项 A: 直接发到 `appreview@apple.com` (推荐)
- 优点:直接进 App Review 队列
- 缺点:可能 3-5 天才回
- 适合:**主动问询**场景(我们想要 pre-review guidance)

### 选项 B: 在 App Store Connect 里 "Contact Us"
- 路径:ASC → App → General → Contact Us
- 优点:跟 app 上下文绑定,Apple 能看到你 app 的状态
- 缺点:也是慢
- 适合:跟 Apple 内部 case 关联

### 选项 C: 跟 Apple Developer Relations 团队联系 (如果有 contact)
- 优点:快,可能 1-2 天回
- 缺点:需要有 DR 团队 contact 信息
- 适合:紧急情况

**推荐:** 选项 B(在 ASC 里提交问题),因为会自动关联到你的 App ID case。

---

## ⚠️ 重要提示

1. **不要承诺 Apple 你做不到的事** — 比如"我会加 6 周缓存",做不到就别说
2. **不要撒娇** — Apple 不吃这套,直接说事实
3. **带截图** — 邮件里附 2-3 张 paywall + disclaimer 截图,Apple 团队更易看
4. **不要 CC 一堆人** — CC 太多会拖慢响应
5. **回信** — 收到 Apple 回信 24h 内必须回(态度分)

---

## 📅 推荐发送时间

- **周二-周四 北京时间 14:00-16:00** (Apple 美国早上 23:00-01:00 PDT)
- 避开周一(Apple 周末后慢) 和周五(Apple 周末前不清)
- 提交 v3.1.0 **前 3-5 天** 发,给 Apple 充足时间回

---

## 📊 我建议不要问的问题 (踩坑)

❌ "I want to make sure my app doesn't get rejected"
   → 没用,Apple 不会给你提前批
❌ "Is $4.99 a fair price?"
   → 商业决策 Apple 不管
❌ "Can you review my code?"
   → Apple 不审代码,只审提交版本
❌ "When will my app be reviewed?"
   → SLA 不保证

---

**文档版本:** v1.0 (2026-06-12)
**作者:** Katherine Johnson
**配对后台:** ASC group=22153084, sub_monthly=6779669614, sub_yearly=6779670016
**配对代码:** ios-VitaMindGo 3.1.0 (开发中, 2026-06-23 计划提交)
