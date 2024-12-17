{
  description = "My system configuration";

  inputs = {

    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";

    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix.url = "github:danth/stylix";

    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      homeStateVersion = "24.11";
      user = "ds2";
      hosts = [
        {
          hostname = "fx51";
          stateVersion = "24.11";
        }
      ];

      makeSystem =
        { hostname, stateVersion }:
        nixpkgs.lib.nixosSystem {
          system = system;
          specialArgs = {
            inherit
              inputs
              stateVersion
              hostname
              user
              ;
          };

          modules = [
            ./hosts/${hostname}/configuration.nix
          ];
        };

    in
    {
      nixosConfigurations = nixpkgs.lib.foldl' (
        configs: host:
        configs
        // {
          "${host.hostname}" = makeSystem {
            inherit (host) hostname stateVersion;
          };
        }
      ) { } hosts;

      homeConfigurations.${user} = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [ inputs.nix-vscode-extensions.overlays.default ];
        };
        extraSpecialArgs = {
          inherit inputs homeStateVersion user;
        };

        modules = [
          ./home-manager/home.nix
        ];
      };
    };
}
