# User environment for macOS.
{ pkgs, inputs, ... }:
let
  llmAgents = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  imports = [
    ./default-apps.nix
    ./karabiner.nix
    ./vivaldi.nix
  ];

  home.packages = [
    llmAgents.claude-code
    llmAgents.codex
  ];

  # Ghostty itself is installed as a Homebrew cask (modules/darwin/apps.nix).
  xdg.configFile."ghostty".source = ../../../config/ghostty;
}
