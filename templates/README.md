# devbox.json reference

Per-project language environments are declared in each project's `devbox.json`.
This template is a starting point — copy, prune, then bootstrap:

```sh
cp ~/path/to/dotfiles/templates/devbox.json ./devbox.json
devbox install
devbox generate direnv
direnv allow
```

After that, `cd` into the project automatically activates the environment
(via direnv) and `exec nu` swaps the shell to nushell.

## Why no `devbox global`

Languages live with the project that needs them — versions never clash and
moving to a fresh machine only requires `devbox install`. The dotfiles only
provision the host with `devbox`, `direnv`, and the editor / shell themselves.
Java is no exception: `jdk@21` + `jdt-language-server` are listed below
alongside the other languages. SDKMAN is intentionally not provisioned.

## Helix LSP discovery

`~/.config/helix/languages.toml` references LSP commands by name (`gopls`,
`rust-analyzer`, `basedpyright-langserver`, etc.). When direnv activates a
project, those binaries appear on `PATH` and Helix picks them up — no global
install needed.
