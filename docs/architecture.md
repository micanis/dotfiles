# 設計

複数の OS・ホストの開発環境を Nix で宣言的に管理し、新しいマシンでも 1 コマンドで同じ環境を再現するための設計メモ。

対象は macOS、Linux（GUI あり・なし）、NixOS の 4 種類です。

## 目次

- [責務の分担](#責務の分担)
- [構成の組み立て](#構成の組み立て)
- [各ディレクトリのルール](#各ディレクトリのルール)
- [bootstrap](#bootstrap)
- [開発環境](#開発環境)
- [今後の課題](#今後の課題)

## 責務の分担

| 責務 | 担当 | 置き場所 |
|---|---|---|
| macOS のシステム設定 | nix-darwin | `modules/darwin/` |
| NixOS のシステム設定 | NixOS modules | `modules/nixos/` |
| ユーザー環境（CLI・シェル・dotfiles） | Home Manager | `modules/home/` |
| macOS の GUI アプリ | Homebrew Cask / Mac App Store（nix-darwin 経由） | `modules/darwin/apps.nix` |
| アプリの設定ファイル本体 | 元の形式のまま保存 | `config/` |
| プロジェクトごとの開発環境 | devbox + direnv（言語ごとの plugin は `devbox-plugin/`） | 各プロジェクト |
| 初回導入 | bootstrap スクリプト | `bootstrap/` |

## 構成の組み立て

`flake.nix` が構成ごとに `hosts/` の入口を読み込み、入口がモジュールを選びます。

```text
flake.nix
├── darwinConfigurations.darwin       → hosts/darwin/default.nix
│     system: modules/darwin + modules/home-manager.nix
│     home:   modules/home/common + modules/home/darwin
├── nixosConfigurations.nixos         → hosts/nixos/configuration.nix
│     system: modules/nixos + modules/home-manager.nix
│     home:   modules/home/common + modules/home/linux
├── homeConfigurations.linux-gui      → hosts/linux-gui/home.nix
│     home:   modules/home/common + modules/home/linux + modules/home/linux/gui.nix
└── homeConfigurations.linux-headless → hosts/linux-headless/home.nix
      home:   modules/home/common + modules/home/linux
```

### 共通引数

`flake.nix` は次の値を全モジュールの引数として渡します（system 側は `specialArgs`、Home Manager 側は `extraSpecialArgs`）。

| 引数 | 内容 |
|---|---|
| `inputs` | flake の input（`llm-agents` など nixpkgs 以外のパッケージ取得に使う） |
| `username` | `micanis` |
| `homeDirectory` | macOS は `/Users/micanis`、Linux は `/home/micanis` |
| `homeStateVersion` | Home Manager の `home.stateVersion` |

`home.username`・`home.homeDirectory`・`home.stateVersion` はこれらを使って `modules/home/common/default.nix` で一括設定しているため、ホスト側で書く必要はありません。

## 各ディレクトリのルール

| ディレクトリ | 書くもの | 書かないもの |
|---|---|---|
| `hosts/` | import するモジュールと、ホスト固有の値（ホスト名など） | 共通の設定 |
| `modules/home/` | ユーザー環境（Home Manager モジュール） | OS レベルの設定 |
| `modules/darwin/`・`modules/nixos/` | OS レベルの設定 | ユーザー環境 |
| `config/` | アプリの設定ファイル本体（元の形式のまま） | Nix の式 |

<details>
<summary><b>modules/home/</b> — Home Manager モジュール</summary>

| サブディレクトリ | 内容 |
|---|---|
| `common/` | 全環境共通。CLI ツール（`packages.nix`）、シェル、Git・gh、SSH、Starship、Helix、Nushell、direnv、Zellij |
| `darwin/` | macOS 専用。Ghostty の設定、Claude Code / Codex、PDF の既定アプリ（`default-apps.nix`）、Karabiner（`karabiner.nix`）、Vivaldi（`vivaldi.nix`） |
| `linux/` | Linux 共通（standalone 用の `home-manager` コマンド）。`gui.nix` はデスクトップ環境向けの追加分（Ghostty 本体と設定） |

</details>

<details>
<summary><b>modules/darwin/ と modules/nixos/</b> — OS レベルの設定</summary>

| ファイル | 内容 |
|---|---|
| `darwin/system.nix` | Nix、ログインシェル（Nushell）、Touch ID sudo、電源、Tailscale |
| `darwin/defaults.nix` | `defaults write` 相当の macOS 設定 |
| `darwin/homebrew.nix`・`darwin/apps.nix` | Homebrew の有効化と GUI アプリ一覧 |
| `nixos/` | ユーザー、ブート、フォント、ネットワーク、サービス |

</details>

<details>
<summary><b>config/</b> — 設定ファイルをそのまま置く理由と例外</summary>

アプリの設定ファイルを元の形式で置き、Home Manager の `xdg.configFile` / `home.file` でシンボリックリンクとして配置します。Home Manager の option に書き換えないことで、既存の設定やアプリの公式ドキュメントをそのまま使えます。

例外:

| アプリ | 扱い | 理由 |
|---|---|---|
| Starship | `programs.starship.settings` に TOML を読み込ませる | Home Manager がシェル統合を生成するため |
| Nushell | `config.nu`・`env.nu` を `programs.nushell` 経由で配置。macOS ではネイティブの `~/Library/Application Support/nushell` を使う。自作のエイリアスと関数は `config/nushell/scripts/` に分ける | Home Manager が Starship・zoxide・direnv の初期化を追記できるようにするため |
| Karabiner | 読み取り専用のリンクではなく、書き込み可能なコピーとして配置。各プロファイルの `devices`（マシンごとのデバイス有効・無効）は既存ファイルの値を残す | アプリが設定ファイルを書き換えるため |
| Vivaldi | `config/vivaldi/` の JSON を既存のプロファイルに deep merge する。Vivaldi の起動中は適用をスキップ | アプリが終了時に設定ファイルを書き換えるため |

</details>

## bootstrap

Nix が入っていない状態から構成の適用までを担当し、それ以降の設定は持ちません。

| スクリプト | 役割 |
|---|---|
| `install.sh` | Nix を導入し、リポジトリを clone（既にあれば pull。git は `nix-shell` で用意）してから、OS に応じて `darwin.sh` / `linux.sh` を実行。NixOS には対応していない |
| `darwin.sh` | Homebrew を導入し、nix-darwin をビルドしてから `masApps` の App Store アプリを `mas install` で入れ、`darwin-rebuild switch`。何度実行しても安全。Nushell の `nix-apply` もこれを呼ぶ |
| `linux.sh` | Home Manager の activation package をビルドして実行 |
| `lib.sh` | `darwin.sh` と `linux.sh` の共通関数 |

> `darwin.sh` が先に `mas install` するのは、macOS 26.1 以降 App Store アプリのインストールに root 権限が必要で、`darwin-rebuild` 内の `brew bundle` ではパスワードを聞けないためです。

> `install.sh` は `curl | sh` で実行され、その時点ではリポジトリが手元に無いため、`lib.sh` と同じ処理を自身に持っています。

## 開発環境

言語ランタイムやプロジェクト固有のツールは Home Manager で管理しません。各プロジェクトに devbox の `devbox.json` と `.envrc` を置き、direnv でディレクトリに入ったときに読み込みます。

言語ごとの共通構成は `devbox-plugin/<言語>/plugin.json` にまとめ、プロジェクトの `devbox.json` から `include` します。

```json
{
  "packages": [],
  "include": ["github:micanis/dotfiles?dir=devbox-plugin/go"]
}
```

### plugin 一覧

| plugin | 入るもの | 設定 |
|---|---|---|
| `python` | Python 3.14・uv・ruff・basedpyright | `UV_PYTHON_DOWNLOADS=never`・`UV_PYTHON_PREFERENCE=only-system`、`VIRTUAL_ENV` と PATH に `.venv` |
| `go` | Go 1.27・gopls・gofumpt・golangci-lint・delve | `GOTOOLCHAIN=local`、`~/go/bin` を PATH に追加 |
| `frontend` | Node.js 26・pnpm 12・TypeScript・typescript-language-server・HTML / CSS / JSON / Tailwind の LSP | `node_modules/.bin` を PATH に追加 |

**python**

- devbox 組み込みの python plugin（`.devbox/virtenv` に venv を作る）は無効にし、uv がプロジェクト直下の `.venv` を管理する。`.venv/bin` は PATH に入るので activate は不要
- uv がダウンロードする Python は NixOS で動かない（動的リンクのため）ので、`UV_PYTHON_DOWNLOADS=never`・`UV_PYTHON_PREFERENCE=only-system` で Nix の Python だけを使わせる

**go**

- `GOTOOLCHAIN=local` で、go.mod の `toolchain` 行による Go の自動ダウンロードを止め、Nix の Go に固定する

**frontend**

- biome はプロジェクトの devDependency を使う（Helix は `pnpm exec biome lsp-proxy` で起動する）。`biome.json` のスキーマとバージョンを揃えるため
- pnpm 自体のバージョンは `package.json` の `packageManager` に従う。pnpm の既定の動作（`manage-package-manager-versions`）に任せていて、こちらでは設定していない。corepack は Node 25 以降同梱されないため使わない

### 導入の手順

[README のプロジェクトの開発環境](../README.md#プロジェクトの開発環境) を参照。macOS では Raycast の Script Command（`config/raycast/scripts/`）が導入コマンドをクリップボードにコピーする。

### 運用ルール

| ルール | 理由 |
|---|---|
| plugin は `path:` ではなく GitHub（main）から読み込む | devbox は `path:` の `~` を展開しないため絶対パスになり、ホームディレクトリが違う macOS（`/Users`）と Linux（`/home`）で `devbox.json` を共有できない |
| plugin を変更したら push する | プロジェクトは GitHub の main を読むため、push するまで反映されない |
| 言語のバージョンを変えたいときは、プロジェクトの `devbox.json` の `packages` に書く | `go@1.26` のように書くと plugin の既定値より優先される |
| LSP の設定は `config/helix/languages.toml`。言語ごとの LSP 本体は plugin に入れ、plugin が無い言語（Rust・C++ など）はプロジェクトの `devbox.json` に直接書く。言語に依存しない LSP（marksman・taplo）だけ `packages.nix` で全環境に入れる | Helix の設定は全環境共通、ツールのバージョンはプロジェクトごとに分けるため |

## 今後の課題

- 秘密情報の管理（sops-nix / agenix）
- NixOS のハードウェア設定の追加（現状は評価できない）
- CI での `nix flake check` とビルド確認
