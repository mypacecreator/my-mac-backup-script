#!/bin/sh
# /Applications 以下のアプリのうち、Homebrew Cask・MAS どちらでも管理されていない
# 「手動インストールアプリ」を検出し、一覧化する。
# backup-to-dropbox.sh とは独立しており、移行の前後どちらでも実行可能。

set -e

DROPBOX_BASE="$HOME/Dropbox/mac-setup"
OUTPUT="$DROPBOX_BASE/manual-apps.txt"
BREWFILE_CANDIDATE="$DROPBOX_BASE/brewfile-additions-candidate.txt"

mkdir -p "$DROPBOX_BASE"

# アプリ名を緩く正規化する（小文字化 + 英数字以外を除去）
# 例: "Google Chrome" と cask名 "google-chrome" を "googlechrome" として一致させる
normalize() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]//g'
}

# --- 1. Homebrew Cask 管理アプリ（正規化済みリスト） ---
cask_normalized=""
if command -v brew >/dev/null 2>&1; then
  for cask in $(brew list --cask 2>/dev/null); do
    cask_normalized="$(printf '%s\n%s' "$cask_normalized" "$(normalize "$cask")")"
  done
fi

# --- 2. MAS 管理アプリ（正規化済みリスト） ---
mas_normalized=""
if command -v mas >/dev/null 2>&1; then
  mas_apps=$(mas list 2>/dev/null | awk '{$1=""; $NF=""; sub(/^[[:space:]]+/,""); sub(/[[:space:]]+$/,""); print}' || true)
  while IFS= read -r name; do
    [ -n "$name" ] || continue
    mas_normalized="$(printf '%s\n%s' "$mas_normalized" "$(normalize "$name")")"
  done <<MASEOF
$mas_apps
MASEOF
fi

# --- 3. macOS標準アプリ（/System/Applications 以下）は比較対象から除外 ---
system_apps=""
if [ -d /System/Applications ]; then
  system_apps=$(find /System/Applications -maxdepth 2 -name "*.app" -exec basename {} \;)
fi

# --- 4. /Applications を走査し、Cask・MAS いずれにも一致しないものを抽出 ---
manual_list=$(mktemp -t detect-manual-apps)
trap 'rm -f "$manual_list"' EXIT

find /Applications -maxdepth 2 -name "*.app" -type d | while IFS= read -r app_path; do
  app_name=$(basename "$app_path")
  app_base="${app_name%.app}"

  # macOS標準アプリは除外
  if echo "$system_apps" | grep -qFx "$app_name"; then
    continue
  fi

  app_normalized=$(normalize "$app_base")

  # Homebrew Cask 管理下かチェック（緩い一致）
  if echo "$cask_normalized" | grep -qFx "$app_normalized"; then
    continue
  fi

  # MAS 管理下かチェック（緩い一致）
  if echo "$mas_normalized" | grep -qFx "$app_normalized"; then
    continue
  fi

  echo "$app_base"
done | sort > "$manual_list"

count=$(wc -l < "$manual_list" | tr -d ' ')

# --- 5. 出力（ターミナル表示 + ファイル保存） ---
{
  echo "=== Homebrew管理外のアプリケーション一覧 ==="
  cat "$manual_list"
  echo ""
  echo "検出件数: ${count}件"
} | tee "$OUTPUT"

echo "出力先: $OUTPUT"
echo ""

# --- 6. Brewfile追記候補（cask名はアプリ名からの推測のため要確認） ---
{
  echo "# Homebrew Cask 追記候補（自動生成）"
  echo "# 生成日時: $(date '+%Y-%m-%d %H:%M:%S')"
  echo "#"
  echo "# 注意: cask名はアプリ名から機械的に推測したものであり、正確とは限りません。"
  echo "#       Brewfileに追記する前に、必ず以下で正式なcask名を確認してください。"
  echo "#         brew search --cask <アプリ名>"
  echo ""
  while IFS= read -r app_base; do
    [ -n "$app_base" ] || continue
    guess=$(echo "$app_base" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
    echo "cask \"$guess\"  # 元アプリ名: $app_base"
  done < "$manual_list"
} > "$BREWFILE_CANDIDATE"

echo "Brewfile追記候補: $BREWFILE_CANDIDATE"

rm -f "$manual_list"
