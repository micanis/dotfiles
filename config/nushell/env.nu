# Nushell environment — sourced before config.nu

# PATH (devbox/direnv handle per-project tools). Nushell can be launched by a
# macOS GUI app without nix-darwin's shell initialization, so include the Nix
# profiles explicitly instead of relying on the inherited PATH.
$env.PATH = ($env.PATH? | default "" | split row (char esep) | prepend [
    ($env.HOME | path join ".local" "bin")
    ($env.HOME | path join ".nix-profile" "bin")
    (["/etc/profiles/per-user" $env.USER "bin"] | path join)
    "/run/current-system/sw/bin"
    "/nix/var/nix/profiles/default/bin"
    "/usr/local/bin"
    "/usr/bin"
    "/bin"
    "/usr/sbin"
    "/sbin"
] | where {|path| $path != "" } | uniq)

# Editor
$env.EDITOR = "hx"
$env.VISUAL = "hx"

# True color (24-bit) — Linux 環境で Helix のテーマカラーが 256 色に丸められないように明示
$env.COLORTERM = "truecolor"

$env.DIRENV_LOG_FORMAT = ""
