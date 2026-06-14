# OpenClaw Marketing & Sales Toolkit

> **Version**: v1.0 (2026-06-14)
> **Audience**: 任何 OpenClaw Agent (Mac mini / Ubuntu / Windows)
> **Goal**: 让所有 agent 都具备 iOS 营销 / 销售监控 / 推广能力, 跨项目复用

---

## 0. 包含什么

| 工具 | 用途 | 频率 |
|------|------|------|
| `asc-api-query.sh` | 查 App Store Connect API (apps/versions/state/IAP) | 手动 / 脚本触发 |
| `check-app-sales.sh` | iTunes Lookup 监控上架数据 (评分/版本/价格变化) | cron 每天 1 次 |
| `check-app-review.sh` | ASC API 监控审核状态 (PROCESSING → IN_REVIEW → READY) | cron 每 4h |
| `check-app-review-with-notify.sh` | launchd wrapper, 弹 Mac 通知 (macOS 专用) | launchd 每 2h |
| `asc-subscription-setup.py` | 创建/补齐 ASC Subscription Group + Products + Trial | 手动, 上架前跑 1 次 |

**所有脚本都跨项目 (跨 app)**: 用 `<app-name>` 作为第一个参数, 从 `~/.config/ios-projects/<app-name>.conf` 读配置。

---

## 1. 安装 (2 分钟)

### 1.1 装脚本 (从 openclaw-portable-template)

```bash
# Mac mini
mkdir -p ~/.openclaw/workspace/scripts
cd ~/.openclaw/workspace/scripts
# portable-template 自动 sync, 直接拿:

# 必备
test -f asc-api-query.sh || curl -fsSL -H "Authorization: token $TOKEN" \
  https://raw.githubusercontent.com/lauer3912/openclaw-portable-template/main/scripts/asc-api-query.sh \
  -o asc-api-query.sh
chmod +x asc-api-query.sh

test -f check-app-sales.sh || curl -fsSL -H "Authorization: token $TOKEN" \
  https://raw.githubusercontent.com/lauer3912/openclaw-portable-template/main/scripts/check-app-sales.sh \
  -o check-app-sales.sh
chmod +x check-app-sales.sh

test -f check-app-review.sh || curl -fsSL -H "Authorization: token $TOKEN" \
  https://raw.githubusercontent.com/lauer3912/openclaw-portable-template/main/scripts/check-app-review.sh \
  -o check-app-review.sh
chmod +x check-app-review.sh

# macOS 才有 launchd
[ "$(uname)" = "Darwin" ] && {
  curl -fsSL -H "Authorization: token $TOKEN" \
    https://raw.githubusercontent.com/lauer3912/openclaw-portable-template/main/scripts/check-app-review-with-notify.sh \
    -o check-app-review-with-notify.sh
  chmod +x check-app-review-with-notify.sh
}

# Python 脚本 (要 pip install pyjwt requests)
test -f asc-subscription-setup.py || curl -fsSL -H "Authorization: token $TOKEN" \
  https://raw.githubusercontent.com/lauer3912/openclaw-portable-template/main/scripts/asc-subscription-setup.py \
  -o asc-subscription-setup.py
chmod +x asc-subscription-setup.py

pip3 install pyjwt requests   # 如果还没装
```

### 1.2 装 ASC API key

```bash
# Mac mini
mkdir -p ~/.appstoreconnect/private_keys
cp ~/Desktop/AuthKey_*.p8 ~/.appstoreconnect/private_keys/
ls ~/.appstoreconnect/private_keys/   # 应有 AuthKey_<KEY_ID>.p8

# Ubuntu (同样)
mkdir -p ~/.appstoreconnect/private_keys
# 用 scp 从 Mac mini 拉:
scp macmini:'~/.appstoreconnect/private_keys/AuthKey_*.p8' ~/.appstoreconnect/private_keys/
# 或从佛老爷那里拿
```

### 1.3 装 project config (每个 iOS app 一份)

```bash
mkdir -p ~/.config/ios-projects
```

**VitaMindGo 例子** (`~/.config/ios-projects/VitaMindGo.conf`):

```ini
# iOS Project Config: VitaMindGo
# Used by: check-app-sales.sh, check-app-review.sh, asc-api-query.sh, asc-subscription-setup.py

APP_ID=6774840392
APP_DISPLAY_NAME=VitaMindGo
APP_BUNDLE=com.ggsheng.VitaMind
APP_VERSION=3.0.0
COUNTRY=us

# ASC API (per佛老爷的 token, 全 team 共用)
ASC_KEY_ID=H3973L93M5
ASC_ISSUER_ID=b2a00f88-3a8d-40d0-b148-1f1db92e10b7
```

