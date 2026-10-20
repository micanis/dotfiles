# shellcheck shell=sh
# Helpers shared by darwin.sh and linux.sh. Source this file; do not run it.
#
# install.sh keeps its own copy of ensure_nix because it is piped from curl
# before the repository (and this file) exists on the machine.

die() {
  echo "error: $*" >&2
  exit 1
}

require_curl() {
  command -v curl >/dev/null 2>&1 || die "curl is required to install $1."
}

# Install Nix with the official installer unless it is already available.
ensure_nix() {
  if ! command -v nix >/dev/null 2>&1; then
    require_curl Nix
    curl -sSfL https://artifacts.nixos.org/nix-installer | sh -s -- install
    export PATH="/nix/var/nix/profiles/default/bin:$PATH"
  fi

  command -v nix >/dev/null 2>&1 ||
    die "nix is not available after installation. Open a new shell and rerun this script."
}

# Run nix with flakes enabled even before nix.conf turns them on.
run_nix() {
  nix --extra-experimental-features "nix-command flakes" "$@"
}

# Move to the repository root (the parent of bootstrap/).
cd_repo_root() {
  cd "$(dirname "$0")/.." || die "cannot cd to the repository root"
}
