{pkgs, ...}: {
  nixpkgs.config.allowUnfree = true;

  home.packages = with pkgs; [
    # Desktop apps
    imv # cl image viewer
    localsend # share files
    mpv # cl video viewer
    obs-studio # screen capture
    ayugram-desktop # messager

    # CLI utils
    bat # dispplay file content
    brightnessctl # cl screan brightness control
    cliphist # cl clipboard history
    ffmpeg # multimedia converter
    fzf # better navigation
    grimblast # screenshot
    htop
    bottom # performance monitor
    microfetch # system info
    ripgrep # cl search
    unzip # extract files from zip
    wget # cl web downloader
    wl-clipboard # wayland clipboard
    wtype # wayland keyboard input simulator
    zip # zip files

    # Browser
    zen-browser

    # Coding stuff
    nixd # nix LSP
    jetbrains.idea-ultimate

    # WM stuff
    libsForQt5.xwaylandvideobridge # impove vide in wayland QT apps
    xdg-desktop-portal-gtk # gtk basef portal for desktop integration in sandboxed apps
    xdg-desktop-portal-hyprland # same, but hyperland-specific
  ];
}
