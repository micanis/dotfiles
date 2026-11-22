{ pkgs, ... }:
{
  home.packages = [
    (pkgs.writeShellApplication {
      name = "pbcopy";
      runtimeInputs = [ pkgs.coreutils ];
      text = builtins.readFile ../../../config/bin/pbcopy-linux;
    })
  ];
}
