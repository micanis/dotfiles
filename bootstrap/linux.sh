#!/usr/bin/env sh
# Apply a standalone Home Manager profile on non-NixOS Linux.
# Usage: bootstrap/linux.sh [linux-gui|linux-headless]   (default: linux-headless)
set -eu

# shellcheck source=bootstrap/lib.sh
. "$(dirname "$0")/lib.sh"

profile="${1:-linux-headless}"

case "$profile" in
  linux-gui | linux-headless) ;;
  *) die "usage: $0 [linux-gui|linux-headless]" ;;
esac

ensure_nix
cd_repo_root

# Home Manager must target the actual account, even when USER is stale or unset.
USER=$(id -un)
export USER
run_nix build --impure ".#homeConfigurations.${profile}.activationPackage"
./result/activate
