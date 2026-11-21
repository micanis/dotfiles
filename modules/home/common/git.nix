{
  programs = {
    git = {
      enable = true;
      settings = {
        user.name = "micanis";
        init.defaultBranch = "main";
        pull.rebase = true;
        push.autoSetupRemote = true;
        http."https://git.crane.home.arpa/" = {
          sslCAInfo = "/Users/micanis/.config/git/certs/crane-root.crt";
        };
      };
    };

    delta = {
      enable = true;
      enableGitIntegration = true;
    };

    gh = {
      enable = true;
      gitCredentialHelper.enable = true;
    };
  };
}
