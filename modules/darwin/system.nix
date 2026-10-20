# nix-darwin system settings: Nix, login shell, security, power, services.
{
  lib,
  pkgs,
  username,
  ...
}:
{
  nix.enable = false;

  nixpkgs.config.allowUnfree = true;

  # nix-darwin owns /etc/shells when environment.shells is set. On the first
  # activation, move the existing file aside:
  #
  #   sudo mv /etc/shells /etc/shells.before-nix-darwin
  environment.shells = with pkgs; [
    bashInteractive
    zsh
    nushell
  ];

  # environment.shells only adds Nushell to /etc/shells; it does not create
  # /run/current-system/sw/bin/nu, which is the stable login-shell path below.
  environment.systemPackages = [ pkgs.nushell ];

  programs.zsh.enable = true;

  # nix-darwin deliberately leaves properties of existing macOS users alone
  # unless it owns the whole account via users.knownUsers. The primary admin
  # user must remain macOS-managed, so enforce only its login shell here.
  system.activationScripts.postActivation.text = lib.mkAfter ''
    desired_shell=/run/current-system/sw/bin/nu
    current_shell="$(dscl . -read /Users/${username} UserShell 2> /dev/null | awk '{ print $2 }')"

    if [ "$current_shell" != "$desired_shell" ]; then
      echo >&2 "setting ${username}'s login shell to Nushell..."
      dscl . -create /Users/${username} UserShell "$desired_shell"
    fi

    configured_shell="$(dscl . -read /Users/${username} UserShell | awk '{ print $2 }')"
    if [ "$configured_shell" != "$desired_shell" ]; then
      echo >&2 "error: failed to set ${username}'s login shell to Nushell"
      exit 1
    fi
  '';

  security.pam.services.sudo_local.touchIdAuth = true;

  # Install the CLI and run tailscaled as a system daemon from boot. This
  # avoids depending on the GUI app or a per-user login item.
  services.tailscale.enable = true;

  # Keep the system awake so background services such as Tailscale remain
  # connected, while allowing idle displays to sleep after one hour.
  power.sleep.computer = "never";
  power.sleep.display = 60;

  system.stateVersion = 6;
}
