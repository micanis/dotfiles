# macOS host (nix-darwin + Home Manager).
{ username, homeDirectory, ... }:
{
  imports = [
    ../../modules/darwin
    ../../modules/home-manager.nix
  ];

  system.primaryUser = username;
  users.users.${username}.home = homeDirectory;

  home-manager.users.${username}.imports = [
    ../../modules/home/common
    ../../modules/home/darwin
  ];
}
