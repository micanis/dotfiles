# GUI apps installed through Homebrew casks and the Mac App Store.
{
  homebrew = {
    casks = [
      "bitwarden"
      "craft"
      "discord"
      "docker-desktop"
      "ghostty"
      "jump-desktop-connect"
      "karabiner-elements"
      "microsoft-excel"
      "microsoft-powerpoint"
      "microsoft-word"
      "notion"
      "raycast"
      "slack"
      "vivaldi"
      "zoom"
    ];

    # Installing a new entry needs sudo, which activation cannot prompt for;
    # apply with bootstrap/darwin.sh, which installs these first.
    masApps = {
      "RunCat Neo" = 6757801838;
    };
  };
}
