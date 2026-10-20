{
  home.sessionVariables = {
    COLORTERM = "truecolor";
    EDITOR = "hx";
    VISUAL = "hx";
    XDG_CONFIG_HOME = "$HOME/.config";
  };

  home.sessionPath = [
    "$HOME/.local/bin"
  ];

  programs.bash = {
    enable = true;
  };

  programs.zsh = {
    enable = true;
    envExtra = ''
      export XDG_CONFIG_HOME="$HOME/.config"
      export COLORTERM="truecolor"
    '';
    initContent = ''
      [[ -o interactive ]] || return
    '';
  };

  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableNushellIntegration = true;
  };
}
