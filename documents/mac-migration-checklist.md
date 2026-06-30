# Mac 移行・売却 完全チェックリスト
> 対象：フリーランスWeb制作者（WordPress / Docker / PhpStorm / Git）  
> 想定フロー：新Mac構築 → 並行運用（1〜2週間）→ 旧Mac初期化 → 売却

---

## 全体フロー

```
① 新Mac購入・クリーンインストール
         ↓
② 旧Macで「持ち出すもの」を整理・バックアップ
         ↓
③ 新Macに開発環境を構築
         ↓
④ 1〜2週間 並行運用（旧Macは電源を切らない）
         ↓
⑤ 取りこぼし確認・ライセンス移行の完了
         ↓
⑥ バックアップ最終確認
         ↓
⑦ 旧Mac初期化
         ↓
⑧ 売却
```

---

## Phase 1：旧Macで事前準備する（新Mac購入後すぐ）

### Homebrew 棚卸し

```bash
# インストール済み一覧を確認
brew list

# Brewfileとして書き出し（Dropboxに保存）
brew bundle dump --file=~/Dropbox/mac-setup/Brewfile
```

→ Brewfileを開いて、**不要なものを削除してから保存**する（クリーンインストールの利点を活かす）

---

### SSH鍵のバックアップ

```bash
# 鍵ファイルと構成を確認
ls -la ~/.ssh/
cat ~/.ssh/config

# Dropboxにコピー
mkdir -p ~/Dropbox/mac-setup/ssh-backup
cp ~/.ssh/id_rsa           ~/Dropbox/mac-setup/ssh-backup/
cp ~/.ssh/id_rsa.pub       ~/Dropbox/mac-setup/ssh-backup/
cp ~/.ssh/id_ed25519       ~/Dropbox/mac-setup/ssh-backup/
cp ~/.ssh/id_ed25519.pub   ~/Dropbox/mac-setup/ssh-backup/
cp ~/.ssh/config           ~/Dropbox/mac-setup/ssh-backup/
# その他の鍵ファイルも同様にコピー
```

> ⚠️ 新Macでの接続確認が完了したら、Dropbox上のssh-backupは必ず削除すること

---

### dotfiles のバックアップ

```bash
mkdir -p ~/Dropbox/mac-setup/dotfiles

# シェル設定
cp ~/.zshrc            ~/Dropbox/mac-setup/dotfiles/
cp ~/.zprofile         ~/Dropbox/mac-setup/dotfiles/
cp ~/.bash_profile     ~/Dropbox/mac-setup/dotfiles/  # ある場合

# Git設定
cp ~/.gitconfig        ~/Dropbox/mac-setup/dotfiles/
cp ~/.gitignore_global ~/Dropbox/mac-setup/dotfiles/
cp ~/.gitflow_export   ~/Dropbox/mac-setup/dotfiles/  # ある場合

# stCommitMsg（コミットメッセージテンプレート）
cp ~/.stCommitMsg      ~/Dropbox/mac-setup/dotfiles/  # ある場合
```

---

### Claude デスクトップ MCP設定のバックアップ

```bash
mkdir -p ~/Dropbox/mac-setup/claude

# MCP設定ファイル
cp ~/Library/Application\ Support/Claude/claude_desktop_config.json \
   ~/Dropbox/mac-setup/claude/

# .claude/ フォルダ（Claude Code設定等）
cp -r ~/.claude ~/Dropbox/mac-setup/claude/claude-dir

# .claude.json
cp ~/.claude.json ~/Dropbox/mac-setup/claude/
```

**新Macでの復元：**

```bash
# claude_desktop_config.json を配置
mkdir -p ~/Library/Application\ Support/Claude/
cp ~/Dropbox/mac-setup/claude/claude_desktop_config.json \
   ~/Library/Application\ Support/Claude/

# .claude/ フォルダを復元
cp -r ~/Dropbox/mac-setup/claude/claude-dir ~/.claude

# .claude.json を復元
cp ~/Dropbox/mac-setup/claude/.claude.json ~/
```

