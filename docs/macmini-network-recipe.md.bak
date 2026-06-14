# Mac mini 网络 + SSH 大文件传输 — Agent 操作卡

> **触发版本**: OpenClaw Portable Template **v1.0.15+**
> **写于**: 2026-06-11 (Ubuntu Agent 报 SSH 大文件传输不稳, 老爷派工立卡)
> **深读**: `docs/SOP-iOS-Ubuntu-Development.md` §2.7 + §2.6 Symptom 7

---

## 🎯 一句话总览

| 你在哪台机器 | 外网命令 (git / curl / brew / npm ...) | 大文件传输 |
|--------------|----------------------------------------|------------|
| **Mac mini** (Katherine 本地 / SSH 触发) | **必加代理** `http://127.0.0.1:10808` | **走 git push + pull (代理)**, 别 SSH 传 |
| **Ubuntu agent** | ❌ **不加代理**, 直连 GitHub 没问题 | `git push` 上 GitHub, 让 Mac mini pull |
| **Mac 本机 (非 mini)** | ❌ 不加代理 | 同 Ubuntu, 直连 |

---

## 📋 4 步操作流程

### Step 1: 识别你在哪

```bash
hostname                  # macmini / ubuntu-* / lauer3912deMac-mini 等
uname -s                  # Darwin = Mac 类, Linux = Ubuntu
```

> ⚠️ 拿不准就当 Mac mini 处理 (加代理), **多 5ms 比 timeout 30 分钟强**

### Step 2: Mac mini 上选代理模式

| 场景 | 推荐写法 | 例 |
|------|---------|-----|
| **只跑 1 个命令** | 单次 `-x` / `-c` | `curl -x http://127.0.0.1:10808 ...` |
| **当前 shell 一连串命令** | 临时 export | `export http_proxy=...; git pull; brew update; unset` |
| **每次新 shell 都要** | 永久写入 `~/.zshrc` | `echo 'export http_proxy=...' >> ~/.zshrc` |

**3 种写法速查** (Mac mini 上跑):

```bash
# 写法 A: curl 单次
curl -x http://127.0.0.1:10808 https://api.github.com/repos/lauer3912/ios-VitaMindGo

# 写法 B: git 单次
git -c http.proxy=http://127.0.0.1:10808 clone https://github.com/lauer3912/ios-VitaMindGo.git

# 写法 C: 整 shell 临时 export
export http_proxy=http://127.0.0.1:10808
export https_proxy=http://127.0.0.1:10808
export all_proxy=socks5://127.0.0.1:10808
git clone ...   # 自动走代理
curl ...        # 自动走代理
unset http_proxy https_proxy all_proxy   # 还原
```

### Step 3: 大文件传输 — 必走 git, 别 SSH

> **根因**: SSH 长流 (10MB+) 抖动 + 防火墙超时, keepalive (60s 心跳) 救不回来

#### ✅ 首选 (绕开 SSH, 5 步搞定)

```bash
# === Ubuntu agent (直连 GitHub, 不加代理) ===
cd ~/.openclaw/workspace/projects/ios-{AppName}/
git add -A
git commit -m "feat: <msg>"
git push origin main          # ✅ 直连, 几十秒搞定

# === Mac mini (走代理拉) ===
ssh macmini 'export http_proxy=http://127.0.0.1:10808 https_proxy=http://127.0.0.1:10808 \
  && cd ~/Desktop/ios-{AppName}/ \
  && git pull origin main'    # ✅ 增量 pull, 几十 KB 秒级
```

**原理**: SSH 传 100MB = 长流易断 ❌, 改成 `git push` 几 MB + `git pull` 增量 = 稳如老狗 ✅

#### ⚠️ 次选 (非要 SSH 传, 加固连接)

```bash
# rsync 允许断点续传
rsync -avz --partial --progress --timeout=120 src/ macmini:~/dst/

# scp 加压缩 + 限速
scp -C -l 8192 big.tar.gz macmini:~/   # 8Mbps 限速, 不挤爆链路

# ssh 临时更激进 keepalive (单次命令)
ssh -o ServerAliveInterval=15 -o ServerAliveCountMax=2 macmini '...'
```