**Subscription config 例子** (可选, 仅当 app 有 IAP):
`~/.config/ios-projects/VitaMindGo-subscriptions.json`:

```json
{
  "group_name": "VitaMindGo Pro",
  "subscriptions": [
    {
      "ref_name": "VitaMindGo Pro Monthly",
      "product_id": "vitamind_pro_monthly",
      "period": "ONE_MONTH",
      "display_name": "Pro Monthly",
      "description": "AI Coach, advanced insights, themes.",
      "price_usd": 4.99,
      "trial": true
    }
  ]
}
```

---

## 2. 用法 (5 个工具)

### 2.1 `asc-api-query.sh` — 查 ASC 后台 (无 cron)

```bash
# 列出所有 apps + 各 version state
asc-api-query.sh list-apps

# 拿指定 app 的 version 状态 (人类可读)
asc-api-query.sh version-state 6774840392

# 拿 JSON (脚本调用)
asc-api-query.sh version-state 6774840392 --json
```

**前置 env**:
```bash
export APP_STORE_CONNECT_ISSUER_ID="b2a00f88-3a8d-40d0-b148-1f1db92e10b7"
# 或加到 ~/.zshrc / ~/.bashrc
```

### 2.2 `check-app-sales.sh` — iTunes 上架数据监控

```bash
# 跑一次
check-app-sales.sh VitaMindGo

# 首次输出: 🎉 启动 + 当前数据
# 后续输出: NO_REPLY (没变) 或 通知 (变了)

# 重置 state (测试 / 数据漂移)
check-app-sales.sh VitaMindGo --reset
```

**配合 cron** (Mac mini 上):
```bash
# 每天 12:00 跑 VitaMindGo, 通知到 QQ
0 12 * * * /Users/user291981/.openclaw/workspace/scripts/check-app-sales.sh VitaMindGo
```

**Ubuntu 上** (用 agent-bus 替代 QQ 通知):
```bash
0 12 * * * /home/ubuntu/.openclaw/workspace/scripts/check-app-sales.sh VitaMindGo | \
  grep -v NO_REPLY | \
  bash /home/ubuntu/.openclaw/workspace/scripts/agent-bus.sh send Katherine-E2wa1m to-persona:Katherine report normal VitaMindGo "sales change" --body "$(cat)"
```

### 2.3 `check-app-review.sh` — 审核状态监控

```bash
check-app-review.sh VitaMindGo
# 首次: 📌 初始化记录
# 后续: NO_REPLY (没变) 或 🚨/🎉/⏸️/🔄 通知
```

**配合 cron** (Mac mini):
```bash
0 */4 * * * /Users/user291981/.openclaw/workspace/scripts/check-app-review.sh VitaMindGo
# 每 4h
```

### 2.4 `check-app-review-with-notify.sh` — macOS launchd wrapper (双保险)

**前置**: 有 `com.openclaw.<app-name>-review.plist` (在 `~/Library/LaunchAgents/`)
**装**:
```bash
# 看 plist 模板 (在 portable-template)
ls /Users/user291981/.openclaw/workspace/dist/openclaw-portable-template/com.openclaw.*-review.plist 2>/dev/null

# 复制 + 改 placeholder
cp ~/.../com.openclaw.<APP>-review.plist ~/Library/LaunchAgents/
# 改里面的 <APP_KEY> 为真实 app name, <SCRIPT_DIR> 为绝对路径
launchctl load ~/Library/LaunchAgents/com.openclaw.<APP>-review.plist
```

### 2.5 `asc-subscription-setup.py` — 创建 IAP (上架前 1 次)

```bash
# Ubuntu 直连 (设 ASC_NO_PROXY=1 绕过 Mac mini 代理)
ASC_NO_PROXY=1 python3 asc-subscription-setup.py VitaMindGo

# Mac mini (用默认 127.0.0.1:10808 代理)
python3 asc-subscription-setup.py VitaMindGo
```

**幂等**: 跑 100 次结果一样。先 list 已有, 缺啥补啥, 已有的 skip。

---

## 3. 多 app 管理

每个 iOS app 一份 config + 一套 cron:

```bash
~/.config/ios-projects/
├── VitaMindGo.conf
├── VitaMindGo-subscriptions.json
├── StretchFlow.conf       (将来)
└── ...

# Cron (Mac mini)
0 12 * * * check-app-sales.sh VitaMindGo
0 */4 * * * check-app-review.sh VitaMindGo
0 12 * * * check-app-sales.sh StretchFlow
0 */4 * * * check-app-review.sh StretchFlow
```

agent-bus 收到变化通知后, 自动 ping 佛老爷 + Katherine (互为备份)。

---

## 4. 跨平台注意点

