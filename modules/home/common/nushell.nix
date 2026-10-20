{
  config,
  lib,
  pkgs,
  ...
}:
let
  configDir =
    if pkgs.stdenv.hostPlatform.isDarwin then
      "${config.home.homeDirectory}/Library/Application Support/nushell"
    else
      "${config.xdg.configHome}/nushell";
in
{
  programs.nushell = {
    enable = true;
    # A login shell launched by a macOS GUI app does not necessarily inherit
    # XDG_CONFIG_HOME, so use Nushell's native Darwin path there. Other
    # platforms keep their configuration under XDG_CONFIG_HOME.
    inherit configDir;
    configFile.source = ../../../config/nushell/config.nu;
    envFile.source = ../../../config/nushell/env.nu;
  };

  # Keep user-authored files separate from config.nu/env.nu so Home Manager
  # can append the Starship, zoxide, and direnv integrations it generates.
  xdg.configFile."nushell/scripts".source = ../../../config/nushell/scripts;

  # Before this configuration, the entire ~/.config/nushell directory was a
  # Home Manager symlink. Unlink only that known legacy target so the files
  # above can be linked individually; never touch a user-owned directory.
  home.activation.migrateNushellConfig = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    if [ -L "$HOME/.config/nushell" ]; then
      target="$(readlink "$HOME/.config/nushell")"
      case "$target" in
        /nix/store/*-home-manager-files/.config/nushell)
          rm "$HOME/.config/nushell"
          ;;
      esac
    fi
  '';
}
