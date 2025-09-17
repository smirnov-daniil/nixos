{
  description = "My system configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";

    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";

    vscode-server.url = "github:nix-community/nixos-vscode-server";

    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:danth/stylix/release-25.05";
      #      inputs.nixpkgs.follows = "nixpkgs";
    };

    gBar = {
      url = "github:scorpion-26/gBar";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    homeStateVersion = "25.05";
    user = "ds2";
    hosts = [
      {
        hostname = "fx51";
        stateVersion = "25.05";
      }
      {
        hostname = "wsl";
        stateVersion = "25.05";
      }
    ];

    makeSystem = {
      hostname,
      stateVersion,
    }:
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
          {nixpkgs.config.allowUnfree = true;}
          ./hosts/${hostname}/configuration.nix
        ];
      };
  in {
    nixosConfigurations =
      nixpkgs.lib.foldl' (
        configs: host:
          configs
          // {
            "${host.hostname}" = makeSystem {
              inherit (host) hostname stateVersion;
            };
          }
      ) {}
      hosts;

    homeConfigurations.${user} = home-manager.lib.homeManagerConfiguration {
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [
          (final: prev: {
            zen-browser = inputs.zen-browser.packages.${system}.default;
          })
        ];
      };
      extraSpecialArgs = {
        inherit inputs homeStateVersion user;
      };

      modules = [
        ./home-manager/home.nix
        ./home-manager/modules
      ];
    };
  };
}
