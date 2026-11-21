# Custom functions

# Create directory and cd into it
def --env mkcd [dir: string] {
    mkdir $dir
    cd $dir
}

# Quick ripgrep search (falls back to grep if rg not found)
def search [pattern: string, ...paths: string] {
    let targets = if ($paths | is-empty) { ["."] } else { $paths }
    if (which rg | is-not-empty) {
        rg $pattern ...$targets
    } else {
        grep -r $pattern ...$targets
    }
}

# Show PATH entries one per line (useful for debugging)
def path-show [] {
    $env.PATH | each { |p| print $p }
}

# Extract any archive by extension
def extract [file: path] {
    match ($file | path parse | get extension) {
        "gz"  => { tar xzf $file }
        "xz"  => { tar xJf $file }
        "bz2" => { tar xjf $file }
        "zip" => { unzip $file }
        "zst" => { tar --zstd -xf $file }
        _     => { error make { msg: $"Unknown extension: ($file)" } }
    }
}

# fzf-powered cd (jump into any dir under cwd)
def --env fcd [] {
    let target = (fd --type d --hidden --exclude .git | fzf)
    if ($target | is-not-empty) { cd $target }
}

# fzf-powered file open in helix
def fe [] {
    let target = (fd --type f --hidden --exclude .git | fzf --preview 'bat --color=always --style=numbers --line-range :200 {}')
    if ($target | is-not-empty) { hx $target }
}

# ─── dotfiles (Nix) ──────────────────────────────────────────────────────────

# Apply the dotfiles for this machine. Linux (non-NixOS) takes the Home Manager
# profile: linux-gui or linux-headless (default, same as bootstrap/linux.sh).
def nix-apply [profile?: string] {
    cd ~/.local/share/dotfiles

    # Flakes ignore files Git does not know about.
    let untracked = (git ls-files --others --exclude-standard | lines)
    if ($untracked | is-not-empty) {
        print "Untracked files (ignored by the flake):"
        $untracked | each { |f| print $"  ($f)" }
        if (input "git add them? [y/N] ") in ["y" "Y"] { git add ...$untracked }
    }

    if $nu.os-info.name == "macos" {
        ./bootstrap/darwin.sh
    } else if ("/etc/NIXOS" | path exists) {
        sudo nixos-rebuild switch --flake .#nixos
    } else {
        ./bootstrap/linux.sh ($profile | default "linux-headless")
    }
}

# Update all flake inputs and the official Linux Codex binary, then apply.
def nix-update [profile?: string] {
    cd ~/.local/share/dotfiles
    with-env (github-nix-config) {
        let updated = (do { ^nix flake update } | complete)
        print -n $updated.stdout
        print -en $updated.stderr
        if $updated.exit_code != 0 {
            error make { msg: "Flake update failed; configuration was not applied." }
        }
        update-codex-binary
    }
    nix-apply $profile
}

# Run from the repository root. The input pins the version; this file pins the
# official archive's contents. This also updates the Linux pin when run on Mac.
def update-codex-binary [] {
    let evaluated = (do {
        ^nix --extra-experimental-features "nix-command flakes" eval --impure --raw --expr '(builtins.getFlake (toString ./.)).inputs.llm-agents.packages.x86_64-linux.codex.version'
    } | complete)
    if $evaluated.exit_code != 0 {
        error make { msg: $"Could not determine the pinned Codex version: ($evaluated.stderr)" }
    }
    let version = ($evaluated.stdout | str trim)
    if $version !~ '^\d+\.\d+\.\d+$' {
        error make { msg: $"Unexpected Codex version: ($version)" }
    }
    let manifest = "packages/codex-binary/source.json"
    let current = (open $manifest)
    if $current.version == $version { return }

    let url = $"https://github.com/openai/codex/releases/download/rust-v($version)/codex-package-x86_64-unknown-linux-musl.tar.gz"
    print $"Fetching official Linux Codex ($version)..."
    let fetched = (do {
        ^nix --extra-experimental-features nix-command store prefetch-file --json --hash-type sha256 $url
    } | complete)
    if $fetched.exit_code != 0 {
        error make { msg: $"Codex download failed; binary pin was not changed: ($fetched.stderr)" }
    }
    let hash = ($fetched.stdout | from json | get hash)
    if $hash !~ '^sha256-[A-Za-z0-9+/]{43}=$' {
        error make { msg: "Codex download returned an invalid SHA-256 hash; binary pin was not changed." }
    }
    let temporary = $"($manifest).(random uuid).tmp"
    try {
        {version: $version, hash: $hash} | to json --indent 2 | save $temporary
        mv -f $temporary $manifest
    } catch {|err|
        if ($temporary | path exists) { rm $temporary }
        error make { msg: $"Could not save the Codex binary pin: ($err.msg)" }
    }
}

# Pass the gh token to Nix so GitHub API calls are not rate limited as
# anonymous requests (60/hour per IP). The token is never written to disk.
def github-nix-config [] {
    let token = (do { gh auth token } | complete)
    if $token.exit_code != 0 { return {} }
    let tokens = $"access-tokens = github.com=($token.stdout | str trim)"
    { NIX_CONFIG: ([$env.NIX_CONFIG? $tokens] | compact | str join "\n") }
}

# Delete old generations and unused store paths.
def nix-clean [] {
    nix-collect-garbage -d
    sudo nix-collect-garbage -d
}
