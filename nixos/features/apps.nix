_: {
  flake.nixosModules.apps = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.features.apps;
  in {
    options.features.apps.enable =
      lib.mkEnableOption "graphical applications that are not part of the wrapped CLI environment";

    config = lib.mkIf cfg.enable {
      environment.systemPackages = with pkgs; [
        localsend
        mpv
        obs-studio
        telegram-desktop
        vscode
      ];
    };
  };
}
