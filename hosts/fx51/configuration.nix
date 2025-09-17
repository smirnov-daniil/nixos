{
  pkgs,
  stateVersion,
  hostname,
  ...
}: {
  imports = [
    inputs.stylix.nixosModules.stylix
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
}
