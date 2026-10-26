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

# Update all flake inputs, then apply.
def nix-update [profile?: string] {
    cd ~/.local/share/dotfiles
    with-env (github-nix-config) { nix flake update }
    nix-apply $profile
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
