# Additions for Linux hosts with a desktop.
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    ghostty
    wl-clipboard
    xclip
  ];

  xdg.configFile."ghostty".source = ../../../config/ghostty;
}
