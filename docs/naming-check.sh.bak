#!/bin/bash
# SC-58: Project naming three-layer consistency check
# Run from project root after any rename.
# Companion to SOP §1.2.3 / HR-76 / SC-58.

set -e

PROJ_DIR="${1:-.}"
cd "$PROJ_DIR" || { echo "❌ Cannot cd to $PROJ_DIR"; exit 1; }

echo "=== Display Name (Info.plist) ==="
if [ -f "Sources/Info.plist" ]; then
  /usr/libexec/PlistBuddy -c "Print :CFBundleDisplayName" Sources/Info.plist
else
  echo "❌ Sources/Info.plist not found"
  exit 1
fi

echo "=== Bundle ID (project.yml) ==="
grep "PRODUCT_BUNDLE_IDENTIFIER:" project.yml | head -1

echo "=== xcodeproj name (Xcode) ==="
ls -d *.xcodeproj 2>/dev/null || echo "❌ No .xcodeproj found"

echo "=== Folder name ==="
basename "$(pwd)"

echo "=== GitHub remote ==="
git remote get-url origin 2>/dev/null || echo "❌ No git remote"

echo ""
echo "=== Self-Check Guidance (per SOP §1.2.3) ==="
echo "Compare output with the project's three-layer mapping table in project.yml top."
echo "Expected VitaMindGo example:"
echo "  Display Name:    VitaMindGo"
echo "  Bundle ID:       com.ggsheng.VitaMind  (legacy, MUST NOT change)"
echo "  xcodeproj:       VitaMindGo.xcodeproj"
echo "  folder:          ios-VitaMind         (intentionally kept, avoids git mv risk)"
echo "  remote:          https://github.com/<owner>/ios-VitaMindGo.git"
echo ""
echo "  Note: folder name NOT required to match repo URL. git remote URL"
echo "        is the authoritative source. Folder can stay for git history"
echo "        continuity (per SOP §1.2.3 decision tree)."
