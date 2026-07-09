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

# ── 線上驗證工具 ──────────────────────────────────
# GitHub Pages push 後不代表部署成功（部署可能卡在佇列），
# 所以一律實際抓線上頁面，和本地檔逐位元組比對。
BASE_URL="https://pure-bot-maker.github.io/ems-dashboard"

url_for() {
  case "$1" in
    "index.html")          echo "$BASE_URL/" ;;
    "ohca/index.html")     echo "$BASE_URL/ohca/" ;;
    "timeline/index.html") echo "$BASE_URL/timeline/" ;;
  esac
}

# verify_page <repo內路徑> <最多檢查次數>（每次間隔 15 秒）
verify_page() {
  local f="$1" tries="$2" url tmp i
  url=$(url_for "$f")
  tmp=$(mktemp)
  for (( i=1; i<=tries; i++ )); do
    if curl -fsSL "${url}?nocache=$(date +%s)" -o "$tmp" 2>/dev/null \
       && cmp -s "$tmp" "$f"; then
      rm -f "$tmp"
      echo "    ✅ $url 線上內容 = 本地最新版"
      return 0
    fi
    [ "$i" -lt "$tries" ] && sleep 15
  done
  rm -f "$tmp"
  echo "    ❌ $url 線上仍是舊內容（已檢查 $tries 次）"
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
  echo "ℹ️  沒有變更。順便檢查上次部署是否真的上線..."
  ALL_OK=1
  for f in "$EMS_DST" "$OHCA_DST" "$TIMELINE_DST"; do
    verify_page "$f" 1 || ALL_OK=0
  done
  echo ""
  echo "═══════════════════════════════════════════════"
  if [ $ALL_OK -eq 1 ]; then
    echo "  ✅ 沒有變更，且線上三頁都是最新版。"
  else
    echo "  ❌ 有頁面的線上內容和本地不一致！"
    echo "     上次的 GitHub Pages 部署可能卡住了。處理方式："
    echo "     1. 到 https://github.com/PURE-bot-maker/ems-dashboard/actions"
    echo "        看「pages build and deployment」是否卡在 queued"
    echo "     2. 或跟 Claude 說：「網頁部署沒成功，幫我檢查」"
  fi
  echo "═══════════════════════════════════════════════"
  [ $ALL_OK -eq 1 ] && exit 0 || exit 1
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

# ── 5. 驗證線上是否真的更新（最多約 5 分鐘）───────
echo ""
echo "⏳ 等待 GitHub Pages 部署並驗證線上內容..."
FAILED=0
for f in "${CHANGED[@]}"; do
  verify_page "$f" 20 || FAILED=1
done

echo ""
echo "═══════════════════════════════════════════════"
if [ $FAILED -eq 0 ]; then
  echo "  ✅ 更新完成，線上內容已驗證為最新版！"
else
  echo "  ❌ 已 push 但線上遲遲沒更新——"
  echo "     GitHub Pages 部署大概卡在佇列（2026-07-09 發生過）。"
  echo "     處理方式："
  echo "     1. 等 10 分鐘後再雙擊一次 update.command（會重新檢查）"
  echo "     2. 到 https://github.com/PURE-bot-maker/ems-dashboard/actions"
  echo "        看「pages build and deployment」是否卡在 queued"
  echo "     3. 或跟 Claude 說：「網頁部署沒成功，幫我檢查」"
fi
echo ""
echo "  🔗 線上網址："
echo "     · 救護儀表板：  https://pure-bot-maker.github.io/ems-dashboard/"
echo "     · OHCA Dashboard：https://pure-bot-maker.github.io/ems-dashboard/ohca/"
echo "     · 救護大事紀：  https://pure-bot-maker.github.io/ems-dashboard/timeline/"
echo ""
echo "  💡 瀏覽器看到舊版時，按 Cmd+Shift+R 強制重新載入。"
echo "═══════════════════════════════════════════════"
exit $FAILED
