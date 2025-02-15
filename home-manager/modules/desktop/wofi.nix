{
  lib,
  config,
  ...
}: {
  options = {
    wofi.use = lib.mkEnableOption "enables wofi";
  };

  config = lib.mkIf config.wofi.use {
    programs.wofi = {
      enable = true;
      settings = {
        allow_markup = true;
        allow_images = true;
        width = 350;
        height = 450;
      };
    };
  };
}
