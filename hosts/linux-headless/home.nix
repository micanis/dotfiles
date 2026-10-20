# Non-NixOS Linux server or container (standalone Home Manager).
{
  imports = [
    ../../modules/home/common
    ../../modules/home/linux
  ];
}
