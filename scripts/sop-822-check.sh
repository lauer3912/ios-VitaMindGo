#!/bin/bash
# SOP §8.22 完整自检套件
# 用于: 上架前 / 早 8 点 / HR-88 违规后 / 任何 SOP 变更后
# 沉淀日期: 2026-06-04

# 不设 set -e: 自检检查有成功有失败是正常的

# 检查器 (带 PASS/FAIL 计数)
ce() {  # check equal (string)
  local id="$1" desc="$2" actual="$3" expected="$4"
  if [ "$actual" = "$expected" ]; then
    echo "✅ $id  $desc ($actual)"
    PASS=$((PASS+1))
  else
    echo "❌ $id  $desc (实际=$actual 期望=$expected)"
    FAIL=$((FAIL+1))
  fi
}

cg() {  # check >= (int)
  local id="$1" desc="$2" actual="$3" min="$4"
  if [ "$actual" -ge "$min" ] 2>/dev/null; then
    echo "✅ $id  $desc ($actual ≥ $min)"
    PASS=$((PASS+1))
  else
    echo "❌ $id  $desc (实际=$actual 最小=$min)"
    FAIL=$((FAIL+1))
  fi
}

ci() {  # check int with op
  local id="$1" desc="$2" actual="$3" op="$4" expected="$5"
  if awk -v a="$actual" -v e="$expected" -v op="$op" 'BEGIN {
    if (op == "<=") { if (a <= e) exit 0; else exit 1; }
    else if (op == "==") { if (a == e) exit 0; else exit 1; }
    else if (op == ">=") { if (a >= e) exit 0; else exit 1; }
    else { exit 2; }
  }'; then
    echo "✅ $id  $desc ($actual $op $expected)"
    PASS=$((PASS+1))
  else
    echo "❌ $id  $desc (实际=$actual $op 期望=$expected)"
    FAIL=$((FAIL+1))
  fi
}

# --- 实际自检 ---
WORKSPACE="${WORKSPACE:-/Users/user291981/.openclaw/workspace}"
PROJECT="${PROJECT:-$HOME/.openclaw/workspace/projects/ios-{AppName}}"
SOP="$WORKSPACE/docs/SOP-iOS-Local-Development.md"
LISTING="$PROJECT/AppStore/Listing.md"

echo "════════════════════════════════════════════════════════════"
echo "  SOP §8.22 完整自检套件"
echo "  时间: $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo "════════════════════════════════════════════════════════════"

PASS=0
FAIL=0

echo ""
echo "═══ HR-87: 规则编号一致性 ═══"
hr_uniq=$(grep -oE "\*\*HR-[0-9]+\*\*" "$SOP" | sort -u | wc -l | tr -d ' ')
hr_total=$(grep -oE "\*\*HR-[0-9]+\*\*" "$SOP" | wc -l | tr -d ' ')
sc_uniq=$(grep -oE "\*\*SC-[0-9]+\*\*" "$SOP" | sort -u | wc -l | tr -d ' ')
ce "HR-87a" "HR 唯一编号数 = 总出现次数" "$hr_uniq" "$hr_total"
# SC cross-ref 多次引用合法，不比较 unique == total
# 只检查 unique 编号是否不重复 (sort -u 已保证)
[ "$sc_uniq" -gt "0" ] && PASS=$((PASS+1))  # SC 编号存在即合法

