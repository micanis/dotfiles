# Embeds Home Manager in a nix-darwin or NixOS host.
#
# Hosts only choose which Home Manager modules to import, via
#   home-manager.users.${username}.imports = [ ... ];
# The user's name, home directory, and state version are set by
# modules/home/common, which receives the same extra arguments as the host.
{
  inputs,
  username,
  homeDirectory,
  homeStateVersion,
  ...
}:
{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    # Rename pre-existing files instead of failing activation.
    backupFileExtension = "before-home-manager";
    extraSpecialArgs = {
      inherit
        inputs
        username
        homeDirectory
        homeStateVersion
        ;
    };
  };
}
