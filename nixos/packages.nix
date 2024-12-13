{ pkgs, ... }: {
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    # Desktop apps
    alacritty           # termianl emulator
    blueman             # bluetoorh gui
    chromium
    vivaldi             # browser
    fuzzel              # app launcher
    imv                 # cl image viewer
    mpv                 # cl video viewer 
    obs-studio          # screen capture
    telegram-desktop    # messager

    # CLI utils
    bottom              # performance monitor
    brightnessctl       # cl screan brightness control
    cliphist            # cl clipboard history
    ffmpeg              # multimedia converter
    git                 # version control system
    grimblast           # screenshot
    lazygit             # terminal ui for git
    lf                  # file manager
    microfetch          # system info
    ripgrep             # cl search
    starship            # shell castomizer (replace with oh-my-posh)
    tmux                # terminal multiplexer
    unzip               # extract files from zip
    wget                # cl web downloader
    wl-clipboard        # wayland clipboard
    wtype               # wayland keyboard input simulator
    zip                 # zip files

    # Coding stuff

    # WM stuff
    hyprlock                       # lock screen
    libsForQt5.xwaylandvideobridge # impove vide in wayland QT apps
    waybar                         # wayland status bar
    xdg-desktop-portal-gtk         # gtk basef portal for desktop integration in sandboxed apps
    xdg-desktop-portal-hyprland    # same, but hyperland-specific

    # Other
    home-manager      # nix home manager
  ];

  fonts.packages = with pkgs; [
    jetbrains-mono
    noto-fonts
    noto-fonts-emoji
    twemoji-color-font
    font-awesome
    powerline-fonts
    powerline-symbols
    (nerdfonts.override { fonts = [ "NerdFontsSymbolsOnly" ]; })
  ];
}
