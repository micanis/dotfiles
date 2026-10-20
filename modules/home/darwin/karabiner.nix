# Karabiner-Elements key mappings (the app is a Homebrew cask).
#
# Karabiner rewrites karabiner.json when its settings change, so a read-only
# Home Manager symlink is not suitable here. Instead, every activation copies
# config/karabiner/karabiner.json into place as a writable file, keeping each
# profile's local `devices` section (per-Mac device enable/disable choices).
{ lib, pkgs, ... }:
let
  jq = "${pkgs.jq}/bin/jq";
  managedConfig = ../../../config/karabiner/karabiner.json;

  # Input: [managed, local]. Output: managed, with each profile's `devices`
  # taken from the local profile of the same name when it has one.
  keepLocalDevices = ''
    .[0] as $managed
    | .[1] as $local
    | $managed
    | .profiles |= map(
        . as $profile
        | ($local.profiles // [] | map(select(.name == $profile.name)) | first) as $local_profile
        | if $local_profile != null and ($local_profile | has("devices"))
          then .devices = $local_profile.devices
          else .
          end
      )
  '';
in
{
  home.activation.installKarabinerConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    config_dir="$HOME/.config/karabiner"
    config_file="$config_dir/karabiner.json"
    merged_config="$config_dir/.karabiner.json.home-manager"

    $DRY_RUN_CMD mkdir -p "$config_dir"

    # Replace a symlink left by an earlier, read-only setup.
    if [ -L "$config_file" ]; then
      $DRY_RUN_CMD rm "$config_file"
    fi

    if [ -f "$config_file" ] && ${jq} -e 'type == "object"' "$config_file" > /dev/null; then
      ${jq} -s '${keepLocalDevices}' ${managedConfig} "$config_file" > "$merged_config"
      $DRY_RUN_CMD install -m 600 "$merged_config" "$config_file"
      $DRY_RUN_CMD rm "$merged_config"
    else
      $DRY_RUN_CMD install -m 600 ${managedConfig} "$config_file"
    fi
  '';
}
