{ pkgs, ... }:
{
  nixpkgs.config.allowUnfree = true;

  home.packages = with pkgs; [
    # Desktop apps
    imv # cl image viewer
    mpv # cl video viewer
    obs-studio # screen capture
    telegram-desktop # messager
    localsend # share files

    # CLI utils
    bottom # performance monitor
    fzf # better navigation
    brightnessctl # cl screan brightness control
    cliphist # cl clipboard history
    ffmpeg # multimedia converter
    grimblast # screenshot
    lf # file manager
    microfetch # system info
    ripgrep # cl search
    unzip # extract files from zip
    wget # cl web downloader
    wl-clipboard # wayland clipboard
    wtype # wayland keyboard input simulator
    zip # zip files

    # vpn
    networkmanager-l2tp

    # Coding stuff
    nixd # nix LSP
    alejandra # nix syntax
    #jetbrains.clion

    # WM stuff
    libsForQt5.xwaylandvideobridge # impove vide in wayland QT apps
    xdg-desktop-portal-gtk # gtk basef portal for desktop integration in sandboxed apps
    xdg-desktop-portal-hyprland # same, but hyperland-specific
  ];
}
