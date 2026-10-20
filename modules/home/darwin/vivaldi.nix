# Vivaldi settings that live in the profile (the app is a Homebrew cask).
#
# Vivaldi rewrites `Local State` and `Preferences` on exit, so they cannot be
# symlinks and must not be edited while it runs. Each activation deep-merges
# the values declared in config/vivaldi/ and leaves the rest of the profile
# untouched (arrays are replaced, not appended):
#   - local-state.json -> `Local State` (Chromium-level: Memory Saver, flags)
#   - preferences.json -> `Default/Preferences` (Vivaldi-level settings)
# If Vivaldi is running, the patch is skipped; quit it and activate again.
{ lib, pkgs, ... }:
let
  jq = "${pkgs.jq}/bin/jq";
  localStatePatch = ../../../config/vivaldi/local-state.json;
  preferencesPatch = ../../../config/vivaldi/preferences.json;
in
{
  home.activation.configureVivaldi = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    profile_dir="$HOME/Library/Application Support/Vivaldi"
    patched="$profile_dir/.patched.home-manager"

    if /usr/bin/pgrep -x Vivaldi > /dev/null; then
      echo >&2 "Vivaldi is running; skipping its settings. Quit it and activate again."
    else
      for entry in \
        "$profile_dir/Local State|${localStatePatch}" \
        "$profile_dir/Default/Preferences|${preferencesPatch}"; do
        target="''${entry%%|*}"
        patch="''${entry##*|}"
        if [ -f "$target" ]; then
          ${jq} -s '.[0] * .[1]' "$target" "$patch" > "$patched" \
            && $DRY_RUN_CMD install -m 600 "$patched" "$target"
        fi
      done

      rm -f "$patched"
    fi
  '';
}