### Mac mini (Katherine)
- 脚本直接用
- launchd 可用 (双保险)
- 代理 `127.0.0.1:10808` 默认开, 不需改
- 网络: 国内 → GitHub/API 走代理

### Ubuntu (UbuntuAgent)
- 脚本直接用
- launchd **不可用** (用 cron)
- 代理: 默认无, 设 `ASC_NO_PROXY=1` 直连 ASC API (Apple 不在中国防火)
- ASC API key 需要 scp 过来
- Project config: 自己写或从 Mac mini 同步
- 通知渠道: 用 `agent-bus send` 推到 Katherine 或 佛老爷

### Windows
- bash 需 WSL 或 git-bash
- ASC API 可跑
- launchd 不可用
- 网络: 视情况设代理

---

## 5. 配合 agent-bus 通知

**场景**: 审核状态变了 (e.g. IN_REVIEW → READY_FOR_SALE)

**自动通知链** (Mac mini):
```
check-app-review.sh 输出 🎉
  → cron 捕获, 推到 QQ
  → 佛老爷看到
  → 我 (Katherine) 看到佛老爷的回复, 跟 agent-bus 上的 UbuntuAgent 说
```

**Ubuntu 替代路径** (无 QQ):
```
check-app-review.sh 输出 🎉
  → cron 捕获, 用 agent-bus send 发到 Katherine (or to:佛老爷)
  → 佛老爷飞书 / QQ 看到 (通过我转发, 或 agent-bus 桥)
```

**示例 wrapper** (Ubuntu, 把监控结果转发到 agent-bus):
```bash
#!/bin/bash
# ~/bin/app-monitor-relay.sh
APP_KEY="$1"
RESULT=$(check-app-review.sh "$APP_KEY")
[[ "$RESULT" == "NO_REPLY" ]] && exit 0
agent-bus send UbuntuAgent-b2c1d4 to-persona:Katherine report normal "$APP_KEY" "review change" --body "$RESULT"
```

---

## 6. 升级 / 维护

- 脚本升级: 拉 `lauer3912/openclaw-portable-template/main/scripts/check-app*.sh` + `asc-*.sh` + `asc-subscription-setup.py`
- 协议升级: 佛老爷拍板, 我推 portable-template 新版
- Breaking change: 走 agent-bus 广播 `type:training` 通知所有 agent

---

## 7. 故障排除

| 症状 | 原因 | 修法 |
|------|------|------|
| `ModuleNotFoundError: jwt` | Python 缺 pyjwt | `pip3 install pyjwt requests` |
| `iTunes Lookup 解析失败` | 网络/代理 | 设 `export https_proxy=http://127.0.0.1:10808` 或 `-x` curl |
| `asc-api-query.sh 调用失败: HTTP 401` | API key 错 / Issuer ID 错 | 检查 `~/.appstoreconnect/private_keys/AuthKey_*.p8` + `APP_STORE_CONNECT_ISSUER_ID` |
| `config not found: ~/.config/ios-projects/<app>.conf` | 缺 config | 创建, 参考 §1.3 模板 |
| `state file 累积` | state file 7 天后自动清 | 等, 或 `--reset` |
| Mac launchd 不弹通知 | 通知权限 | System Settings → Notifications → Script Editor → Allow |

---

## 8. 完整 cron 例子 (Mac mini)

```cron
# VitaMindGo
0 12 * * * /Users/user291981/.openclaw/workspace/scripts/check-app-sales.sh VitaMindGo
0 */4 * * * /Users/user291981/.openclaw/workspace/scripts/check-app-review.sh VitaMindGo

# StretchFlow (将来)
0 12 * * * /Users/user291981/.openclaw/workspace/scripts/check-app-sales.sh StretchFlow
0 */4 * * * /Users/user291981/.openclaw/workspace/scripts/check-app-review.sh StretchFlow

# agent-bus 5 min 轮询
*/5 * * * * /Users/user291981/.openclaw/workspace/scripts/agent-bus-poll.sh >> /Users/user291981/.local/share/agent-bus/poll.log 2>&1

# agent-bus 每天自检
0 8 * * * /Users/user291981/.openclaw/workspace/scripts/agent-bus-test.sh
```

## 9. 完整 cron 例子 (Ubuntu)

```cron
# agent-bus 5 min
*/5 * * * * /home/ubuntu/.openclaw/workspace/scripts/agent-bus-poll.sh >> /home/ubuntu/.local/share/agent-bus/poll.log 2>&1

# VitaMindGo 监控 + 转发到 agent-bus
0 12 * * * /home/ubuntu/bin/app-monitor-relay.sh VitaMindGo sales
0 */4 * * * /home/ubuntu/bin/app-monitor-relay.sh VitaMindGo review
```
