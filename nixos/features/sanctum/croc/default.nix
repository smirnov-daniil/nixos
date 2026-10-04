{
  self,
  inputs,
  ...
}: {
  flake.nixosModules.sanctum-croc = {
    config,
    pkgs,
    lib,
    ...
  }:
    with lib; let
      cfg = config.sanctum.croc;
    in {
      imports = [
        self.nixosModules.sanctum-core
        inputs.sops-nix.nixosModules.default
      ];

      options.sanctum.croc = {
        enable = mkEnableOption "Croc file transfer";
        port = mkOption {
          type = types.port;
          default = 9009;
          description = "First croc relay port; the next port carries transfers. Both must be reachable from clients.";
        };
      };

      # The relay speaks raw TCP on its own ports (clients connect to the first,
      # then to the transfer port it advertises), so nginx cannot front it.
      config = mkIf cfg.enable {
        sops.secrets.croc.restartUnits = ["croc.service"];

        # The relay runs as a DynamicUser and cannot read the root-only SOPS
        # file; croc would then silently use the path itself as the password.
        systemd.services.croc.serviceConfig.LoadCredential = ["pass:${config.sops.secrets.croc.path}"];

        services.croc = {
          enable = true;
          ports = [cfg.port (cfg.port + 1)];
          pass = "/run/credentials/croc.service/pass";
          openFirewall = true;
        };
      };
    };
}
