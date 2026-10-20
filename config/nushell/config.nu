# Nushell main configuration

# Aliases and functions
source ~/.config/nushell/scripts/aliases.nu
source ~/.config/nushell/scripts/functions.nu

# Starship, zoxide, and direnv are initialized by Home Manager after this file.

$env.config = {
    show_banner: false

    history: {
        max_size:      100_000
        sync_on_enter: true
        file_format:   "sqlite"   # SQLite history supports better search than plaintext
    }

    # Vi keybindings (esc → normal mode, i → insert)
    edit_mode: vi
    cursor_shape: {
        vi_insert: line
        vi_normal: block
    }

    completions: {
        case_sensitive: false
        quick:          true
        partial:        true
        algorithm:      "prefix"
    }

    table: {
        mode:       "rounded"
        index_mode: "always"
    }

}
