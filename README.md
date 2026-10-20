# micanis dotfiles

macOS・Linux・NixOS の開発環境を、1 つの Nix flake で宣言的に管理する dotfiles。

- **4 つの構成** — macOS / Linux（GUI あり・なし）/ NixOS を同じモジュールから組み立てる
- **1 行で導入** — `curl | sh` で Nix の導入から構成の適用まで完了する
- **設定ファイルはそのまま** — 各アプリの設定は元の形式で `config/` に置き、Home Manager でリンクする
- **macOS も宣言的に** — `defaults`・Dock・Homebrew Cask・Mac App Store まで nix-darwin で管理する

## 目次

- [クイックスタート](#クイックスタート)
- [構成一覧](#構成一覧)
- [日常の操作](#日常の操作)
- [よくある変更の置き場所](#よくある変更の置き場所)
- [開発・検証](#開発検証)
- [フォルダ構成](#フォルダ構成)
- [ドキュメント](#ドキュメント)
- [バージョン](#バージョン)

## クイックスタート

必要なもの: macOS (Apple Silicon) または x86_64 Linux、`curl`。Nix・Homebrew・git は bootstrap が用意します。

```sh
curl -fsSL https://raw.githubusercontent.com/micanis/dotfiles/main/bootstrap/install.sh | sh
```

Linux ではプロファイルを引数で選べます（省略時は `linux-headless`）。

```sh
curl -fsSL https://raw.githubusercontent.com/micanis/dotfiles/main/bootstrap/install.sh | sh -s -- linux-gui
```

| 環境変数 | 既定値 | 用途 |
|---|---|---|
| `DOTFILES_DIR` | `~/.local/share/dotfiles` | clone 先 |
| `DOTFILES_REPO` | `https://github.com/micanis/dotfiles.git` | clone 元 |

<details>
<summary><b>macOS の初回だけ必要な作業</b> — <code>/etc/shells</code> の衝突</summary>

nix-darwin が `/etc/shells` を管理するため、初回の適用で既存ファイルと衝突した場合は退避してから再実行します。

```sh
sudo mv /etc/shells /etc/shells.before-nix-darwin
./bootstrap/darwin.sh
```

</details>

<details>
<summary><b>NixOS の初回だけ必要な作業</b> — ハードウェア設定の追加</summary>

`nixosConfigurations.nixos` はブートローダーやファイルシステムの設定を含んでいないため、このままでは評価に失敗します。実機で生成した `hardware-configuration.nix` を `hosts/nixos/` に追加し、import してください。

</details>

## 構成一覧

| 構成名 | 対象 | 仕組み |
|---|---|---|
| `darwinConfigurations.darwin` | macOS (Apple Silicon) | nix-darwin + Home Manager + Homebrew Cask |
| `homeConfigurations.linux-gui` | NixOS 以外の Linux デスクトップ | Home Manager (standalone) |
| `homeConfigurations.linux-headless` | NixOS 以外の Linux サーバー | Home Manager (standalone) |
| `nixosConfigurations.nixos` | NixOS | NixOS modules + Home Manager |

主なツール（全環境共通）: Nushell・Starship・Zellij・Helix・Yazi・lazygit・gh・direnv（nix-direnv）・ripgrep・fd・bat・eza・fzf など。macOS では加えて Ghostty・Karabiner-Elements・Claude Code・Codex を入れます。

## 日常の操作

設定を変更したら、リポジトリのルートで次を実行して反映します。

| 対象 | コマンド |
|---|---|
| macOS | `sudo darwin-rebuild switch --flake .#darwin` |
| Linux | `home-manager switch --flake .#linux-gui`（または `.#linux-headless`） |
| NixOS | `sudo nixos-rebuild switch --flake .#nixos` |

> **注意:** Nix flake は Git に登録されていないファイルを無視します。新しいファイルを追加したら、適用前に `git add` してください。

### 依存の更新

```sh
nix flake update            # すべての input を更新
nix flake update nixpkgs    # 特定の input だけ更新
```

<details>
<summary><b>Mac App Store のアプリを追加したとき</b> — <code>darwin-rebuild</code> ではなく <code>bootstrap/darwin.sh</code> で適用</summary>

`modules/darwin/apps.nix` の `masApps` にアプリを追加したら、`./bootstrap/darwin.sh` で適用します。

macOS 26.1 以降、App Store アプリのインストールには管理者権限が必要です。`darwin-rebuild` は途中でパスワードを聞けないため、未インストールのアプリがあると適用が失敗します。`bootstrap/darwin.sh` は先に `mas install` でアプリを入れて（ここでパスワードを聞きます）から `darwin-rebuild switch` を実行します。

アプリ ID は `mas search <名前>` で調べられます。

</details>

## よくある変更の置き場所

| やりたいこと | 編集するファイル |
|---|---|
| 全環境に CLI ツールを追加 | `modules/home/common/packages.nix` |
| macOS に GUI アプリを追加 | `modules/darwin/apps.nix`（Homebrew Cask / Mac App Store） |
| macOS のシステム設定を変更 | `modules/darwin/defaults.nix` |
| シェルのエイリアス・関数を追加 | `config/nushell/scripts/aliases.nu`・`functions.nu` |
| エディタやターミナルの設定 | `config/<アプリ名>/` |
| キー配列（Karabiner）を変更 | `config/karabiner/karabiner.json` |

## 開発・検証

```sh
nix develop                 # nixfmt / nil / statix / deadnix 入りのシェル
nixfmt $(git ls-files '*.nix')
nix build .#darwinConfigurations.darwin.system --dry-run
nix build .#homeConfigurations.linux-gui.activationPackage --dry-run
nix build .#homeConfigurations.linux-headless.activationPackage --dry-run
```

## フォルダ構成

```
├── flake.nix            入口。全構成と共通引数（username・homeDirectory など）を定義
├── bootstrap/           新しいマシンへの初回導入
│   ├── install.sh         curl | sh 用。Nix を入れて clone し、darwin.sh / linux.sh へ
│   ├── darwin.sh          Homebrew・App Store アプリを入れて darwin-rebuild switch
│   ├── linux.sh           Home Manager の activation package を実行
│   └── lib.sh             darwin.sh / linux.sh の共通関数
├── hosts/               構成ごとの入口。どのモジュールを使うかとホスト固有の値だけを書く
├── modules/
│   ├── home/            Home Manager（ユーザー環境）
│   │   ├── common/        全環境共通: CLI ツール、シェル、Git、SSH、エディタ
│   │   ├── darwin/        macOS 専用: Karabiner、Vivaldi、既定アプリ、AI エージェント
│   │   └── linux/         Linux 専用（gui.nix はデスクトップ向けの追加分）
│   ├── darwin/          nix-darwin（システム設定・defaults・Homebrew）
│   ├── nixos/           NixOS のシステム設定
│   └── home-manager.nix nix-darwin / NixOS に Home Manager を組み込む共通設定
├── config/              各アプリの設定ファイル本体（元の形式のまま）
└── docs/                設計と macOS 設定一覧
```

## ドキュメント

| ドキュメント | 内容 |
|---|---|
| [docs/architecture.md](docs/architecture.md) | 設計方針、責務の分担、構成の組み立て方、各ディレクトリのルール |
| [docs/darwin-settings.md](docs/darwin-settings.md) | nix-darwin / Home Manager で管理している macOS 設定の一覧（移行用チェックリスト） |

## バージョン

現在のバージョンは **v1.0.0** です。変更内容は git のタグとコミット履歴を参照してください。
