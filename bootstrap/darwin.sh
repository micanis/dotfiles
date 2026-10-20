#!/usr/bin/env sh
# Apply darwinConfigurations.darwin (nix-darwin + Home Manager + Homebrew).
set -eu

# shellcheck source=bootstrap/lib.sh
. "$(dirname "$0")/lib.sh"

# Add Homebrew to PATH, installing it first when it is missing.
ensure_homebrew() {
  for prefix in /opt/homebrew /usr/local; do
    if [ -x "$prefix/bin/brew" ]; then
      export PATH="$prefix/bin:$PATH"
      return
    fi
  done

  if ! command -v brew >/dev/null 2>&1; then
    require_curl Homebrew
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    for prefix in /opt/homebrew /usr/local; do
      if [ -x "$prefix/bin/brew" ]; then
        export PATH="$prefix/bin:$PATH"
        break
      fi
    done
  fi

  command -v brew >/dev/null 2>&1 ||
    die "homebrew is not available after installation. Open a new shell and rerun this script."
}

# Install the Mac App Store apps listed in homebrew.masApps.
#
# Since macOS 26.1, mas needs root to install an app and asks for a
# password through sudo. nix-darwin runs `brew bundle` without a terminal,
# so that prompt fails and activation stops. Install missing apps here,
# where sudo can prompt, so `brew bundle` later finds them already installed.
install_app_store_apps() {
  mas="$(run_nix eval --raw .#darwinConfigurations.darwin.pkgs.mas.outPath)/bin/mas"
  ids=$(run_nix eval --raw .#darwinConfigurations.darwin.config.homebrew.masApps \
    --apply 'apps: toString (builtins.attrValues apps)')

  [ -n "$ids" ] || return 0
  run_nix build --no-link .#darwinConfigurations.darwin.pkgs.mas

  for id in $ids; do
    # Already installed apps are skipped without asking for a password.
    "$mas" install "$id" ||
      die "could not install App Store app $id. Sign in to the App Store app and rerun this script."
  done
}

ensure_nix
ensure_homebrew
cd_repo_root

# darwin-rebuild is not installed yet on a fresh Mac, so build the system
# first and use the darwin-rebuild it contains.
run_nix build .#darwinConfigurations.darwin.system
install_app_store_apps
sudo ./result/sw/bin/darwin-rebuild switch --flake .#darwin
