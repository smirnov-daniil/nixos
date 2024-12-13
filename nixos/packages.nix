{ pkgs, ... }: {
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    # Packages in each category are sorted alphabetically

    # Desktop apps
    alacritty
    blueman
    vivaldi
    fuzzel
    imv
    mpv
    obs-studio
    obsidian
    telegram-desktop
#    wofi

    # CLI utils
    bottom
    brightnessctl
    cliphist
    ffmpeg
    git
    grimblast
    htop
    lazygit
    lf
    microfetch
    playerctl
    ripgrep
    silicon
    starship
    swww
    tmux
    tree
    unzip
    vim
    wget
    wl-clipboard
    wtype
    yt-dlp
    zip

    # Coding stuff

    # WM stuff
    hyprpicker
    libsForQt5.xwaylandvideobridge
    libnotify
    waybar
    xdg-desktop-portal-gtk
    xdg-desktop-portal-hyprland

    # Other
    bemoji
    home-manager
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
