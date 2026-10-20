# Default applications for file types.
{ lib, pkgs, ... }:
let
  duti = "${pkgs.duti}/bin/duti";
in
{
  home.packages = [ pkgs.duti ];

  # Keep PDFs out of Preview and open them with the current default
  # browser. Querying the HTML handler makes this follow browser
  # changes instead of hard-coding Vivaldi's bundle identifier.
  home.activation.openPdfsInDefaultBrowser = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    browser_bundle_id="$(${duti} -x html | tail -n 1)"

    if [ -z "$browser_bundle_id" ]; then
      echo >&2 "error: could not determine the default browser"
      exit 1
    fi

    $DRY_RUN_CMD ${duti} -s "$browser_bundle_id" com.adobe.pdf all
  '';
}
