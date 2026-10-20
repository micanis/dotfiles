# Non-NixOS Linux desktop (standalone Home Manager).
{
  imports = [
    ../../modules/home/common
    ../../modules/home/linux
    ../../modules/home/linux/gui.nix
  ];
}
