{
  lib,
  inputs,
  self,
  ...
}: {
  perSystem = {
    pkgs,
    self',
    ...
  }: let
    myTools = [
      # nix
      pkgs.alejandra
      pkgs.devenv
      pkgs.manix
      pkgs.nil
      pkgs.nixd
      pkgs.nix-inspect
      pkgs.statix
      self'.packages.nh

      # other
      pkgs.bat
      pkgs.brightnessctl
      pkgs.btop
      pkgs.cliphist
      pkgs.eza
      pkgs.fd
      pkgs.ffmpeg-full
      pkgs.file
      pkgs.glow
      pkgs.htop
      pkgs.imagemagick
      pkgs.impala
      pkgs.imv
      pkgs.jq
      pkgs.killall
      pkgs.microfetch
      pkgs.openspec
      pkgs.p7zip
      pkgs.ripgrep
      pkgs.serie
      pkgs.sshfs
      pkgs.tree-sitter
      pkgs.unzip
      pkgs.wget
      pkgs.wiremix
      pkgs.wl-clipboard
      pkgs.wtype
      pkgs.zip
      pkgs.zoxide

      # wrapped
      self'.packages.ccmux
      self'.packages.fzf
      self'.packages.git
      self'.packages.helix
      self'.packages.herdr
      self'.packages.jjui
      self'.packages.jujutsu
      self'.packages.kakoune
      self'.packages.nix-check-bin
      self'.packages.oh-my-posh
      self'.packages.pi
      self'.packages.skillopt-sleep
      self'.packages.tuicr
      self'.packages.tuicr-agent-review
      self'.packages.tmux
      self'.packages.tmux-project
      self'.packages.tmux-repo
    ];
    combinedCompletions = pkgs.buildEnv {
      name = "env-completions";
      paths = myTools;
      pathsToLink = ["/share/zsh/site-functions"];
    };
  in {
    packages = {
      # My whole desktop in one package: niri wired to my terminal and editor
      desktop = inputs.wrapper-modules.wrappers.niri.wrap {
        inherit pkgs;
        imports = [self.wrappersModules.niri];
        terminal = lib.getExe self'.packages.terminal;
        env = {
          EDITOR = lib.getExe self'.packages.kakoune;
        };
      };

      # My primary flake terminal
      terminal = self'.packages.ghostty;

      # My primary flake shell with all of it's packages
      environment = inputs.wrappers.lib.wrapPackage {
        inherit pkgs;
        package = self'.packages.zsh;
        runtimeInputs = myTools;
        env = {
          EDITOR = lib.getExe self'.packages.kakoune;
          # New tmux panes inherit this environment instead of an older profile.
          SHELL = lib.getExe self'.packages.zsh;
        };
      };

      completions = combinedCompletions;

      nix-check-bin = pkgs.writeShellApplication {
        name = "nix-check-bin";
        text = ''
          $EDITOR "$(nix build "$1" --no-link --print-out-paths)/bin"
        '';
      };
    };
  };
}
