#!/bin/bash
# ─────────────────────────────────────────────────────────────
# 救護儀表板一鍵更新腳本
# 把上層目錄的「救護儀表板.html」複製成 index.html，
# 然後 commit + push 到 GitHub，自動觸發 GitHub Pages 重新部署。
#
# 使用方式：
#   方法 1：終端機執行  bash update.sh
#   方法 2：在 Finder 雙擊 update.command（macOS 會自動開終端機跑）
# ─────────────────────────────────────────────────────────────

set -e  # 任一指令失敗就停止

# 切到腳本所在目錄（無論從哪呼叫都能正確運作）
cd "$(dirname "$0")"

SRC="../救護儀表板.html"
DST="index.html"

echo "═══════════════════════════════════════════════"
echo "  📊 救護儀表板更新流程"
echo "═══════════════════════════════════════════════"

# 1. 檢查來源檔案存在
if [ ! -f "$SRC" ]; then
  echo "❌ 找不到來源檔案：$SRC"
  echo "   請確認「救護儀表板.html」位於上層目錄"
  exit 1
fi

# 2. 複製
echo ""
echo "📋 [1/4] 複製檔案 $SRC → $DST"
cp "$SRC" "$DST"
SIZE=$(ls -lh "$DST" | awk '{print $5}')
echo "    ✓ 大小：$SIZE"

# 3. 檢查有沒有變更
echo ""
echo "🔍 [2/4] 檢查變更"
if git diff --quiet "$DST"; then
  echo "    ℹ️  index.html 沒有變更，無需更新。"
  exit 0
fi
echo "    ✓ 偵測到變更"

# 4. Commit
echo ""
echo "💾 [3/4] 建立 commit"
git add "$DST"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M")
git commit -m "Update dashboard — $TIMESTAMP" | tail -3

# 5. Push
echo ""
echo "🚀 [4/4] 推送到 GitHub"
git push 2>&1 | tail -5

# 6. 完成提示
echo ""
echo "═══════════════════════════════════════════════"
echo "  ✅ 更新完成！"
echo ""
echo "  🔗 線上網址："
echo "     https://pure-bot-maker.github.io/ems-dashboard/"
echo ""
echo "  ⏳ GitHub Pages 約需 1–2 分鐘才會反映新版本，"
echo "     重新整理瀏覽器時請按 Cmd+Shift+R 強制重新載入。"
echo "═══════════════════════════════════════════════"