> Web経由のMCP（GitHub・freee等）はこれだけで動く。  
> ローカルMCP（GA4・Search Console等）はNode.js（Volta）が入っていれば動く。

---

### .aws のバックアップ（AWS CLI認証情報）

```bash
cp -r ~/.aws ~/Dropbox/mac-setup/aws-backup
```

**新Macでの復元：**

```bash
cp -r ~/Dropbox/mac-setup/aws-backup ~/.aws
chmod 600 ~/.aws/credentials
```

> ⚠️ 認証情報を含むため、移行完了後はDropboxのaws-backupを削除すること

---

### .netrc のバックアップ（サーバー認証情報）

```bash
cp ~/.netrc ~/Dropbox/mac-setup/netrc-backup
```

**新Macでの復元：**

```bash
cp ~/Dropbox/mac-setup/netrc-backup ~/.netrc
chmod 600 ~/.netrc
```

> ⚠️ パスワードが平文で書かれている。移行完了後は必ずDropboxから削除すること。  
> 記載されているサーバーのパスワードが現在も有効か確認しておくと安心。

---

### Volta のインストール済みバージョン確認

コピーではなく**再インストール**が推奨。

```bash
# 旧Macで確認：インストール済みバージョンをメモしておく
volta list

# プロジェクトごとの固定バージョンを確認
grep -r '"volta"' ~/projects/*/package.json 2>/dev/null
```

**新Macでの手順：**

```bash
# Voltaをインストール
curl https://get.volta.sh | bash

# 旧Macで確認したバージョンをインストール
volta install node@xx.x.x

# 確認
volta list
```

> Brewfileに `node` を含めている場合は競合に注意。  
> Voltaを使うなら Brewfile から `brew "node"` は除外する。

---

### PhpStorm 設定のエクスポート

Settings Sync を使用中 → 新Macでサインインするだけで完了（エクスポート不要）

Settings Sync を使っていない場合：
```
File → Manage IDE Settings → Export Settings
→ ~/Dropbox/mac-setup/phpstorm-settings.zip
```

---

### その他の確認事項

```bash
# /etc/hosts（ローカル開発用のホスト設定）
cat /etc/hosts

# crontab（定期実行の設定）
crontab -l

# プロジェクト内 .env ファイルの所在確認
find ~/Sites ~/dev ~/Documents -name ".env" 2>/dev/null
```

---

### macOS キーボードショートカットのスクリーンショット

```
システム設定 → キーボード → キーボードショートカット
```

→ よく使うカスタマイズ部分をスクリーンショットで撮影しておく  
（新Macでは都度再設定。並行運用中に気づいたものを設定していく）

---

## Phase 2：新Macのクリーンインストール構築手順

### Step 1：macOS 初期設定

- Apple IDでサインイン
- iCloud Drive・Keychain を有効化
- Touch ID を設定

---

### Step 2：Homebrew のインストール

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# PATHを通す（Appleシリコンは /opt/homebrew）
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
```

---

### Step 3：Brewfile から環境を復元

```bash
brew bundle install --file=~/Dropbox/mac-setup/Brewfile
```

**wp-env用途を踏まえた推奨 Brewfile 構成例：**

```ruby
brew "git"
# node は Volta で管理するなら除外する（競合するため）
brew "php"
brew "composer"
brew "wp-cli"

cask "docker"
cask "phpstorm"
cask "google-chrome"
cask "dropbox"
# 他、必要なものを追加
```

> ⚠️ Voltaを使う場合、Brewfileに `brew "node"` を含めると競合する。どちらかに統一すること。

---

### Step 4：Git 設定の復元

```bash
cp ~/Dropbox/mac-setup/dotfiles/.gitconfig ~/.gitconfig

# 内容確認
cat ~/.gitconfig
```

---

### Step 5：SSH鍵の引き継ぎ

```bash
# 鍵ファイルを配置
mkdir -p ~/.ssh
cp ~/Dropbox/mac-setup/ssh-backup/id_rsa          ~/.ssh/
cp ~/Dropbox/mac-setup/ssh-backup/id_rsa.pub      ~/.ssh/
cp ~/Dropbox/mac-setup/ssh-backup/id_ed25519      ~/.ssh/
cp ~/Dropbox/mac-setup/ssh-backup/id_ed25519.pub  ~/.ssh/
cp ~/Dropbox/mac-setup/ssh-backup/config          ~/.ssh/
# その他の鍵ファイルも同様

