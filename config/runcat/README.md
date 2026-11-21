# RunCat Neo の AI 使用量

Home Manager の適用時に、既存の設定を残したまま Claude Code の status line と Codex の Stop hook を追加します。既存の Claude status line がある場合は上書きしません。

RunCat Neo の Settings → Metrics → Custom Metrics で次のファイルを追加します。

- `~/.claude/runcat-usage.json`（Claude Code NPO）
- `~/.codex/runcat-usage.json`（ローカル Codex の現在のログイン）

表示をメニューバーに出すには Metrics Bar の各ソースを有効にします。Claude Code は対話中の status line 更新時、Codex はターン完了時に更新されます。Codex の hook は再起動後に `/hooks` で確認し、必要に応じて信頼してください。どちらもセッションが動いていない間は更新されません。Claude Code の 5 時間・7 日の値はサービスから提供された場合に表示されます。

私用 Codex は別サーバー上で動くため、この設定だけでは表示されません。サーバー上の出力を Mac に転送する別途の設定が必要です。

Codex のスクリプトは [RunCat Neo 公式サンプル](https://github.com/runcat-dev/RunCatNeo/tree/main/docs/samples/codex) を元に、出力先と表示名を変更しています。
