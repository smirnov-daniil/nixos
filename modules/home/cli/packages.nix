{
  pkgs,
  lib,
  config,
  ...
}: {
  options.cli = {
    tools.enable = lib.mkEnableOption "enables cli tools";
    utils.enable = lib.mkEnableOption "enables cli utils";
  };

  config = lib.mkMerge [
    (lib.mkIf config.cli.tools.enable {
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
    (lib.mkIf config.cli.utils.enable {
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
