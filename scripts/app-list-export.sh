#!/bin/sh
# /Applications のアプリのうち、Homebrew Cask・MAS どちらでも管理されていない
# 「手動インストールアプリ」を洗い出し、Dropbox に保存する。

set -e

DROPBOX_BASE="$HOME/Dropbox/mac-setup"
OUTPUT="$DROPBOX_BASE/app-inventory.txt"

mkdir -p "$DROPBOX_BASE"

echo "アプリインベントリを作成中..."

{
  echo "================================================================"
  echo "  アプリインベントリ"
  echo "  生成日時: $(date '+%Y-%m-%d %H:%M:%S')"
  echo "================================================================"
  echo ""

  # --- Homebrew Cask 管理アプリ ---
  echo "=== [1] Homebrew Cask 管理アプリ ==="
  if command -v brew >/dev/null 2>&1; then
    brew list --cask 2>/dev/null || echo "(caskアプリなし)"
  else
    echo "(Homebrewがインストールされていません)"
  fi
  echo ""

  # --- MAS 管理アプリ ---
  echo "=== [2] Mac App Store 管理アプリ ==="
  if command -v mas >/dev/null 2>&1; then
    mas list 2>/dev/null || echo "(MASアプリなし)"
  else
    echo "(mas がインストールされていません)"
    echo "  → brew install mas を実行後、再度このスクリプトを実行してください"
  fi
  echo ""

  # --- 手動インストールアプリの洗い出し ---
  echo "=== [3] 手動インストールアプリ（要確認・新Macでは MAS/Cask への移行を検討） ==="

  # Cask 管理アプリ名の正規化リストを構築
  # brew list --cask の出力はパッケージ名（例: google-chrome）のみ
  # /Applications の .app 名（例: Google Chrome.app）と突き合わせるために
  # cask のインストール先ディレクトリ情報を利用する
  cask_apps=""
  if command -v brew >/dev/null 2>&1; then
    for cask in $(brew list --cask 2>/dev/null); do
      # brew info --cask で実際の .app 名を取得
      app_name=$(brew info --cask "$cask" 2>/dev/null \
        | grep -E '\.app' \
        | grep -oE '[^/]+\.app' \
        | head -1)
      if [ -n "$app_name" ]; then
        cask_apps="$cask_apps
$app_name"
      fi
    done
  fi

  # MAS 管理アプリ名リストを構築（"id  アプリ名  (バージョン)" 形式から抽出）
  mas_apps=""
  if command -v mas >/dev/null 2>&1; then
    mas_apps=$(mas list 2>/dev/null | awk '{$1=""; $NF=""; sub(/^[[:space:]]+/,""); sub(/[[:space:]]+$/,""); print}' || true)
  fi

  # /Applications 内の .app を走査して未管理のものを出力
  # find で2階層分（直下 + サブフォルダ内）を再帰的に走査する
  unmanaged_list=$(mktemp)
  find /Applications -maxdepth 2 -name "*.app" -type d | while IFS= read -r app_path; do
    app_name=$(basename "$app_path")
    app_base="${app_name%.app}"

    # Cask管理かチェック（完全一致）
    if echo "$cask_apps" | grep -qFx "$app_name"; then
      continue
    fi

    # MAS管理かチェック（アプリ名の完全一致）
    if echo "$mas_apps" | grep -qFx "$app_base"; then
      continue
    fi

    echo "  - $app_base"
  done > "$unmanaged_list"
  cat "$unmanaged_list"

  if [ ! -s "$unmanaged_list" ]; then
    echo "  (手動インストールアプリは見つかりませんでした)"
  fi
  rm -f "$unmanaged_list"

  echo ""
  echo "================================================================"
  echo "  新Macでの対応方針（手動インストールアプリについて）"
  echo "================================================================"
  echo ""
  echo "  各アプリについて以下の順で確認し、できる限り MAS/Cask 管理に移行する:"
  echo ""
  echo "  ① mas search <アプリ名>          → MASにあれば: mas install <id>"
  echo "  ② brew search --cask <アプリ名>  → Caskにあれば: brew install --cask <アプリ名>"
  echo "  ③ 上記になければ: 公式サイトから手動インストール"
  echo ""
  echo "  新Macで ① または ② でインストールできたアプリは"
  echo "  Brewfile に追記しておくと、次回以降の移行で自動化できる。"
  echo ""
  echo "  Brewfile への追記例:"
  echo "    cask \"アプリ名\"           # Homebrew Cask の場合"
  echo "    mas \"アプリ名\", id: 12345 # Mac App Store の場合"

} > "$OUTPUT"

echo "[OK] $OUTPUT に保存しました"
echo ""
echo "次のステップ："
echo "  1. $OUTPUT を開いて [3] の手動インストールアプリを確認する"
echo "  2. mas がインストールされていなければ: brew install mas"
echo "  3. 各アプリについて MAS/Cask への移行可否を調べる"
