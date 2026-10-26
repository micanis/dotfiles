# micanis dotfiles

macOS・Linux・NixOS の開発環境を、1 つの Nix flake で宣言的に管理する dotfiles。

- **4 つの構成** — macOS / Linux（GUI あり・なし）/ NixOS を同じモジュールから組み立てる
- **1 行で導入** — `curl | sh` で Nix の導入から構成の適用まで完了する
- **設定ファイルはそのまま** — 各アプリの設定は元の形式で `config/` に置き、Home Manager でリンクする
- **macOS も宣言的に** — `defaults`・Dock・Homebrew Cask・Mac App Store まで nix-darwin で管理する
- **プロジェクトごとの開発環境** — 言語ランタイムは devbox + direnv。言語ごとの共通構成を plugin として配布する

## 目次

- [クイックスタート](#クイックスタート)
- [構成一覧](#構成一覧)
- [日常の操作](#日常の操作)
- [プロジェクトの開発環境](#プロジェクトの開発環境)
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

導入が終わったらターミナルを開き直します。macOS ではログインシェルが Nushell に変わり、[日常の操作](#日常の操作) の関数が使えるようになります（Linux では `nu` を起動して使います）。

<details>
<summary><b>macOS の初回だけ必要な作業</b> — <code>/etc/shells</code> の衝突、Raycast の登録</summary>

**`/etc/shells` の衝突**: nix-darwin が `/etc/shells` を管理するため、初回の適用で既存ファイルと衝突した場合は退避してから再実行します。

```sh
sudo mv /etc/shells /etc/shells.before-nix-darwin
cd ~/.local/share/dotfiles && ./bootstrap/darwin.sh
```

**Raycast の Script Command**: Raycast の Settings → Extensions → `+` → Add Script Directory で `~/.local/share/dotfiles/config/raycast/scripts` を登録します。ファイル選択ダイアログでは隠しフォルダが見えないので、⌘⇧G でパスを入力します。

</details>

<details>
<summary><b>NixOS の初回だけ必要な作業</b> — ハードウェア設定の追加</summary>

NixOS では `install.sh` を使いません（Linux と判定して standalone の Home Manager を適用してしまうため）。

1. リポジトリを `~/.local/share/dotfiles` に clone する
2. `nixosConfigurations.nixos` はブートローダーやファイルシステムの設定を含んでいないため、実機で生成した `hardware-configuration.nix` を `hosts/nixos/` に追加して import する
3. `sudo nixos-rebuild switch --flake .#nixos` を実行する（2 回目以降は `nix-apply`）

</details>

## 構成一覧

| 構成名 | 対象 | 仕組み |
|---|---|---|
| `darwinConfigurations.darwin` | macOS (Apple Silicon) | nix-darwin + Home Manager + Homebrew Cask |
| `homeConfigurations.linux-gui` | NixOS 以外の Linux デスクトップ | Home Manager (standalone) |
| `homeConfigurations.linux-headless` | NixOS 以外の Linux サーバー | Home Manager (standalone) |
| `nixosConfigurations.nixos` | NixOS | NixOS modules + Home Manager |

主なツール（全環境共通）: Nushell・Starship・Zellij・Helix・Yazi・lazygit・gh・devbox・direnv（nix-direnv）・ripgrep・fd・bat・eza・fzf など。macOS では加えて Ghostty・Karabiner-Elements・Raycast・Claude Code・Codex を入れます。

## 日常の操作

設定を変更したら、Nushell で次の関数を実行して反映します。どのディレクトリからでも実行できます。

| 関数 | やること |
|---|---|
| `nix-apply` | 設定を反映する。OS を判定し、macOS は `bootstrap/darwin.sh`、NixOS は `nixos-rebuild switch`、それ以外の Linux は `bootstrap/linux.sh` を実行 |
| `nix-update` | すべての input を最新にしてから `nix-apply` |
| `nix-clean` | 古い世代と、使われていない Nix store を削除 |

- **未追跡のファイル**: Nix flake は Git に登録されていないファイルを無視します。`nix-apply` は未追跡のファイルがあると `git add` するか聞きます
- **Linux（NixOS 以外）**: Home Manager のプロファイルを引数で渡します。省略すると `linux-headless` になるため、**GUI のマシンでは毎回 `nix-apply linux-gui` / `nix-update linux-gui` と指定してください**（忘れると Ghostty などの GUI 向け設定が外れます）
- **GitHub の利用制限**: `nix-update` は `gh auth token` のトークンを Nix に渡して、GitHub API の利用回数制限（認証なしだと 1 時間 60 回）を避けます。トークンはファイルに保存しません
- **Mac App Store のアプリ**: `masApps` に追加したアプリも `nix-apply` で入ります（途中でパスワードを聞かれます。理由は [docs/architecture.md の bootstrap](docs/architecture.md#bootstrap)）。アプリ ID は `nix run nixpkgs#mas -- search <名前>` で調べられます

<details>
<summary><b>関数を使わずに実行する</b> — リポジトリのルートで実行するコマンド</summary>

| 対象 | 反映 |
|---|---|
| macOS | `./bootstrap/darwin.sh`（App Store のアプリを追加していなければ `sudo darwin-rebuild switch --flake .#darwin` でも可） |
| Linux | `home-manager switch --flake .#linux-gui`（または `.#linux-headless`） |
| NixOS | `sudo nixos-rebuild switch --flake .#nixos` |

```sh
nix flake update            # すべての input を更新
nix flake update nixpkgs    # 特定の input だけ更新
```

</details>

## プロジェクトの開発環境

言語ランタイムや LSP はプロジェクトごとに devbox で用意し、direnv でディレクトリに入ったときに読み込みます。

プロジェクトのディレクトリで、Nushell で次を実行します（`go` の部分は `python`・`go`・`frontend` のどれか）。`devbox.json` と `.envrc` ができ、`direnv allow` まで済みます。

```nu
{packages: [], include: ["github:micanis/dotfiles?dir=devbox-plugin/go"]} | save -f devbox.json; devbox generate direnv
```

macOS では Raycast で `devbox: <言語>` を実行すると、このコマンドがクリップボードにコピーされます（Script Command の登録が必要。[macOS の初回だけ必要な作業](#クイックスタート) を参照）。

plugin の中身と運用ルールは [docs/architecture.md の開発環境](docs/architecture.md#開発環境) を参照してください。

## よくある変更の置き場所

| やりたいこと | 編集するファイル |
|---|---|
| 全環境に CLI ツールを追加 | `modules/home/common/packages.nix` |
| macOS に GUI アプリを追加 | `modules/darwin/apps.nix`（Homebrew Cask / Mac App Store） |
| macOS のシステム設定を変更 | `modules/darwin/defaults.nix` |
| シェルのエイリアス・関数を追加 | `config/nushell/scripts/aliases.nu`・`functions.nu` |
| エディタやターミナルの設定 | `config/<アプリ名>/` |
| キー配列（Karabiner）を変更 | `config/karabiner/karabiner.json` |
| エディタの LSP・フォーマッターを設定 | `config/helix/languages.toml`（LSP 本体の入れ方は [開発環境の運用ルール](docs/architecture.md#運用ルール)） |
| 言語ごとの開発環境を変更 | `devbox-plugin/<言語>/plugin.json`（push してから反映される） |
| Raycast のコマンドを追加 | `config/raycast/scripts/` |

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
│   │   ├── darwin/        macOS 専用: Ghostty の設定、Karabiner、Vivaldi、既定アプリ、AI エージェント
│   │   └── linux/         Linux 専用（gui.nix はデスクトップ向けの追加分）
│   ├── darwin/          nix-darwin（システム設定・defaults・Homebrew）
│   ├── nixos/           NixOS のシステム設定
│   └── home-manager.nix nix-darwin / NixOS に Home Manager を組み込む共通設定
├── config/              各アプリの設定ファイル本体（元の形式のまま）
├── devbox-plugin/       プロジェクトの devbox.json から include する言語ごとの plugin
└── docs/                設計と macOS 設定一覧
```

## ドキュメント

| ドキュメント | 内容 |
|---|---|
| [docs/architecture.md](docs/architecture.md) | 設計方針、責務の分担、構成の組み立て方、各ディレクトリのルール、開発環境（devbox plugin） |
| [docs/darwin-settings.md](docs/darwin-settings.md) | nix-darwin / Home Manager で管理している macOS 設定の一覧（移行用チェックリスト） |

## バージョン

現在のバージョンは **v1.0.0** です。変更内容は git のタグとコミット履歴を参照してください。
