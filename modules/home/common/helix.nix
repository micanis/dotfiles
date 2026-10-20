{
  xdg.configFile."helix".source = ../../../config/helix;
  xdg.configFile."clangd".source = ../../../config/clangd;

  home.file.".local/bin/helix-yazi" = {
    source = ../../../config/bin/helix-yazi;
    executable = true;
  };
}
