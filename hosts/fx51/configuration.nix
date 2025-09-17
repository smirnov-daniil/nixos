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
    ../../nixos/modules
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

  home-manager = {
    extraSpecialArgs = {
      inherit inputs;
    };

    users = {
      "ds2" = import ./home.nix;
    };

    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
      overlays = [
        (final: prev: {
          zen-browser = inputs.zen-browser.packages.${system}.default;
        })
      ];
    };
  };
}
