#!/bin/bash
# ========================================
# OpenClaw: App Store Connect API 查询 (portable, macOS+Linux)
# ========================================
# 用法:
#   asc-api-query.sh list-apps                              # 列出所有 apps + 各 version state
#   asc-api-query.sh version-state <APP_ID>                 # 拿指定 app 的 version 状态
#   asc-api-query.sh version-state <APP_ID> --json          # 返回原始 JSON
#
# 前置:
#   1. API Key 在 ~/.appstoreconnect/private_keys/AuthKey_<KEY_ID>.p8
#   2. Issuer ID 在 env APP_STORE_CONNECT_ISSUER_ID (UUID 格式)
#   3. python3 在 PATH (macOS/Ubuntu 都预装)
#
# 设计:
#   - 纯 bash + openssl + python3 + curl, **无 pip 依赖**
#   - macOS / Ubuntu 行为一致 (Python 解析 DER → raw r||s, robust)
#   - JWT 有效期 20 分钟 (Apple 上限 60 分钟, 留余量)
#   - 状态机: PREPARE_FOR_SUBMISSION / WAITING_FOR_REVIEW / IN_REVIEW /
#             REJECTED / PENDING_DEVELOPER_RELEASE / READY_FOR_SALE
# ========================================

set -euo pipefail

# --- 配置 ---
API_KEY_DIR="${API_KEY_DIR:-$HOME/.appstoreconnect/private_keys}"
BASE_URL="https://api.appstoreconnect.apple.com/v1"

# --- 项目常量 (3 优先级, 必须在 ISSUER_ID 赋值前 source) ---
# 1. 显式 env var (CI/脚本调用)
# 2. openclaw.config (新 Ubuntu 入职后默认)
# 3. 空 (会要求用户输入)
INSTALL_DIR="${INSTALL_DIR:-$HOME/.openclaw/workspace/openclaw-portables}"
if [ -f "$INSTALL_DIR/openclaw.config" ]; then
    # shellcheck source=/dev/null
    . "$INSTALL_DIR/openclaw.config"
fi
ISSUER_ID="${APP_STORE_CONNECT_ISSUER_ID:-${ASC_ISSUER_ID:-}}"

# --- 用法 ---
usage() {
  echo "Usage: $0 <action> [args]"
  echo ""
  echo "Actions:"
  echo "  list-apps                            列出所有 apps + version state"
  echo "  version-state <APP_ID>              拿指定 app 的最新 version 状态"
  echo "  version-state <APP_ID> --json       返回原始 JSON"
  echo ""
  echo "Env vars (required):"
  echo "  APP_STORE_CONNECT_ISSUER_ID         App Store Connect Issuer ID (UUID)"
  echo ""
  echo "API Key 自动从 $API_KEY_DIR/AuthKey_*.p8 找"
  echo "  (若多个, 用 API_KEY_ID 指定, 例: H3973L93M5)"
  exit 1
}

# --- 参数检查 ---
if [ $# -lt 1 ]; then
  usage
fi

ACTION="$1"
shift

if [ -z "$ISSUER_ID" ]; then
  echo "❌ APP_STORE_CONNECT_ISSUER_ID 未设"
  echo "   老爷去 App Store Connect → Users & Access → Keys 拿 Issuer ID (UUID)"
  exit 2
fi

# --- 找 API Key ---
if [ -n "${API_KEY_ID:-}" ]; then
  KEY_PATH="$API_KEY_DIR/AuthKey_${API_KEY_ID}.p8"
else
  # 自动找第一个
  KEY_PATH=$(ls "$API_KEY_DIR"/AuthKey_*.p8 2>/dev/null | head -1 || echo "")
fi

if [ -z "$KEY_PATH" ] || [ ! -f "$KEY_PATH" ]; then
  echo "❌ 找不到 API Key: $API_KEY_DIR/AuthKey_*.p8"
  echo "   从 ~/Desktop/ 复制: mkdir -p $API_KEY_DIR && cp ~/Desktop/AuthKey_*.p8 $API_KEY_DIR/"
  exit 2
fi

KEY_ID=$(basename "$KEY_PATH" | sed -E 's/AuthKey_([A-Z0-9]+)\.p8/\1/')

# --- 核心: 生成 ES256 JWT ---
# 设计: 把所有数据 (issuer, key_id, key_path, base_url) 通过 env 传给 Python,
#       Python 内部生成 JWT + 调 API + 解析 JSON + 格式化输出。
#       这样避开 bash/python 字符串传递, 也避开 DER parser bug。
# --- 调度 ---
case "$ACTION" in
  list-apps)
    ISSUER_ID="$ISSUER_ID" KEY_ID="$KEY_ID" KEY_PATH="$KEY_PATH" \
    ACTION="list-apps" APP_ID="" BASE_URL="$BASE_URL" \
    python3 << 'PYEOF'