# パーミッション設定（必須）
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
chmod 600 ~/.ssh/config
# その他の秘密鍵も chmod 600

# ssh-agentに登録
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa
ssh-add ~/.ssh/id_ed25519

# ~/.ssh/config に以下を追加（Keychain連携）
# Host *
#   AddKeysToAgent yes
#   UseKeychain yes
```

---

### Step 6：SSH接続確認

configに記載されているHostを1件ずつ確認する。

```bash
# GitHub
ssh -T git@github.com

# その他のサーバー
ssh user@hostname

# 接続できない場合（id_rsa が拒否される場合）
ssh -vvv user@hostname 2>&1 | grep -i "rsa\|algorithm\|key"
```

> ⚠️ すべての接続確認が完了したら、Dropbox の ssh-backup フォルダを削除すること

```bash
# 旧Mac側でも実行
rm -rf ~/Dropbox/mac-setup/ssh-backup/
```

---

### Step 7：dotfiles の復元

```bash
cp ~/Dropbox/mac-setup/dotfiles/.zshrc ~/.zshrc
cp ~/Dropbox/mac-setup/dotfiles/.zprofile ~/.zprofile
cp ~/Dropbox/mac-setup/dotfiles/.gitignore_global ~/.gitignore_global
cp ~/Dropbox/mac-setup/dotfiles/.gitflow_export ~/.gitflow_export  # ある場合
source ~/.zshrc
```

---

### Step 7.5：Volta のインストール

```bash
# Voltaをインストール
curl https://get.volta.sh | bash

# 旧Macで確認したバージョンをインストール
volta install node@xx.x.x

# 確認
volta list
node --version
npm --version
```

---

### Step 7.6：Claude デスクトップ MCP設定の復元

Claude デスクトップアプリをインストール後：

```bash
# 設定ファイルを配置
mkdir -p ~/Library/Application\ Support/Claude/
cp ~/Dropbox/mac-setup/claude/claude_desktop_config.json \
   ~/Library/Application\ Support/Claude/

# .claude/ フォルダを復元
cp -r ~/Dropbox/mac-setup/claude/claude-dir ~/.claude

# .claude.json を復元
cp ~/Dropbox/mac-setup/claude/.claude.json ~/
```

Claude デスクトップを再起動して、MCPサーバーが認識されることを確認する。  
ローカルMCP（GA4・Search Console等）はVoltaのNode.jsが入っていれば動くはず。

---

### Step 7.7：.aws の復元

```bash
cp -r ~/Dropbox/mac-setup/aws-backup ~/.aws
chmod 600 ~/.aws/credentials

# 動作確認（AWS CLIが入っている場合）
aws sts get-caller-identity
```

復元確認後、Dropboxのバックアップを削除：

```bash
rm -rf ~/Dropbox/mac-setup/aws-backup
```

---

### Step 7.8：.netrc の復元

```bash
cp ~/Dropbox/mac-setup/netrc-backup ~/.netrc
chmod 600 ~/.netrc
```

復元確認後、Dropboxのバックアップを削除：

```bash
rm -rf ~/Dropbox/mac-setup/netrc-backup
```

---

### Step 8：Docker Desktop

1. Brewfileでインストール済みの場合はアプリを起動
2. ライセンス同意・初期設定
3. メモリ割り当てを確認（wp-env推奨：4GB以上）

```bash
# 動作確認
docker --version
docker compose version

