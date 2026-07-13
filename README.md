# Mac移行バックアップスクリプト

Mac移行時に、旧Macのdotfilesや設定ファイル・SSH鍵・AWS認証情報をDropboxへバックアップするスクリプト集です。
次回以降のMac移行でも再利用できるよう汎用的に作られています。

---

## 前提条件

- macOS（Appleシリコン推奨）
- zsh または bash
- Dropboxがインストール済みで同期中であること（`~/Dropbox/` が存在すること）

---

## ディレクトリ構成

```
mac-dotfiles/
├── README.md
└── scripts/
    ├── backup-to-dropbox.sh           # バックアップ実行スクリプト
    ├── detect-manual-apps.sh          # 手動インストールアプリの検出スクリプト
    └── cleanup-dropbox-secrets.sh     # 移行後の秘密鍵削除スクリプト
```

バックアップ先の構成:

```
~/Dropbox/mac-setup/
├── dotfiles/       # シェル設定・Git設定等
├── ssh-backup/     # SSH鍵・config（⚠️ 秘密鍵含む）
├── claude/         # Claude設定・MCP設定
├── aws-backup/     # AWS CLI認証情報（⚠️ 認証情報含む）
├── volta-versions.txt  # Voltaで管理しているNode等のバージョン一覧
├── manual-apps.txt      # Homebrew管理外の手動インストールアプリ一覧
└── brewfile-additions-candidate.txt  # Brewfile追記候補（cask名は推測）
```

---

## 使い方

### バックアップ実行

```sh
sh scripts/backup-to-dropbox.sh
```

実行前に警告メッセージと続行確認が表示されます。
`y` を入力すると各ファイルのコピーが始まり、最後に成功・スキップ件数のサマリーが表示されます。

### 手動インストールアプリの検出

`/Applications` 以下のアプリのうち、Homebrew Cask・MASのどちらでも管理されていない
「手動インストールアプリ」を洗い出します。Mac移行時に取りこぼしがちな
手動インストールアプリを特定するために使います。`backup-to-dropbox.sh` とは独立しており、
実行前後どちらのタイミングでも実行可能です。

```sh
sh scripts/detect-manual-apps.sh
```

検出結果は `~/Dropbox/mac-setup/manual-apps.txt` に保存されるほか、
Brewfileへの追記候補（`cask "xxx"` 形式）が `~/Dropbox/mac-setup/brewfile-additions-candidate.txt`
に出力されます。cask名はアプリ名からの機械的な推測のため、追記前に必ず
`brew search --cask <アプリ名>` で正式名称を確認してください。

### 移行後のクリーンアップ（秘密鍵削除）

新しいMacへの移行が完了したら、Dropboxに残った秘密鍵・認証情報を削除してください。

```sh
sh scripts/cleanup-dropbox-secrets.sh
```

削除対象:
- `~/Dropbox/mac-setup/ssh-backup/`
- `~/Dropbox/mac-setup/aws-backup/`
- `~/Dropbox/mac-setup/dotfiles/.netrc`

---

## バックアップ対象ファイル一覧

### dotfiles/

| コピー元 | コピー先 |
|---|---|
| `~/.zshrc` | `dotfiles/.zshrc` |
| `~/.zprofile` | `dotfiles/.zprofile` |
| `~/.bash_profile` | `dotfiles/.bash_profile` |
| `~/.gitconfig` | `dotfiles/.gitconfig` |
| `~/.gitignore_global` | `dotfiles/.gitignore_global` |
| `~/.gitflow_export` | `dotfiles/.gitflow_export` |
| `~/.netrc` | `dotfiles/.netrc` ⚠️ |

### ssh-backup/（⚠️ 秘密鍵含む）

| コピー元 | コピー先 |
|---|---|
| `~/.ssh/id_rsa` | `ssh-backup/id_rsa` |
| `~/.ssh/id_rsa.pub` | `ssh-backup/id_rsa.pub` |
| `~/.ssh/id_ed25519` | `ssh-backup/id_ed25519` |
| `~/.ssh/id_ed25519.pub` | `ssh-backup/id_ed25519.pub` |
| `~/.ssh/config` | `ssh-backup/config` |
| `~/.ssh/` 内のその他の鍵ファイル | `ssh-backup/` |

### claude/

| コピー元 | コピー先 |
|---|---|
| `~/Library/Application Support/Claude/claude_desktop_config.json` | `claude/claude_desktop_config.json` |
| `~/.claude.json` | `claude/.claude.json` |
| `~/.claude/` | `claude/claude-dir/` |

### aws-backup/（⚠️ 認証情報含む）

| コピー元 | コピー先 |
|---|---|
| `~/.aws/` | `aws-backup/` |

---

## 移行後の注意事項

> **⚠️ 重要**: SSH秘密鍵・AWS認証情報・.netrc はDropboxに平文で保存されます。
> 新しいMacへのセットアップが完了したら、**必ず** `cleanup-dropbox-secrets.sh` を実行してDropboxから削除してください。

- 削除後はDropboxの同期が完了したことを確認してください
- Dropbox Webコンソールでも残存ファイルがないか確認することを推奨します

---

## 次回Mac移行時の手順

詳細な移行手順は `mac-migration-checklist.md`（別管理）を参照してください。

大まかな流れ:

1. 旧Macで `backup-to-dropbox.sh` を実行
2. Dropboxの同期完了を確認
3. 新MacにDropboxをインストール・同期
4. `~/Dropbox/mac-setup/` から各ファイルを復元
5. Volta・Docker Desktop・各種アプリをインストール
6. 動作確認後、`cleanup-dropbox-secrets.sh` でDropboxの秘密鍵を削除