import os, sys, json, time, subprocess, base64, urllib.request, urllib.error

ISSUER_ID = os.environ["ISSUER_ID"]
KEY_ID = os.environ["KEY_ID"]
KEY_PATH = os.environ["KEY_PATH"]
BASE_URL = os.environ["BASE_URL"]

def b64url(b):
    return base64.urlsafe_b64encode(b).rstrip(b"=").decode()

def generate_jwt():
    now = int(time.time())
    header = b64url(json.dumps({"alg": "ES256", "kid": KEY_ID, "typ": "JWT"}).encode())
    payload = b64url(json.dumps({
        "iss": ISSUER_ID, "iat": now, "exp": now + 1200, "aud": "appstoreconnect-v1"
    }).encode())
    data = f"{header}.{payload}".encode()
    # openssl dgst 输出 DER
    der = subprocess.run(
        ["openssl", "dgst", "-sha256", "-sign", KEY_PATH],
        input=data, capture_output=True, check=True
    ).stdout
    # 转 raw r||s
    assert der[0] == 0x30, f"Expected SEQUENCE, got {der[0]:#x}"

    def read_int(pos):
        assert der[pos] == 0x02, f"Expected INTEGER at {pos}, got {der[pos]:#x}"
        pos += 1
        length = der[pos]; pos += 1
        value = der[pos:pos+length]; pos += length
        if value[0] == 0:  # strip DER leading zero
            value = value[1:]
        return value, pos

    r, pos = read_int(2)
    s, pos = read_int(pos)
    r = r.rjust(32, b"\x00")
    s = s.rjust(32, b"\x00")
    assert len(r) == 32 and len(s) == 32, f"r/s length: {len(r)}/{len(s)}"
    sig = b64url(r + s)
    return f"{header}.{payload}.{sig}"

def api_get(url):
    jwt = generate_jwt()
    req = urllib.request.Request(url, headers={"Authorization": f"Bearer {jwt}"})
    try:
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read())
    except urllib.error.HTTPError as e:
        return json.loads(e.read())

print(f"🔍 查 App Store Connect apps...")
print(f"   Issuer: {ISSUER_ID}")
print(f"   Key: {KEY_PATH} (ID={KEY_ID})")
print()
data = api_get(f"{BASE_URL}/apps?limit=200")
if "errors" in data:
    print("❌ API 错误:")
    for e in data["errors"]:
        print(f"   {e['status']} {e['code']}: {e['title']}")
    sys.exit(1)
for app in data.get("data", []):
    a = app["attributes"]
    print(f'= Name: {a["name"]}')
    print(f"  ID: {app['id']}")
    print(f"  Bundle ID: {a['bundleId']}")
    print(f"  SKU: {a.get('sku', '')}")
    print(f"  Primary Locale: {a.get('primaryLocale', '')}")
    print()
