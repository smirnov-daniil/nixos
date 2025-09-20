{
  description = "My system configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";

    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";

    nix-minecraft.url = "github:Infinidoge/nix-minecraft";

    vscode-server.url = "github:nix-community/nixos-vscode-server";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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
    hosts = [
      {
        hostname = "fx51";
        stateVersion = "25.05";
      }
      {
        hostname = "wsl";
        stateVersion = "25.05";
      }
      {
        hostname = "msi";
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
            system
            ;
        };

        modules = [
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
  };
}