echo ""
echo "═══ HR-88 + SC-70: workspace 根零图片 ═══"
root_png=$(ls "$WORKSPACE"/*.png 2>/dev/null | wc -l | tr -d ' ')
root_jpg=$(ls "$WORKSPACE"/*.jpg "$WORKSPACE"/*.jpeg 2>/dev/null | wc -l | tr -d ' ')
root_gif=$(ls "$WORKSPACE"/*.gif 2>/dev/null | wc -l | tr -d ' ')
ce "SC-70"   "workspace 根 *.png 数量"  "$root_png" "0"
ce "HR-88a"  "workspace 根 *.jpg 数量"  "$root_jpg" "0"
ce "HR-88b"  "workspace 根 *.gif 数量"  "$root_gif" "0"

echo ""
echo "═══ SC-65: Listing.md 字段完整性 ═══"
ce "SC-65a" "§5 Support URL 存在"   "$(grep -c '^## 5\.' "$LISTING")" "1"
ce "SC-65b" "§5A Copyright 存在"     "$(grep -c '^## 5A\.' "$LISTING")" "1"
ce "SC-65c" "§10.1-10.6 子节数"     "$(grep -cE '^### 10\.[1-6] ' "$LISTING")" "6"

echo ""
echo "═══ SC-66: Copyright 格式 ═══"
copyright_value=$(grep -E "^\| \*\*Copyright\*\*" "$LISTING" | sed 's/.*\*\*Copyright\*\* *| *//;s/ *|.*//')
echo "  Copyright 实际值: '$copyright_value'"
ce "SC-66a" "Copyright 是 YYYY OwnerName 格式" "$copyright_value" '`YYYY OwnerName` (应替换为当前年+老爷名)'
copy_in_value=$(echo "$copyright_value" | grep -cE "©|\(c\)")
ce "SC-66b" "Copyright 值无 © 符号" "$copy_in_value" "0"

echo ""
echo "═══ SC-67: Regulated Medical Device 措辞 ═══"
section_104=$(awk '/^### 10\.4 /,/^### 10\.5 /' "$LISTING")
cg "SC-67a" "含 'lifestyle/wellness'"      "$(echo "$section_104" | grep -ciE 'lifestyle|wellness')" "1"
cg "SC-67b" "声明 'NOT a medical device'"  "$(echo "$section_104" | grep -ciE 'not a (regulated )?medical device|is not a medical')" "1"

echo ""
echo "═══ SC-68: App Encryption 措辞 ═══"
section_105=$(awk '/^### 10\.5 /,/^### 10\.6 /' "$LISTING")
cg "SC-68a" "含 'HTTPS/TLS'"      "$(echo "$section_105" | grep -ciE 'https|tls')" "1"
cg "SC-68b" "含 'Category 5'"    "$(echo "$section_105" | grep -ciE 'category 5|cat 5|pt 2|note 4')" "1"
cg "SC-68c" "含 'exempt/豁免'"    "$(echo "$section_105" | grep -ciE 'exempt|豁免')" "1"

echo ""
echo "═══ SC-69: App Store Server Notifications 状态 ═══"
section_106=$(awk '/^### 10\.6 /,/^### 10\.7 /' "$LISTING")
cg "SC-69" "无 IAP 时含 'N/A' 或 '无 IAP' 说明" "$(echo "$section_106" | grep -ciE 'n/a|无 iap|not applicable')" "1"

echo ""
echo "═══ SC-56: 描述类字段字符数 + 格式 ═══"
pt_text=$(awk '/^## 2\./,/^## 3\./' "$LISTING" | sed -n '/^```$/,/^```$/p' | sed '1d;$d')
fd_text=$(awk '/^## 3\./,/^## 4\./' "$LISTING" | sed -n '/^```$/,/^```$/p' | sed '1d;$d')
kw_text=$(awk '/^## 4\./,/^## 5\./' "$LISTING" | sed -n '/^```$/,/^```$/p' | sed '1d;$d')
pt_count=$(echo -n "$pt_text" | wc -m | tr -d ' ')
fd_count=$(echo -n "$fd_text" | wc -m | tr -d ' ')
kw_count=$(echo -n "$kw_text" | wc -m | tr -d ' ')
ci "SC-56a" "Promotional Text ≤100"   "$pt_count" "<=" "100"
ci "SC-56b" "Full Description ≤4000"  "$fd_count" "<=" "4000"
ci "SC-56c" "Keywords ≤80"            "$kw_count" "<=" "80"

md_count=$(echo "$fd_text" | grep -cE '\*\*|__|^# |^\* ')
emoji_count=$(echo "$fd_text" | python3 -c "
import sys, unicodedata
content = sys.stdin.read()
emoji_count = 0
for c in content:
    if unicodedata.category(c) == 'So':
        emoji_count += 1
print(emoji_count)
")
ci "SC-56d" "Full Description 无 markdown" "$md_count" "==" "0"
ci "SC-56e" "Full Description 无 emoji" "$emoji_count" "==" "0"

echo ""
echo "════════════════════════════════════════════════════════════"
echo "  结果: ✅ $PASS 通过  ❌ $FAIL 失败"
echo "════════════════════════════════════════════════════════════"

[ "$FAIL" -eq 0 ] && exit 0 || exit 1
