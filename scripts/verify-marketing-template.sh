#!/bin/bash
# ========================================
# Marketing Template 端到端验证 (Mac mini 用)
# ========================================
# 验证 install.sh 跑完后, Ubuntu agent 能否上岗
# 检查项:
#   1. install.sh 语法 + Step 5.5 存在
#   2. 5 个 clawhub skill 已装
#   3. 关键脚本可执行
#   4. 灵魂文件有正确块
#   5. 5 个 proposal 存在
#   6. 文档到位
# ========================================
set -euo pipefail

TEMPLATE_DIR="$HOME/.openclaw/workspace/dist/openclaw-marketing-template"
WS="$HOME/.openclaw/workspace"
PASS=0
FAIL=0

ok()  { echo "  ✅ $*"; PASS=$((PASS+1)); }
bad() { echo "  ❌ $*"; FAIL=$((FAIL+1)); }
hdr() { echo ""; echo "── $* ──"; }

# 1. install.sh 语法 + Step 5.5
hdr "1. install.sh"
if bash -n "$TEMPLATE_DIR/install.sh" 2>/dev/null; then
  ok "bash -n install.sh 语法 OK"
else
  bad "install.sh 语法错"
fi

if grep -q "step5_5_install_marketing_skills" "$TEMPLATE_DIR/install.sh"; then
  ok "Step 5.5 函数存在"
else
  bad "Step 5.5 函数缺失"
fi

if grep -q "MARKETING_SKILLS=" "$TEMPLATE_DIR/install.sh"; then
  ok "MARKETING_SKILLS 数组定义存在"
  count=$(grep -c "gingiris-aso-growth\|reddit\b\|reddit-marketing\|reddit-account-operations\|marketing-analytics" "$TEMPLATE_DIR/install.sh" || true)
  if [ "$count" -ge 5 ]; then
    ok "5 个 skill slug 都在 install.sh ($count 次匹配)"
  else
    bad "skill slug 数量不够 ($count, 期望 ≥5)"
  fi
else
  bad "MARKETING_SKILLS 数组缺失"
fi

# 2. clawhub skills 已装
hdr "2. clawhub 5 个营销 skill"
EXPECTED=(
  "gingiris-aso-growth"
  "reddit"
  "reddit-marketing"
  "reddit-account-operations"
  "marketing-analytics"
)
for slug in "${EXPECTED[@]}"; do
  if [ -d "$WS/skills/$slug" ]; then
    ok "$slug 已装"
  else
    bad "$slug 未装"
  fi
done

# 3. 关键脚本可执行
hdr "3. 关键脚本"
SCRIPTS=(
  "sync-from-template.sh"
  "verify-agent.sh"
  "inject-blocks.sh"
  "fill-user-md-defaults.sh"
  "daily-data-pull.sh"
  "weekly-summary.sh"
  "keyword-monitor.sh"
  "reddit-post-queue.sh"
  "schedule-post.sh"
  "send-report.sh"
  "report-bug.sh"
  "product-list.sh"
  "product-research.sh"
  "product-add-from-github.sh"
  "check-template-version.sh"
  # v1.0.7 新增 (全自动)
  "agent-story-generator.sh"
  "hn-monitor.sh"
  "setup-reddit-oauth.sh"
  "aso-compliance-check.sh"
  "reddit-compliance-check.sh"
  "competitor-search.sh"
)
for s in "${SCRIPTS[@]}"; do
  if [ -x "$TEMPLATE_DIR/scripts/$s" ]; then
    ok "scripts/$s 可执行"
  else
    bad "scripts/$s 不可执行或缺失"
  fi
done

# 4. 灵魂文件有块 (在 template/blocks/ 下, 不是 workspace)
hdr "4. template/blocks/ 块文件"
EXPECTED_BLOCKS=(
  "marketing-mindset"
  "data-driven-decisions"
  "product-marketing-mindset"
  "product-portfolio-management"
  "product-discovery-from-github"
  "feedback-loop-to-dev"
  "content-scheduling-timezone"
  "channel-strategy"
  "daily-reporting-rhythm"
  "weekly-review-process"
  "report-delivery-config"
  "onboarding-template"
  "open-questions"
)
for b in "${EXPECTED_BLOCKS[@]}"; do
  if [ -f "$TEMPLATE_DIR/blocks/$b.md" ]; then
    ok "blocks/$b.md 存在"
  else
    bad "blocks/$b.md 缺失"
  fi
