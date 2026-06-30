#!/bin/sh
# Mac移行用バックアップスクリプト
# dotfiles・SSH鍵・Claude設定・AWS認証情報をDropboxへコピーする

set -e

DROPBOX_BASE="$HOME/Dropbox/mac-setup"
SUCCESS=0
SKIP=0

# ============================================================
# ヘルパー関数
# ============================================================

copy_file() {
  src="$1"
  dst="$2"
  if [ ! -e "$src" ]; then
    echo "[SKIP] $src (存在しません)"
    SKIP=$((SKIP + 1))
    return
  fi
  dst_dir=$(dirname "$dst")
  mkdir -p "$dst_dir"
  cp "$src" "$dst"
  echo "[OK]   $src -> $dst"
  SUCCESS=$((SUCCESS + 1))
}

copy_dir() {
  src="$1"
  dst="$2"
  if [ ! -d "$src" ]; then
    echo "[SKIP] $src (ディレクトリが存在しません)"
    SKIP=$((SKIP + 1))
    return
  fi
  mkdir -p "$dst"
  cp -r "$src/." "$dst/"
  echo "[OK]   $src/ -> $dst/"
  SUCCESS=$((SUCCESS + 1))
}

# ============================================================
# 警告・確認
# ============================================================

echo ""
echo "========================================================"
echo "  Mac移行バックアップスクリプト"
echo "========================================================"
echo ""
echo "⚠️  警告: SSH秘密鍵・AWS認証情報・.netrc をDropboxにコピーします。"
echo "   移行完了後は必ず cleanup-dropbox-secrets.sh で削除してください。"
echo ""
printf "続行しますか? [y/N]: "
read -r answer
case "$answer" in
  [yY]|[yY][eE][sS]) ;;
  *)
    echo "中止しました。"
    exit 0
    ;;
esac
echo ""

# ============================================================
# 1. dotfiles/
# ============================================================

echo "--- dotfiles -----------------------------------------"
copy_file "$HOME/.zshrc"           "$DROPBOX_BASE/dotfiles/.zshrc"
copy_file "$HOME/.zprofile"        "$DROPBOX_BASE/dotfiles/.zprofile"
copy_file "$HOME/.bash_profile"    "$DROPBOX_BASE/dotfiles/.bash_profile"
copy_file "$HOME/.gitconfig"       "$DROPBOX_BASE/dotfiles/.gitconfig"
copy_file "$HOME/.gitignore_global" "$DROPBOX_BASE/dotfiles/.gitignore_global"
copy_file "$HOME/.gitflow_export"  "$DROPBOX_BASE/dotfiles/.gitflow_export"
copy_file "$HOME/.netrc"           "$DROPBOX_BASE/dotfiles/.netrc"
echo ""

# ============================================================
# 2. ssh-backup/（秘密鍵含む）
# ============================================================

echo "--- ssh-backup ---------------------------------------"
copy_file "$HOME/.ssh/id_rsa"         "$DROPBOX_BASE/ssh-backup/id_rsa"
copy_file "$HOME/.ssh/id_rsa.pub"     "$DROPBOX_BASE/ssh-backup/id_rsa.pub"
copy_file "$HOME/.ssh/id_ed25519"     "$DROPBOX_BASE/ssh-backup/id_ed25519"
copy_file "$HOME/.ssh/id_ed25519.pub" "$DROPBOX_BASE/ssh-backup/id_ed25519.pub"
copy_file "$HOME/.ssh/config"         "$DROPBOX_BASE/ssh-backup/config"

# ~/.ssh/ 内のその他の鍵ファイル（上記以外）
if [ -d "$HOME/.ssh" ]; then
  for f in "$HOME/.ssh/"*; do
    base=$(basename "$f")
    case "$base" in
      id_rsa|id_rsa.pub|id_ed25519|id_ed25519.pub|config|known_hosts|authorized_keys)
        # 上でコピー済み or 不要なファイル
        continue
        ;;
      *.pub)
        # その他の公開鍵はコピー
        copy_file "$f" "$DROPBOX_BASE/ssh-backup/$base"
        ;;
      id_*)
        # その他の秘密鍵はコピー
        copy_file "$f" "$DROPBOX_BASE/ssh-backup/$base"
        ;;
    esac
  done
fi
echo ""

# ============================================================
# 3. claude/
# ============================================================

echo "--- claude -------------------------------------------"
copy_dir  "$HOME/Library/Application Support/Claude" "$DROPBOX_BASE/claude/app-support"
copy_file "$HOME/.claude.json"  "$DROPBOX_BASE/claude/.claude.json"
copy_dir  "$HOME/.claude"       "$DROPBOX_BASE/claude/claude-dir"
echo ""

# ============================================================
# 4. aws-backup/（認証情報含む）
# ============================================================

echo "--- aws-backup ---------------------------------------"
copy_dir "$HOME/.aws" "$DROPBOX_BASE/aws-backup"
echo ""

# ============================================================
# Brewfile生成
# ============================================================

echo "--- Homebrew -----------------------------------------"
if command -v brew >/dev/null 2>&1; then
  mkdir -p "$DROPBOX_BASE"
  brew bundle dump --file="$DROPBOX_BASE/Brewfile" --force
  echo "[OK]   brew bundle dump -> $DROPBOX_BASE/Brewfile"
  SUCCESS=$((SUCCESS + 1))
else
  echo "[SKIP] Homebrewがインストールされていません"
  SKIP=$((SKIP + 1))
fi
echo ""

# ============================================================
# MASアプリ一覧記録
# ============================================================

echo "--- Mac App Store (mas) ------------------------------"
if command -v mas >/dev/null 2>&1; then
  mkdir -p "$DROPBOX_BASE"
  mas list > "$DROPBOX_BASE/mas-list.txt" 2>&1
  echo "[OK]   mas list -> $DROPBOX_BASE/mas-list.txt"
  SUCCESS=$((SUCCESS + 1))
else
  echo "[SKIP] mas がインストールされていません（brew install mas で導入可能）"
  SKIP=$((SKIP + 1))
fi
echo ""

# ============================================================
# Voltaバージョン記録
# ============================================================

echo "--- Volta --------------------------------------------"
if command -v volta >/dev/null 2>&1; then
  mkdir -p "$DROPBOX_BASE"
  volta list > "$DROPBOX_BASE/volta-versions.txt" 2>&1
  echo "[OK]   volta list -> $DROPBOX_BASE/volta-versions.txt"
  SUCCESS=$((SUCCESS + 1))
else
  echo "[SKIP] Voltaがインストールされていません"
  SKIP=$((SKIP + 1))
fi
echo ""

# ============================================================
# サマリー
# ============================================================

echo "========================================================"
echo "  完了: 成功 ${SUCCESS} 件 / スキップ ${SKIP} 件"
echo "========================================================"
echo ""
echo "⚠️  移行完了後は必ず以下を実行してDropboxから秘密鍵を削除してください:"
echo "   sh scripts/cleanup-dropbox-secrets.sh"
echo ""
