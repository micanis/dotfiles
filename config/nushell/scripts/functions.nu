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
