# NixOS system configuration.
{
  imports = [
    ./users.nix
    ./system.nix
    ./services.nix
  ];
}
