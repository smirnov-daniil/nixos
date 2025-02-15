{pkgs, ...}: {
  nixpkgs.config.allowUnfree = true;

  home.packages = with pkgs; [
    # Desktop apps
    ayugram-desktop # messager
    imv # cl image viewer
    jetbrains.idea-ultimate # IDE
    localsend # share files
    mpv # cl video viewer
    obs-studio # screen capture
    zen-browser # browser

    # CLI utils
    bat # dispplay file content
    bottom # performance monitor
    brightnessctl # cl screan brightness control
    cliphist # cl clipboard history
    ffmpeg # multimedia converter
    fzf # better navigation
    grimblast # screenshot
    microfetch # system info
    ripgrep # cl search
    unzip # extract files from zip
    wget # cl web downloader
    wl-clipboard # wayland clipboard
    wtype # wayland keyboard input simulator
    zip # zip files

    # WM stuff
    libsForQt5.xwaylandvideobridge # impove vide in wayland QT apps
    xdg-desktop-portal-gtk # gtk basef portal for desktop integration in sandboxed apps
    xdg-desktop-portal-hyprland # same, but hyperland-specific
  ];
}
