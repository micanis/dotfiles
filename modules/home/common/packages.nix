{ pkgs, ... }:
{
  home.packages = with pkgs; [
    devbox
    zellij
    helix
    ripgrep
    fd
    bat
    eza
    fzf
    yazi
    lazygit
    dust
    procs
    hyperfine
    tokei
    jq
    yq-go
    marksman
    taplo
  ];
}
