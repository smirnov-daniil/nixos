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
        fd # files search
        ffmpeg # multimedia converter
        grex # regex generator
        impala # networks manager
        jrnl # Thoughts journal
        microfetch # system info
        ripgrep # cl search
        serie # git commits viewer
        unzip # extract files from zip
        wget # cl web downloader
        wiremix # audio manager
        zip # zip files
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
