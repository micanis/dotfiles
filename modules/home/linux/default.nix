# User environment for every Linux host (NixOS and non-NixOS).
{ pkgs, inputs, ... }:
let
  llmAgents = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  home.packages = [
    (pkgs.callPackage ../../../packages/codex-binary { })
    llmAgents.claude-code
  ];

  # Fresh Linux accounts commonly have .profile and .bashrc already.
  # This also applies when bootstrap runs the activation package directly.
  home.backupFileExtension = "before-home-manager";

  # Put the `home-manager` command on PATH for standalone installs.
  programs.home-manager.enable = true;
}
