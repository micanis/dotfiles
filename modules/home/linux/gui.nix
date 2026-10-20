# Additions for Linux hosts with a desktop.
{ pkgs, ... }:
{
  home.packages = [ pkgs.ghostty ];

  xdg.configFile."ghostty".source = ../../../config/ghostty;
}