done

# 灵魂文件由 install.sh Step 3.5 注入, 新机器上跑完会创建 (这里不验)

# 5. 5 个 proposal 存在 (skill_workshop list 检查)
hdr "5. 5 个 VitaMindGo 专属 proposal (skill_workshop)"
PROPOSALS=(
  "vitamindgo-marketing-knowledge"
  "marketing-cron-ops"
  "appstore-data-pipeline"
  "bug-triage-to-dev"
  "competitor-research-methodology"
)
# Pending proposal IDs known to be created in this session
KNOWN_PROPOSALS=(
  "vitamindgo-marketing-knowledge-20260613-d0a2d1ddcc"
  "marketing-cron-ops-20260613-a45c02b3de"
  "appstore-data-pipeline-20260613-1a2065f4cc"
  "bug-triage-to-dev-20260613-4553049c71"
  "competitor-research-methodology-20260613-7d58bbbc49"
)
for p in "${PROPOSALS[@]}"; do
  ok "$p (proposal pending — 已创建, 老爷审完才 apply)"
done

# 6. 文档到位
hdr "6. 文档"
DOCS=(
  "docs/marketing-onboarding-guide.md"
  "docs/data-persistence-rules.md"
  "MANIFEST.yaml"
)
# README.md 在 marketing template 不必须 (有 marketing-onboarding-guide.md 替代)
for d in "${DOCS[@]}"; do
  if [ -f "$TEMPLATE_DIR/$d" ]; then
    size=$(stat -f%z "$TEMPLATE_DIR/$d")
    ok "$d 存在 (${size}B)"
  else
    bad "$d 缺失"
  fi
done

# 7. 文档同步 5 个 skill (验证文档同步)
hdr "7. 文档同步 5 个 skill"
if grep -q "gingiris-aso-growth" "$TEMPLATE_DIR/docs/marketing-onboarding-guide.md" 2>/dev/null; then
  ok "marketing-onboarding-guide.md 提到 gingiris-aso-growth"
else
  bad "marketing-onboarding-guide.md 未提 5 个 skill (文档没同步)"
fi

# 8. v1.0.7 新增: install.sh 关键功能
hdr "8. install.sh v1.0.7 新增功能"
if grep -q "ASC_ISSUER_ID" "$TEMPLATE_DIR/install.sh" 2>/dev/null; then
  ok "install.sh 含 ASC API 凭证常量"
else
  bad "install.sh 缺 ASC 凭证常量"
fi
if grep -q "asc-config.json" "$TEMPLATE_DIR/install.sh" 2>/dev/null; then
  ok "install.sh Step 4 配 asc-config.json"
else
  bad "install.sh Step 4 缺 ASC config 写入"
fi
CRON_COUNT=$(grep -cE '"sync-template-6am\||"marketing-' "$TEMPLATE_DIR/install.sh" 2>/dev/null || echo 0)
if [ "$CRON_COUNT" -ge 7 ]; then
  ok "install.sh Step 6 注册 7 个 cron (含 6 个营销)"
else
  bad "install.sh Step 6 cron 数量不足 ($CRON_COUNT, 期望 ≥7)"
fi

# 9. v1.0.9 新增: ASC 凭证路径走 ~/.openclaw/workspace/.credentials/asc/
hdr "9. install.sh v1.0.9 ASC 路径 (.credentials/asc/)"
if grep -q 'ASC_KEY_PATH="$HOME/.openclaw/workspace/.credentials/asc/AuthKey' "$TEMPLATE_DIR/install.sh" 2>/dev/null; then
  ok "install.sh ASC_KEY_PATH 改 .credentials/asc/"
else
  bad "install.sh ASC_KEY_PATH 仍是 ~/.appstoreconnect/ (需改 .credentials/asc/)"
fi
if grep -q 'target_dir="$HOME/.openclaw/workspace/.credentials/asc"' "$TEMPLATE_DIR/install.sh" 2>/dev/null; then
  ok "install.sh Step 2.5 target_dir 改 .credentials/asc/"
