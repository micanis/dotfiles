# User environment shared by every host.
{
  username,
  homeDirectory,
  homeStateVersion,
  ...
}:
{
  imports = [
    ./packages.nix
    ./shell.nix
    ./git.nix
    ./ssh.nix
    ./starship.nix
    ./helix.nix
    ./nushell.nix
    ./direnv.nix
    ./zellij.nix
  ];

  home.username = username;
  home.homeDirectory = homeDirectory;
  home.stateVersion = homeStateVersion;
}