PYEOF
    ;;

  version-state)
    if [ $# -lt 1 ]; then
      echo "❌ 缺 APP_ID"; usage
    fi
    APP_ID="$1"
    shift
    JSON_FLAG=""
    if [ "${1:-}" = "--json" ]; then
      JSON_FLAG="--json"
    fi

    if [ -n "$JSON_FLAG" ]; then
      # 返回原始 JSON
      ISSUER_ID="$ISSUER_ID" KEY_ID="$KEY_ID" KEY_PATH="$KEY_PATH" \
      ACTION="version-state" APP_ID="$APP_ID" BASE_URL="$BASE_URL" JSON_FLAG="1" \
      python3 << 'PYEOF'
import os, sys, json, time, subprocess, base64, urllib.request, urllib.error

ISSUER_ID = os.environ["ISSUER_ID"]
KEY_ID = os.environ["KEY_ID"]
KEY_PATH = os.environ["KEY_PATH"]
APP_ID = os.environ["APP_ID"]
BASE_URL = os.environ["BASE_URL"]

def b64url(b):
    return base64.urlsafe_b64encode(b).rstrip(b"=").decode()

def generate_jwt():
    now = int(time.time())
    header = b64url(json.dumps({"alg": "ES256", "kid": KEY_ID, "typ": "JWT"}).encode())
    payload = b64url(json.dumps({
        "iss": ISSUER_ID, "iat": now, "exp": now + 1200, "aud": "appstoreconnect-v1"
    }).encode())
    data = f"{header}.{payload}".encode()
    der = subprocess.run(
        ["openssl", "dgst", "-sha256", "-sign", KEY_PATH],
        input=data, capture_output=True, check=True
    ).stdout
    assert der[0] == 0x30
    def read_int(pos):
        assert der[pos] == 0x02
        pos += 1
        length = der[pos]; pos += 1
        value = der[pos:pos+length]; pos += length
        if value[0] == 0:
            value = value[1:]
        return value, pos
    r, pos = read_int(2)
    s, pos = read_int(pos)
    r = r.rjust(32, b"\x00")
    s = s.rjust(32, b"\x00")
    return f"{header}.{payload}.{b64url(r + s)}"

jwt = generate_jwt()
req = urllib.request.Request(
    f"{BASE_URL}/apps/{APP_ID}/appStoreVersions",
    headers={"Authorization": f"Bearer {jwt}"}
)
try:
    with urllib.request.urlopen(req) as resp:
        print(json.dumps(json.loads(resp.read()), indent=2, ensure_ascii=False))
except urllib.error.HTTPError as e:
    print(json.dumps(json.loads(e.read()), indent=2, ensure_ascii=False))
PYEOF
    else
      ISSUER_ID="$ISSUER_ID" KEY_ID="$KEY_ID" KEY_PATH="$KEY_PATH" \
      ACTION="version-state" APP_ID="$APP_ID" BASE_URL="$BASE_URL" \
      python3 << 'PYEOF'
import os, sys, json, time, subprocess, base64, urllib.request, urllib.error

ISSUER_ID = os.environ["ISSUER_ID"]
KEY_ID = os.environ["KEY_ID"]
KEY_PATH = os.environ["KEY_PATH"]
APP_ID = os.environ["APP_ID"]
BASE_URL = os.environ["BASE_URL"]

def b64url(b):
    return base64.urlsafe_b64encode(b).rstrip(b"=").decode()

def generate_jwt():
    now = int(time.time())
    header = b64url(json.dumps({"alg": "ES256", "kid": KEY_ID, "typ": "JWT"}).encode())
    payload = b64url(json.dumps({
        "iss": ISSUER_ID, "iat": now, "exp": now + 1200, "aud": "appstoreconnect-v1"
    }).encode())
    data = f"{header}.{payload}".encode()
    der = subprocess.run(
        ["openssl", "dgst", "-sha256", "-sign", KEY_PATH],
        input=data, capture_output=True, check=True
    ).stdout
    assert der[0] == 0x30
    def read_int(pos):
        assert der[pos] == 0x02
        pos += 1
        length = der[pos]; pos += 1
        value = der[pos:pos+length]; pos += length
        if value[0] == 0:
            value = value[1:]
        return value, pos
    r, pos = read_int(2)
    s, pos = read_int(pos)
    r = r.rjust(32, b"\x00")
    s = s.rjust(32, b"\x00")
    return f"{header}.{payload}.{b64url(r + s)}"

def api_get(url):
    jwt = generate_jwt()
    req = urllib.request.Request(url, headers={"Authorization": f"Bearer {jwt}"})
    try:
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read())
    except urllib.error.HTTPError as e:
        return json.loads(e.read())

print(f"🔍 查 App {APP_ID} 的 version 状态...")
print()
data = api_get(f"{BASE_URL}/apps/{APP_ID}/appStoreVersions")
if "errors" in data:
    print("❌ API 错误:")
    for e in data["errors"]:
        print(f"   {e['status']} {e['code']}: {e['title']}")
    sys.exit(1)
for v in data.get("data", []):
    a = v["attributes"]
    print(f'= Version: {a.get("versionString", "?")}')
    print(f"  ID: {v['id']}")
    print(f"  State: {a.get('appStoreState', '?')}")
    print(f"  Platform: {a.get('platform', '?')}")
    print(f"  Created: {a.get('createdDate', '?')}")
    if "releaseType" in a:
        print(f"  Release Type: {a['releaseType']}")
    if "earliestReleaseDate" in a:
        print(f"  Earliest Release: {a['earliestReleaseDate']}")
    print()
PYEOF
    fi
    ;;

  *)
    echo "❌ 未知 action: $ACTION"; usage
    ;;
esac
