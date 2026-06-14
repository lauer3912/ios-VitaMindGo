# HEARTBEAT Tasks

# Keep this file empty (or with only comments) to skip heartbeat API calls.
# Add tasks below when you want the agent to check something periodically.

## 🔄 Periodic Checks

### VitaMindGo 上架监控 (Stage 10, 2026-06-10 19:53 北京时间发布)

**状态**: ✅ **v3.0.0 build 11 已上架销售**
- iTunes 验证: `https://itunes.apple.com/lookup?id=6774840392` → resultCount=1, version=3.0.0, price=0.0 USD, userRatingCount=0
- 公开 URL: https://apps.apple.com/us/app/vitamindgo/id6774840392

**已停掉的监控** (审核已结束, 不再需要):
- ❌ OpenClaw cron `09e10484` (每 4h 查审核 state) — 2026-06-11 20:35 disable
  - 原因: build 11 已上架, state 永远是 APPROVED, 4h 跑一次纯浪费
  - 备份: state file 在 `~/.openclaw/workspace/.cache/vitamindgo-review-state` (最后值: APPROVED)
- ❌ macOS launchd plist `com.openclaw.vitamindgo-review` (每 2h)
  - 操作: `launchctl unload ~/Library/LaunchAgents/com.openclaw.vitamindgo-review.plist`

**新监控 (上架后, 暂未启用, 等老爷拍板)**:
- 📊 **上架数据监控** (评分/版本/价格) — ✅ **2026-06-11 20:38 启用, cron `e2e1aa9c` 每天 12:00 跑**
  - 脚本: `scripts/check-vitamindgo-sales.sh`
  - 状态: 跑 iTunes Lookup API, 跟 state file 比对, 变了才通知
  - 覆盖: userRatingCount / averageUserRating / version / price / releaseDate
- 🐛 崩溃监控 (App Store Connect / Xcode Organizer Crashes) — 建议每 24h 查
- 💰 销量/收入 (Sales and Trends) — 建议每 24h 查 (需要 ASC API + JWT)

**手动查 (老爷任何时候想看)**:
```bash
# iTunes Lookup (公开, 无需 auth)
curl -fsSL "https://itunes.apple.com/lookup?id=6774840392&country=us" | python3 -m json.tool | head -30

# ASC API (需要 JWT, 详细用法见 MEMORY.md)
bash ~/.openclaw/workspace/scripts/asc-api-query.sh version-state 6774840392
```

### Cron 健康 (避免 7-day 静默失败重演)
- **每 12 小时**跑 `openclaw cron list` 看 `lastStatus` + `consecutiveErrors`
- 任何 job 连续 error ≥ 4 → 主动 ping 老爷 (failure-alert 阈值 2026-06-06 调到 4)
- 重点 jobs:
  - 8:00 早报 (2e627e59) - last ok ✅
  - dreaming-noon (cfb1d093) - last ok ✅
  - dreaming-3am (91ac3031) - last ok ✅
  - ~~VitaMindGo 审核检查 (09e10484)~~ - **2026-06-11 disable** (审核结束)
  - **VitaMindGo 上架监控 (e2e1aa9c) - 2026-06-11 启用, 每天 12:00 跑**

## 🚨 State

Last check: 2026-06-11 20:40 GMT+8 (VitaMindGo 上架监控 cron 启用 + v3.1.0 IAP 计划)
Next planned: 2026-06-12 08:00 GMT+8 (早报) → 启动 v3.1.0 IAP Phase 1 (Day 1: ASC 后台 + Xcode capability)