{ pkgs, ... }:
{
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nixpkgs.config.allowUnfree = true;

  boot.tmp.cleanOnBoot = true;

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  hardware.enableRedistributableFirmware = true;

  networking.networkmanager.enable = true;

  system.stateVersion = "25.05";
}