#### 🆘 兜底 (实在要 SSH 传 50MB+ 大文件)

```bash
# 分块: 5MB/块, 一块一块传 (任一块断都可单独重传)
split -b 5M bigfile chunks/chunk_
for f in chunks/chunk_*; do scp -C "$f" macmini:~/chunks/; done
ssh macmini 'cat ~/chunks/chunk_* > bigfile && rm -rf ~/chunks/'
# 本地清理: rm -rf chunks/
```

### Step 4: 验证 (3 项检查)

```bash
# 1. 代理端口在听 (Mac mini 上)
lsof -i :10808 2>/dev/null || nc -zv 127.0.0.1 10808

# 2. 代理能通 GitHub (Mac mini 上)
curl -fsSL --max-time 15 -x http://127.0.0.1:10808 https://api.github.com | head -3

# 3. git 走代理能拉 (Mac mini 上)
git -c http.proxy=http://127.0.0.1:10808 ls-remote https://github.com/lauer3912/ios-VitaMindGo.git HEAD
```

---

## 🚨 7 条铁律 (绝对不能做)

| # | 不能做 | 为什么 |
|---|--------|--------|
| 1 | `install.sh` 加代理检测 | Ubuntu 不需要, 加了浪费 5s + 误导新 agent |
| 2 | `setup-ubuntu-ssh-client.sh` 设 `http_proxy` | Ubuntu 直连没问题, 这是 Mac mini 的 workaround |
| 3 | `setup-macos-ssh-host.sh` 写死代理 | 让老爷自己 `export` 到 `~/.zshrc`, 脚本不替 |
| 4 | `sync-from-template.sh` / `distribute-sop.sh` 加代理 fallback | 同上, 不是 OpenClaw 通用配置 |
| 5 | Ubuntu agent 主动 `export http_proxy=...` | Ubuntu 不需要, 反而可能搞坏自己直连 |
| 6 | Mac mini 上 `curl https://api.github.com` (无 -x) | 必 timeout, 报"网络问题"前先加代理 |
| 7 | Mac mini 上 `git clone` 全仓 / `rsync` 100MB+ | 走 git push + pull (Step 3 首选), 别硬传 |

---

## 🗂️ 触发场景速查表

| 场景 | 命令 | 加代理? |
|------|------|---------|
| Mac mini `git clone/pull/push` | `git -c http.proxy=http://127.0.0.1:10808 ...` | ✅ |
| Mac mini `curl` API / raw | `curl -x http://127.0.0.1:10808 ...` | ✅ |
| Mac mini `gh api` | `HTTPS_PROXY=http://127.0.0.1:10808 gh api ...` | ✅ |
| Mac mini `brew install` | `HTTPS_PROXY=http://127.0.0.1:10808 brew ...` | ✅ |
| Mac mini `npm install` | `npm config set proxy http://127.0.0.1:10808 && npm install` | ✅ |
| Mac mini `xcodebuild` 拉 SPM | 走 `export HTTPS_PROXY=...` 即可 | ✅ |
| Ubuntu `git push origin main` | 无需任何代理 | ❌ |
| Ubuntu `curl https://api.github.com` | 无需任何代理 | ❌ |
| Ubuntu `ssh macmini 'git pull ...'` | **Mac mini 那段**需要代理 (Step 3 SSH 写法) | ⚠️ 中转 |

---

## 🔗 相关章节

- **SOP §2.7** — Mac mini 网络约束与本地代理 (深读, 含完整警告)
- **SOP §2.6 Symptom 7** — 大文件 SSH 传输极不稳定 (4 套方案)
- **SOP §3.1** — Mac mini 项目根目录布局 (含代理提示)
- **MEMORY.md §🌐 网络代理** — 2026-06-10 老爷拍板永久规则