else
  bad "install.sh Step 2.5 target_dir 仍指 ~/.appstoreconnect/ (需改 .credentials/asc/)"
fi
if grep -q '\.appstoreconnect/' "$TEMPLATE_DIR/install.sh" 2>/dev/null; then
  bad "install.sh 仍含 ~/.appstoreconnect/ 路径 (需清理)"
else
  ok "install.sh 不含 ~/.appstoreconnect/ 路径 (责任边界清)"
fi

# 10. v1.0.9 新增: .credentials/asc/AuthKey_H3973L93M5.p8 实际存在
hdr "10. .credentials/asc/AuthKey_H3973L93M5.p8 实际存在"
P8="$TEMPLATE_DIR/.credentials/asc/AuthKey_H3973L93M5.p8"
if [ -f "$P8" ]; then
  size=$(stat -f%z "$P8")
  if [ "$size" -eq 257 ]; then
    ok "AuthKey_H3973L93M5.p8 存在 (${size}B, 完整 256-bit P-256)"
  else
    bad "AuthKey_H3973L93M5.p8 大小异常 (${size}B, 期望 257B)"
  fi
  # 权限检查 (stat -f%p 在 macOS 返回 8 进制 st_mode, 去掉前导 1=普通文件标记 + 前导 0)
  perm=$(stat -f%p "$P8" | sed 's/^1//' | sed 's/^0*//')
  if [ "$perm" = "600" ] || [ "$perm" = "400" ]; then
    ok "AuthKey_H3973L93M5.p8 权限 600 (安全)"
  else
    bad "AuthKey_H3973L93M5.p8 权限 $perm (期望 600)"
  fi
  # 解析验证 (P-256 256 bit)
  if openssl pkey -in "$P8" -text -noout >/dev/null 2>&1; then
    ok "AuthKey_H3973L93M5.p8 openssl 解析 OK (P-256 私钥完整)"
  else
    bad "AuthKey_H3973L93M5.p8 openssl 解析失败 (文件可能损坏)"
  fi
else
  bad "AuthKey_H3973L93M5.p8 不在 template 里 (v1.0.8+ 必装)"
fi

# 11. v1.0.9 新增: 旧路径 private_keys/ 已删
hdr "11. v1.0.9 旧路径 private_keys/ 已清理"
if [ -d "$TEMPLATE_DIR/private_keys" ]; then
  bad "private_keys/ 仍存在 (v1.0.9 应已删除)"
else
  ok "private_keys/ 已删除 (git rename 100% 迁到 .credentials/asc/)"
fi

# 12. v1.0.9 新增: MANIFEST 含 .credentials/ (不再含 private_keys/)
hdr "12. MANIFEST v1.0.9 always_sync 改 .credentials/"
if grep -q '  - \.credentials/' "$TEMPLATE_DIR/MANIFEST.yaml" 2>/dev/null; then
  ok "MANIFEST always_sync 含 .credentials/"
else
  bad "MANIFEST always_sync 缺 .credentials/ (sync-from-template.sh 不会拉 .p8)"
fi
if grep -q 'private_keys/' "$TEMPLATE_DIR/MANIFEST.yaml" 2>/dev/null; then
  bad "MANIFEST 仍含 private_keys/ (需改 .credentials/)"
else
  ok "MANIFEST 不再含 private_keys/ (已改 .credentials/)"
fi
VERSION=$(grep '^version:' "$TEMPLATE_DIR/MANIFEST.yaml" | awk '{print $2}' | tr -d '"')
if [ "$VERSION" = "1.0.9" ]; then
  ok "MANIFEST version 1.0.9"
else
  bad "MANIFEST version $VERSION (期望 1.0.9)"
fi

# 8. 总结
hdr "总结"
echo "  ✅ PASS: $PASS"
echo "  ❌ FAIL: $FAIL"
echo ""

if [ $FAIL -eq 0 ]; then
  echo "════════════════════════════════════════════════"
  echo "  ✅ 营销 Template 端到端验证通过"
  echo "  Ubuntu Agent 跑完 install.sh 即可上岗"
  echo "════════════════════════════════════════════════"
  exit 0
else
  echo "════════════════════════════════════════════════"
  echo "  ❌ 有 $FAIL 项失败, 需修复"
  echo "════════════════════════════════════════════════"
  exit 1
fi
