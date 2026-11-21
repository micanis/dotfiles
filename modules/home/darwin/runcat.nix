{ lib, pkgs, ... }:
let
  scripts = ../../../config/runcat;
in
{
  # Claude and Codex own these settings files, so merge our entries at activation.
  home.activation.installRunCatMetrics = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD ${pkgs.python3}/bin/python3 ${scripts}/install.py
  '';
}
