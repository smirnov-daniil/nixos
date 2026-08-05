{self, ...}: {
  flake.nixosModules.zen-browser = {
    pkgs,
    lib,
    config,
    ...
  }: let
    cfg = config.programs.zen-browser;
  in {
    options.programs.zen-browser.package = lib.mkOption {
      type = lib.types.package;
      default = self.packages.${pkgs.stdenv.hostPlatform.system}.zen-browser-plain;
    };

    config.environment.systemPackages = [cfg.package];
  };
}
