{
  description = "micanis dotfiles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # AI coding agents (Claude Code, Codex) packaged outside nixpkgs.
    llm-agents.url = "git+https://github.com/numtide/llm-agents.nix.git?shallow=1";
  };

  outputs =
    inputs@{
      nixpkgs,
      home-manager,
      nix-darwin,
      ...
    }:
    let
      username = "micanis";
      homeStateVersion = "25.05";

      # Extra arguments available to every module, both system-level
      # (nix-darwin / NixOS) and Home Manager.
      argsFor = homeDirectory: {
        inherit
          inputs
          username
          homeStateVersion
          homeDirectory
          ;
      };
      darwinArgs = argsFor "/Users/${username}";
      linuxArgs = argsFor "/home/${username}";

      pkgsFor =
        system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

      # Standalone Home Manager for non-NixOS Linux.
      mkHome =
        hostModule:
        home-manager.lib.homeManagerConfiguration {
          pkgs = pkgsFor "x86_64-linux";
          extraSpecialArgs = linuxArgs;
          modules = [ hostModule ];
        };

      forAllSystems = nixpkgs.lib.genAttrs [
        "aarch64-darwin"
        "x86_64-linux"
      ];
    in
    {
      darwinConfigurations.darwin = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        specialArgs = darwinArgs;
        modules = [
          ./hosts/darwin
          home-manager.darwinModules.home-manager
        ];
      };

      homeConfigurations = {
        linux-gui = mkHome ./hosts/linux-gui/home.nix;
        linux-headless = mkHome ./hosts/linux-headless/home.nix;
      };

      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = linuxArgs;
        modules = [
          ./hosts/nixos/configuration.nix
          home-manager.nixosModules.home-manager
        ];
      };

      # `nix develop` gives the tools used to edit and lint this repository.
      devShells = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              git
              nixfmt
              nil
              statix
              deadnix
            ];
          };
        }
      );
    };
}
