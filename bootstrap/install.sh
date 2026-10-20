#!/usr/bin/env sh
# Entry point for a fresh machine:
#
#   curl -fsSL https://raw.githubusercontent.com/micanis/dotfiles/main/bootstrap/install.sh | sh
#
# Clones (or updates) this repository, then hands off to darwin.sh or
# linux.sh. When run from an existing checkout, it uses that checkout as is.
#
# Environment:
#   DOTFILES_REPO  repository URL  (default: the GitHub repository above)
#   DOTFILES_DIR   checkout path   (default: ~/.local/share/dotfiles)
# Arguments (Linux only):
#   $1             linux-gui | linux-headless  (default: linux-headless)
set -eu

repo_url="${DOTFILES_REPO:-https://github.com/micanis/dotfiles.git}"
target_dir="${DOTFILES_DIR:-$HOME/.local/share/dotfiles}"

die() {
  echo "error: $*" >&2
  exit 1
}

case "$(uname -s)" in
  Darwin | Linux) ;;
  *) die "unsupported system: $(uname -s)" ;;
esac

# Same as ensure_nix in lib.sh, which does not exist yet when piped from curl.
ensure_nix() {
  if ! command -v nix >/dev/null 2>&1; then
    command -v curl >/dev/null 2>&1 || die "curl is required to install Nix."
    curl -sSfL https://artifacts.nixos.org/nix-installer | sh -s -- install
    export PATH="/nix/var/nix/profiles/default/bin:$PATH"
  fi

  command -v nix >/dev/null 2>&1 ||
    die "nix is not available after installation. Open a new shell and rerun this script."
}

# Run git from nixpkgs so a fresh machine does not need git installed.
nix_git() {
  DOTFILES_REPO="$repo_url" DOTFILES_DIR="$target_dir" nix-shell -p git --run "$1"
}

script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
if [ -f "$script_dir/install.sh" ] && [ -f "$script_dir/../flake.nix" ]; then
  # Running from a checkout.
  target_dir=$(CDPATH= cd -- "$script_dir/.." && pwd)
else
  ensure_nix
  mkdir -p "$(dirname "$target_dir")"

  if [ -d "$target_dir/.git" ]; then
    nix_git 'git -C "$DOTFILES_DIR" pull --ff-only'
  elif [ -e "$target_dir" ]; then
    die "$target_dir exists but is not a git repository."
  else
    nix_git 'git clone "$DOTFILES_REPO" "$DOTFILES_DIR"'
  fi
fi

case "$(uname -s)" in
  Darwin) exec "$target_dir/bootstrap/darwin.sh" ;;
  Linux) exec "$target_dir/bootstrap/linux.sh" "${1:-linux-headless}" ;;
esac
