# macOS user defaults (`defaults write ...`), grouped by preference domain.
# docs/darwin-settings.md summarizes these for humans.
{ homeDirectory, ... }:
{
  system.defaults = {
    # Mouse settings shared by global preferences.
    ".GlobalPreferences" = {
      "com.apple.mouse.scaling" = 0.5;
    };

    # Domains without a dedicated nix-darwin option.
    CustomUserPreferences = {
      # Do not write .DS_Store files on network or USB volumes.
      "com.apple.desktopservices" = {
        DSDontWriteNetworkStores = true;
        DSDontWriteUSBStores = true;
      };

      # Disable Japanese IME Live Conversion so candidates are only committed
      # explicitly.
      "com.apple.inputmethod.Kotoeri" = {
        JIMPrefLiveConversionKey = false;
      };

      # Locale and preferred languages.
      NSGlobalDomain = {
        AppleLanguages = [
          "en-JP"
          "ja-JP"
        ];
        AppleLocale = "en_JP";
      };
    };

    # User-wide macOS defaults such as appearance, keyboard repeat, and input.
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      AppleKeyboardUIMode = 0;
      ApplePressAndHoldEnabled = false;
      AppleShowAllExtensions = true;
      AppleSpacesSwitchOnActivate = false;
      InitialKeyRepeat = 15;
      KeyRepeat = 2;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSTableViewDefaultSizeMode = 1;
      "com.apple.keyboard.fnState" = false;
      "com.apple.springing.delay" = 0.5;
      "com.apple.springing.enabled" = true;
      "com.apple.swipescrolldirection" = false;
      "com.apple.trackpad.forceClick" = true;
      "com.apple.trackpad.scaling" = 0.6875;
    };

    # Control Center and menu bar items.
    controlcenter = {
      BatteryShowPercentage = true;
    };

    # Dock layout, pinned apps, stacks, gestures, and hot corners.
    dock = {
      autohide = true;
      largesize = 16;
      magnification = false;
      mru-spaces = false;
      persistent-apps = [
        "/Applications/Vivaldi.app"
        "/Applications/Craft.app"
        "/Applications/Ghostty.app"
      ];
      persistent-others = [
        {
          folder = {
            path = "${homeDirectory}/Downloads";
            arrangement = "date-added";
            displayas = "stack";
            showas = "fan";
          };
        }
      ];
      show-recents = false;
      showAppExposeGestureEnabled = true;
      showDesktopGestureEnabled = false;
      showLaunchpadGestureEnabled = false;
      showMissionControlGestureEnabled = true;
      tilesize = 58;
      wvous-br-corner = 14;
    };

    # Finder visibility, default view, search scope, and desktop devices.
    finder = {
      AppleShowAllExtensions = true;
      AppleShowAllFiles = true;
      FXDefaultSearchScope = "SCev";
      FXEnableExtensionChangeWarning = false;
      FXPreferredViewStyle = "Nlsv";
      NewWindowTarget = "Home";
      ShowExternalHardDrivesOnDesktop = true;
      ShowHardDrivesOnDesktop = false;
      ShowMountedServersOnDesktop = true;
      ShowPathbar = true;
      ShowRemovableMediaOnDesktop = true;
      ShowStatusBar = true;
      _FXShowPosixPathInTitle = true;
      _FXSortFoldersFirst = true;
    };

    # Screenshot behavior.
    screencapture = {
      target = "clipboard";
    };

    # Clock display in the menu bar.
    menuExtraClock = {
      ShowAMPM = true;
      ShowDate = 0;
      ShowDayOfWeek = true;
    };
  };
}
