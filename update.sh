#!/bin/bash
# ─────────────────────────────────────────────────────────────
# 儀表板一鍵更新腳本（管理三個頁面）
#   1) 救護儀表板 (EMS)         → /index.html
#   2) OHCA Dashboard v6        → /ohca/index.html
#   3) 救護大事紀 (Timeline)    → /timeline/index.html
#
# 自動偵測哪個來源檔案有變更，只更新有變更的；
# 然後 commit + push 一次推上 GitHub。
#
# 使用方式：
#   方法 1：終端機  bash update.sh
#   方法 2：Finder  雙擊 update.command
# ─────────────────────────────────────────────────────────────

set -e
cd "$(dirname "$0")"

EMS_SRC="../救護儀表板.html"
EMS_DST="index.html"
OHCA_SRC="../taiwan_ohca_dashboard_v6.html"
OHCA_DST="ohca/index.html"
TIMELINE_SRC="../救護大事紀.html"
TIMELINE_DST="timeline/index.html"

echo "═══════════════════════════════════════════════"
echo "  📊 儀表板更新流程"
echo "═══════════════════════════════════════════════"

# 偵測檔案是否有變更（含新檔）
has_changed() {
  local f="$1"
  # 檔案不在 git 索引中（新檔）→ 有變更
  if ! git ls-files --error-unmatch "$f" > /dev/null 2>&1; then
    return 0
  fi
  # 已追蹤但內容有 diff → 有變更
  if ! git diff --quiet "$f"; then
    return 0
  fi
  return 1
}

CHANGED=()

# ── 1. 救護儀表板 ─────────────────────────────────
echo ""
echo "📋 [1/3] 救護儀表板 (EMS)"
if [ -f "$EMS_SRC" ]; then
  cp "$EMS_SRC" "$EMS_DST"
  if has_changed "$EMS_DST"; then
    SIZE=$(ls -lh "$EMS_DST" | awk '{print $5}')
    echo "    ✓ 已更新 ($SIZE)"
    CHANGED+=("$EMS_DST")
  else
    echo "    ℹ️  無變更"
  fi
else
  echo "    ⚠️  找不到來源 $EMS_SRC，跳過"
fi

# ── 2. OHCA Dashboard ─────────────────────────────
echo ""
echo "📋 [2/3] OHCA Dashboard"
if [ -f "$OHCA_SRC" ]; then
  cp "$OHCA_SRC" "$OHCA_DST"
  if has_changed "$OHCA_DST"; then
    SIZE=$(ls -lh "$OHCA_DST" | awk '{print $5}')
    echo "    ✓ 已更新 ($SIZE)"
    CHANGED+=("$OHCA_DST")
  else
    echo "    ℹ️  無變更"
  fi
else
  echo "    ⚠️  找不到來源 $OHCA_SRC，跳過"
fi

# ── 3. 救護大事紀 ─────────────────────────────────
echo ""
echo "📋 [3/3] 救護大事紀 (Timeline)"
if [ -f "$TIMELINE_SRC" ]; then
  mkdir -p "$(dirname "$TIMELINE_DST")"
  cp "$TIMELINE_SRC" "$TIMELINE_DST"
  if has_changed "$TIMELINE_DST"; then
    SIZE=$(ls -lh "$TIMELINE_DST" | awk '{print $5}')
    echo "    ✓ 已更新 ($SIZE)"
    CHANGED+=("$TIMELINE_DST")
  else
    echo "    ℹ️  無變更"
  fi
else
  echo "    ⚠️  找不到來源 $TIMELINE_SRC，跳過"
fi

# ── 4. Commit + Push（若有變更）───────────────────
if [ ${#CHANGED[@]} -eq 0 ]; then
  echo ""
  echo "═══════════════════════════════════════════════"
  echo "  ℹ️  沒有變更，無需更新。"
  echo "═══════════════════════════════════════════════"
  exit 0
fi

echo ""
echo "💾 建立 commit"
git add "${CHANGED[@]}"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M")
MSG="Update dashboards — $TIMESTAMP"
git commit -m "$MSG" | tail -3

echo ""
echo "🚀 推送到 GitHub"
git push 2>&1 | tail -5

echo ""
echo "═══════════════════════════════════════════════"
echo "  ✅ 更新完成！"
echo ""
echo "  🔗 線上網址："
echo "     · 救護儀表板：  https://pure-bot-maker.github.io/ems-dashboard/"
echo "     · OHCA Dashboard：https://pure-bot-maker.github.io/ems-dashboard/ohca/"
echo "     · 救護大事紀：  https://pure-bot-maker.github.io/ems-dashboard/timeline/"
echo ""
echo "  ⏳ GitHub Pages 約需 1–2 分鐘才會反映新版本，"
echo "     重新整理瀏覽器時請按 Cmd+Shift+R 強制重新載入。"
echo "═══════════════════════════════════════════════"
