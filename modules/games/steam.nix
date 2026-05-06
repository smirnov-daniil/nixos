{
  lib,
  config,
  ...
}: {
  options = {
    games.steam.enable = lib.mkEnableOption "enables games";
  };

  config = lib.mkIf config.games.steam.enable {
    programs = {
      steam = {
        enable = true;
        gamescopeSession.enable = true;
      };
      # steamd = {
      #   enable = true;
      # };
      # steam-tui = {
      #   enable = true;
      # };
      # gamescope = {
      #   ebable = true;
      #   capSysNice = true;
      # };
    };
  };
}
