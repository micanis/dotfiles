# macOS の設定一覧

nix-darwin と Home Manager で管理している macOS の設定を、別の Mac へ移行するときのチェックリストとしてまとめたもの。

> 正しい値はコード側にあります。この一覧と食い違う場合は「定義場所」のファイルを優先してください。

## 目次

- [管理している設定](#管理している設定)
- [移行元の Mac と比較する](#移行元の-mac-と比較する)
- [別の Mac に適用する](#別の-mac-に適用する)

## 管理している設定

| 分類 | 内容 | 定義場所 |
|---|---|---|
| ユーザー | プライマリユーザー `micanis`、ホーム `/Users/micanis`、ログインシェルは Nushell | `hosts/darwin`, `modules/darwin/system.nix` |
| セキュリティ | `sudo` で Touch ID を使用 | `modules/darwin/system.nix` |
| 電源 | システムはスリープしない。ディスプレイは 60 分でスリープ | `modules/darwin/system.nix` |
| Tailscale | Nix 版 CLI。`tailscaled` を起動時からシステムデーモンとして実行 | `modules/darwin/system.nix` |
| 言語 | 優先言語 `en-JP`, `ja-JP`、ロケール `en_JP` | `modules/darwin/defaults.nix` |
| キーボード | キーリピート高速化、長押しのアクセント入力無効、日本語入力のライブ変換無効 | `modules/darwin/defaults.nix` |
| キー配列 | Karabiner-Elements で Control と Command を入れ替え。Caps Lock は Control+Space、Shift+Caps Lock で Caps Lock | `config/karabiner/karabiner.json` |
| 外観 | ダークモード | `modules/darwin/defaults.nix` |
| 入力 | ナチュラルスクロール無効、強めのクリック有効、マウス速度 `0.5`、トラックパッド速度 `0.6875` | `modules/darwin/defaults.nix` |
| メニューバー | バッテリー残量を % 表示。時計は AM/PM・曜日を表示し、日付は余裕があるとき表示 | `modules/darwin/defaults.nix` |
| Finder | 隠しファイルと拡張子を表示、パスバー・ステータスバー表示、タイトルに POSIX パス、リスト表示、検索は現在のフォルダ、新規ウインドウはホーム | `modules/darwin/defaults.nix` |
| デスクトップ | 外部ディスク・サーバー・リムーバブルメディアを表示、内蔵ディスクは非表示 | `modules/darwin/defaults.nix` |
| `.DS_Store` | ネットワークと USB ボリュームには作らない | `modules/darwin/defaults.nix` |
| Dock | 自動的に隠す、最近使ったアプリ非表示、サイズ `58`、右下ホットコーナーでクイックメモ、Mission Control / App Exposé ジェスチャー有効 | `modules/darwin/defaults.nix` |
| Dock の項目 | Vivaldi、Craft、Ghostty、ダウンロードフォルダ（スタック） | `modules/darwin/defaults.nix` |
| スクリーンショット | クリップボードに保存 | `modules/darwin/defaults.nix` |
| 既定アプリ | PDF を現在の既定ブラウザで開く | `modules/home/darwin/default-apps.nix` |
| Vivaldi | メモリ節約: Memory Saver（Balanced）、復元したタブを遅延読み込み | `modules/home/darwin/vivaldi.nix`, `config/vivaldi/` |
| アプリ | Homebrew Cask と Mac App Store のアプリ | `modules/darwin/apps.nix` |
| ユーザーファイル | シェル・Git・エディタなどの設定 | `modules/home/`, `config/` |

## 移行元の Mac と比較する

`modules/darwin/defaults.nix` を変更する前に、現在の値を確認します。

```sh
defaults read NSGlobalDomain
defaults read com.apple.finder
defaults read com.apple.desktopservices
defaults read com.apple.dock
defaults read com.apple.screencapture
defaults read com.apple.menuextra.clock
defaults read com.apple.controlcenter
```

> **注意:** 最近使った項目、ウインドウ位置、分析用のタイムスタンプ、マウントしたボリュームの位置、デバイスごとの履歴など、頻繁に変わる値は Nix に書かないでください。

## 別の Mac に適用する

```sh
curl -fsSL https://raw.githubusercontent.com/micanis/dotfiles/main/bootstrap/install.sh | sh
```

初回の適用で nix-darwin が `/etc/shells` を管理できない場合は、元のファイルを退避して再実行します。

```sh
sudo mv /etc/shells /etc/shells.before-nix-darwin
./bootstrap/darwin.sh
```

> Karabiner の設定は、Home Manager の適用のたびに書き込み可能なファイルとしてコピーされます。Karabiner がその場で設定を書き換えても動作し、次回の適用時には `config/karabiner/karabiner.json` の内容に戻ります（デバイスの有効・無効だけは各 Mac の値を保持します）。

> Vivaldi の設定は、Vivaldi を終了した状態で適用してください。起動中は適用がスキップされます。
