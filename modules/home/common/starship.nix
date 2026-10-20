{
  programs.starship = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableNushellIntegration = true;
    settings = builtins.fromTOML (builtins.readFile ../../../config/starship.toml);
  };
}
