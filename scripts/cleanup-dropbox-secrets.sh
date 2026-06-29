#!/bin/sh
# Dropboxに保存した秘密鍵・認証情報を削除するスクリプト
# Mac移行完了後に必ず実行すること

DROPBOX_BASE="$HOME/Dropbox/mac-setup"

echo ""
echo "========================================================"
echo "  Dropbox秘密鍵クリーンアップスクリプト"
echo "========================================================"
echo ""
echo "以下のファイル・ディレクトリを削除します:"
echo "  - $DROPBOX_BASE/ssh-backup/"
echo "  - $DROPBOX_BASE/aws-backup/"
echo "  - $DROPBOX_BASE/dotfiles/.netrc"
echo ""
printf "本当に削除しますか? [y/N]: "
read -r answer
case "$answer" in
  [yY]|[yY][eE][sS]) ;;
  *)
    echo "中止しました。"
    exit 0
    ;;
esac
echo ""

deleted=0
skipped=0

remove_path() {
  target="$1"
  if [ -e "$target" ]; then
    rm -rf "$target"
    echo "[削除] $target"
    deleted=$((deleted + 1))
  else
    echo "[SKIP] $target (存在しません)"
    skipped=$((skipped + 1))
  fi
}

remove_path "$DROPBOX_BASE/ssh-backup"
remove_path "$DROPBOX_BASE/aws-backup"
remove_path "$DROPBOX_BASE/dotfiles/.netrc"

echo ""
echo "========================================================"
echo "  完了: 削除 ${deleted} 件 / スキップ ${skipped} 件"
echo "========================================================"
echo ""
echo "Dropboxの同期が完了するまで少し待ってから、"
echo "Dropbox上に秘密鍵が残っていないか確認してください。"
echo ""
