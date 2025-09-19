{
  pkgs,
  lib,
  config,
  ...
}: {
  options.cli = {
    tools.use = lib.mkEnableOption "enables cli tools";
    utils.use = lib.mkEnableOption "enables cli utils";
  };

  config = lib.mkMerge [
    (lib.mkIf config.cli.tools.use {
      home.packages = with pkgs; [
        bat # dispplay file content
        bottom # performance monitor
        microfetch # system info
        ripgrep # cl search
        wget # cl web downloader
        unzip # extract files from zip
        zip # zip files
        ffmpeg # multimedia converter
      ];
    })
    (lib.mkIf config.cli.utils.use {
      home.packages = with pkgs; [
        brightnessctl # cl screan brightness control
        cliphist # cl clipboard history
        grimblast # screenshot
        wl-clipboard # wayland clipboard
        wtype # wayland keyboard input simulator
      ];
    })
  ];
}
