{
  pkgs,
  stateVersion,
  hostname,
  inputs,
  ...
}: let
user = "ds2";
system = "x86_64-linux";
in
{
  imports = [
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
#   sharedModules = [{inputs.stylix.targets.xyz.enable = false;}];
    extraSpecialArgs = {
      inherit inputs;
      pkgs = import inputs.nixpkgs {
      inherit system;
        config.allowUnfree = true;
        overlays = [
          (final: prev: {
            zen-browser = inputs.zen-browser.packages.${system}.default;
          })
        ];
      };
    };
    users = {
      "ds2" = import ./users/ds2.nix;
    };
  };
}
