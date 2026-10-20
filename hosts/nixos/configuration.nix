# NixOS host (NixOS modules + Home Manager).
{ username, ... }:
{
  imports = [
    ../../modules/nixos
    ../../modules/home-manager.nix
  ];

  networking.hostName = "nixos";

  home-manager.users.${username}.imports = [
    ../../modules/home/common
    ../../modules/home/linux
  ];
}
