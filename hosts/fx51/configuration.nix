{
  pkgs,
  stateVersion,
  hostname,
  ...
}: {
  imports = [
    inputs.stylix.nixosModules.stylix
    inputs.home-manager.nixosModules.default
    ./hardware-configuration.nix
    ./local-packages.nix
    ../../modules/nixos
    ./modules
  ];

  nixpkgs.config.allowUnfree = true;

  environment = {
    systemPackages = [pkgs.home-manager];
    sessionVariables = rec {
      TERMINAL = "ghostty";
      XDG_BIN_HOME = "$HOME/.local/bin";
      PATH = [
        "${XDG_BIN_HOME}"
      ];
    };
  };

  networking.hostName = hostname;

  system.stateVersion = stateVersion;

  main-user = {
    enable = true;
    username = user;
  };

  home-manager = {
    extraSpecialArgs = {
      inherit inputs;
      pkgs = import nixpkgs {
        config.allowUnfree = true;
        overlays = [
          (final: prev: {
            zen-browser = inputs.zen-browser.packages.${system}.default;
          })
        ];
      };
    };

    users = {
      "ds2" = import ./ds2.nix;
    };
  };
}
