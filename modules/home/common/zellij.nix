{ pkgs, ... }:
let
  configDir = ../../../config/zellij;
  keybinds = if pkgs.stdenv.hostPlatform.isDarwin then "keybinds-darwin.kdl" else "keybinds-linux.kdl";
in
{
  xdg.configFile."zellij".source = pkgs.writeTextDir "config.kdl" (
    builtins.readFile (configDir + "/config.kdl")
    + builtins.readFile (configDir + "/${keybinds}")
  );
}
