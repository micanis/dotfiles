# Homebrew is used only for GUI apps; the app list lives in apps.nix.
{
  homebrew = {
    enable = true;
    # Leave apps that are not declared here installed.
    onActivation.cleanup = "none";
  };
}
