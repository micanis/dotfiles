# macOS system configuration (nix-darwin).
{
  imports = [
    ./system.nix
    ./defaults.nix
    ./homebrew.nix
    ./apps.nix
  ];
}