# wp-envの動作確認
npm install -g @wordpress/env
mkdir ~/test-wp && cd ~/test-wp
wp-env start
```

---

### Step 9：PhpStorm

1. JetBrains アカウントでサインイン → ライセンス認証
2. Settings Sync でサインイン → 設定が自動復元される
3. プロジェクトを開いて動作確認

---

### Step 10：その他ツールの認証

| ツール | 対応 |
|--------|------|
| Adobe Creative Cloud | CCアプリをインストール → サインイン（旧Macは後でサインアウト） |
| Microsoft 365 | インストール → Microsoftアカウント認証 |
| Dropbox | インストール → サインイン・同期 |
| Google Drive | インストール → Googleアカウント認証 |
| Claude | claude.ai にログイン |
| ChatGPT | openai.com にログイン |

---

### Step 11：/etc/hosts の復元（必要な場合）

```bash
sudo vim /etc/hosts
# 旧Macで確認した内容をもとに追記
```

---

## Phase 3：並行運用期間（1〜2週間）の確認事項

新Macで実務を行いながら、以下を1件ずつ確認する。  
**旧Macを参照したくなった場面はメモしておく** → それが「取りこぼし」の発見につながる。

- [ ] GitHubへのpush/pullが正常に動く
- [ ] 各レンタルサーバーへのSSH接続が正常に動く
- [ ] wp-envが正常に起動する
- [ ] PhpStormでプロジェクトが開ける・補完が効く
- [ ] `.env` が必要なプロジェクトで環境変数が読める
- [ ] Homebrewで入れたツールが正常に動く
- [ ] Voltaで管理しているNodeバージョンが正常に動く
- [ ] Claude デスクトップのMCPサーバーが認識されている（Web系・ローカル系それぞれ）
- [ ] GA4・Search ConsoleなどのローカルMCPが正常に動く
- [ ] Adobe CCが起動する・ライセンスが通っている
- [ ] Microsoft 365が起動する
- [ ] Dropbox・Google Driveの同期が正常に動く
- [ ] ブラウザの拡張機能・ブックマークが揃っている

---

## Phase 4：旧Mac 売却前 最終チェックリスト

### 🔴 データ・設定の移行確認

- [ ] SSH鍵（`~/.ssh/`）を新Macにコピーし、接続確認済み
- [ ] `~/.ssh/config` を新Macに移行済み
- [ ] `~/.gitconfig` を移行済み
- [ ] `~/.gitignore_global` を移行済み
- [ ] `~/.zshrc` / `~/.zprofile` を移行済み
- [ ] Homebrew `Brewfile` を出力し、新Macで復元済み
- [ ] Volta を新Macにインストールし、必要なNodeバージョンを入れ直した
- [ ] Claude デスクトップの `claude_desktop_config.json` を移行済み
- [ ] Claude デスクトップのMCPサーバーが正常に動いている（Web系・ローカル系）
- [ ] `.aws/` を移行済み・Dropboxのバックアップを削除済み
- [ ] `.netrc` を移行済み・Dropboxのバックアップを削除済み
- [ ] PhpStorm の設定が新Macに反映されている（Settings Sync確認）
- [ ] `/etc/hosts` の内容を確認・移行済み
- [ ] プロジェクト内 `.env` ファイルの所在を確認済み
- [ ] Docker のボリューム・必要なイメージを移行済み（またはwp-envのため不要と判断済み）
- [ ] `crontab -l` を確認済み
- [ ] Dropbox の ssh-backup フォルダを削除済み

### 🟡 ライセンス・認証の解除

- [ ] Adobe Creative Cloud を旧Macでサインアウト済み
- [ ] Microsoft 365 の認証状況を確認済み
- [ ] iMessage をサインアウト済み（メッセージ → 設定 → iMessageをサインアウト）
- [ ] FaceTime をサインアウト済み

### 🟢 バックアップの最終確認

- [ ] Time Machine を手動実行済み（初期化直前）
- [ ] Dropbox の同期が完了している
- [ ] iCloud の同期が完了している
- [ ] Google Drive の同期が完了している
- [ ] 新Macで1〜2週間問題なく実務が回っている

---

## Phase 5：旧Mac 初期化手順（Appleシリコン）

**順序を守ること。**

### ① 初期化前の確認

```
appleid.apple.com → デバイス → 対象Macが表示されていることを確認
```

### ② 「すべてのコンテンツと設定を消去」を実行

```
システム設定 → 一般 → 転送またはリセット
→「すべてのコンテンツと設定を消去」
```

これ1つで以下がまとめて処理される：
- Apple IDのサインアウト
- 「探す（Find My）」の解除
- アクティベーションロックの解除
- ディスクの消去
- macOSの再インストール準備

### ③ 初期化後の確認

- Macが「こんにちは」画面で止まっていることを確認
- `appleid.apple.com` にログインし、デバイス一覧から消えていることを確認

---

## 補足：バックアップツールの役割分担

| ツール | 役割 |
|--------|------|
| Time Machine | システム全体の「最後の砦」。気づいていない取りこぼしへの保険 |
| Dropbox | プロジェクト・業務ファイルの引き継ぎメイン |
| iCloud | 書類・デスクトップの自動引き継ぎ |
| Google Drive | クライアント共有ファイル・アカウント再ログインで復元 |

> Time Machineのディスクは、初期化後1ヶ月程度は保管しておくこと。

---

## dotfiles 仕分け表（ホームディレクトリ）

今回のM3 Air → M5 Pro移行時に確認・判断したもの一覧。

| ファイル/フォルダ | 判断 | 理由・備考 |
|---|---|---|
| `.aws/` | ✅ 移行する | AWS CLI認証情報。Dropbox経由で移行後に削除 |
| `.bash_history` | ❌ 不要 | コマンド履歴。引き継ぐ意味なし |
| `.bash_profile` | ✅ 移行する | シェル設定。Dropbox経由でコピー |
| `.cache/` | ❌ 不要 | キャッシュ。新Macで自動生成される |
| `.cagent/` | ❌ 不要 | Dockerのイメージレイヤーキャッシュ。自動生成 |
| `.CFUserTextEncoding` | ❌ 不要 | macOSが自動生成するエンコード設定 |
| `.claude/` | ✅ 移行する | Claude Code設定。Dropbox経由でコピー |
| `.claude.json` | ✅ 移行する | Claude設定ファイル。Dropbox経由でコピー |
| `.claude.json.backup.*` | ❌ 不要 | バックアップファイル群。不要 |
| `.codex/` | ❌ 不要 | OpenAI Codex関連。試用品と思われる |
| `.composer/` | ❌ 不要 | Composerキャッシュ。再インストールで再生成 |
| `.config/cagent/` | ❌ 不要 | 初回起動フラグのみ |
| `.config/configstore/` | ❌ 不要 | npm等の更新通知キャッシュ |
| `.config/gh/` | ❌ 不要 | GitHub CLI設定。`gh auth login`で再設定可能 |
| `.config/git/` | ❌ 不要 | `~/.gitignore_global`と重複 |
| `.config/github-copilot/` | ❌ 不要 | Copilot認証DB。新環境で再認証 |
| `.config/iterm2/` | ❌ 不要 | デフォルト設定のみ。再インストールで十分 |
| `.config/jgit/` | ❌ 不要 | PhpStorm内蔵Gitで代替可能 |
| `.config/opencode/` | ❌ 不要 | 試用品と思われる |
| `.config/zed/` | ❌ 不要 | 普段使いでない |
| `.copilot/` | ❌ 不要 | セッション履歴・ログ。新環境で再認証 |
| `.cups/` | ❌ 不要 | 印刷設定キャッシュ。自動生成 |
| `.cursor/` | ❌ 不要 | 試用後未使用 |
| `.docker/` | ❌ 不要 | 認証情報なし（Keychain管理）。wp-env専用なら不要 |
| `.dropbox/` | ❌ 不要 | Dropbox内部設定。再インストールで再生成 |
| `.gemini/` | ❌ 不要 | 現在未使用。新環境で再インストール可能 |
| `.gitconfig` | ✅ 移行する | Gitグローバル設定。Dropbox経由でコピー |
| `.gitflow_export` | ✅ 移行する | git-flow設定。Dropbox経由でコピー |
| `.gitignore_global` | ✅ 移行する | グローバルgitignore。Dropbox経由でコピー |
| `.hgignore_global` | ❌ 不要 | Mercurial用。Git環境では不要 |
| `.htaccess` | ❌ 削除済み | 誤って残っていたもの |
| `.kiro/` | ❌ 不要 | 試用後未使用 |
| `.lesshst` | ❌ 不要 | lessコマンド履歴 |
| `.local/` | ❌ 不要 | AIエージェント自動生成。バイナリ・キャッシュのみ |
| `.netrc` | ✅ 移行する | サーバー認証情報（平文）。Dropbox経由で移行後に削除 |
| `.npm/` | ❌ 不要 | npmキャッシュ。再インストールで再生成 |
| `.pencil/` | ❌ 不要 | Pencilアプリ設定。未使用と思われる |
| `.profile` | ❌ 不要 | Voltaのパス設定のみ。`.zshrc`に上位互換の設定あり |
| `.ssh/` | ✅ 移行する | SSH鍵・config。Dropbox経由でコピー後にパーミッション設定 |
| `.stCommitMsg` | ❌ 不要 | 中身が空。SourceTreeが自動生成したもの |
| `.swiftpm/` | ❌ 不要 | Swift Package Manager。未使用 |
| `.v8flags.*.json` | ❌ 不要 | Node.js内部フラグキャッシュ。自動生成 |
| `.volta/` | ❌ 不要（再インストール） | バイナリ管理の仕組みが独特。`volta install`で再構築 |
| `.wget-hsts` | ❌ 不要 | wgetのHSTS履歴キャッシュ |
| `.wp-env/` | ❌ 不要 | wp-envキャッシュ。再起動で再生成 |
| `.zprofile` | ✅ 移行する | Homebrewのpathなどの起動設定。Dropbox経由でコピー |
| `.zsh_history` | ❌ 不要 | zshコマンド履歴 |
| `.zsh_sessions/` | ❌ 不要 | zshセッション履歴。自動生成 |
| `.zshrc` | ✅ 移行する | シェル設定・エイリアス。Dropbox経由でコピー |
| `.zshrc.sb-*` | ❌ 不要 | zshrcのバックアップ。不要 |

### 移行するものまとめ

| ファイル/フォルダ | 方法 |
|---|---|
| `.aws/` | Dropbox経由（移行後に削除） |
| `.bash_profile` | Dropbox経由 |
| `.claude/` | Dropbox経由 |
| `.claude.json` | Dropbox経由 |
| `.gitconfig` | Dropbox経由 |
| `.gitflow_export` | Dropbox経由 |
| `.gitignore_global` | Dropbox経由 |
| `.netrc` | Dropbox経由（移行後に削除） |
| `.ssh/` | Dropbox経由（移行後に削除） |
| `.zprofile` | Dropbox経由 |
| `.zshrc` | Dropbox経由 |
| `~/Library/Application Support/Claude/claude_desktop_config.json` | Dropbox経由 |
| Volta管理のNode | 再インストール（`volta install node@xx`） |

---

## 見落としがちな項目一覧

| 項目 | 確認ポイント |
|------|------------|
| `.env` ファイル | プロジェクト内に散在。Dropbox管理外のものに注意 |
| `/etc/hosts` | ローカル開発用のホスト設定 |
| `~/.zshrc` / `~/.zprofile` | エイリアス・PATH設定 |
| `~/.gitconfig` | Git グローバル設定 |
| `~/.gitignore_global` | グローバルgitignore |
| `~/.ssh/config` | ホスト別接続設定 |
| `claude_desktop_config.json` | MCPサーバー設定。Web系・ローカル系両方含む |
| `.aws/` | AWS CLI認証情報。平文のため移行後は削除 |
| `.netrc` | サーバー認証情報（平文）。存在を忘れがち |
| Volta管理のNodeバージョン | `volta list` で確認してから再インストール |
| `crontab` | 定期実行の設定 |
| Alfred Workflow | 設定・Workflowのバックアップ |
| Keychain | iCloud Keychainで引き継がれるが要確認 |
| ブラウザ拡張機能 | Chrome / Safariの設定と拡張 |
| ローカルDB | Docker外で動かしている場合はダンプ |
| APIキー | ローカルの設定ファイルに埋め込んでいるもの |
| キーボードショートカット | クリーンインストールでは引き継がれない。スクリーンショットを撮っておく |
