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
      pkgs.manix
      pkgs.nil
      pkgs.nixd
      pkgs.nix-inspect
      pkgs.statix
      self'.packages.nh

      # other
      pkgs.bat
      pkgs.btop
      pkgs.eza
      pkgs.fd
      pkgs.ffmpeg-full
      pkgs.file
      pkgs.glow
      pkgs.htop
      pkgs.imagemagick
      pkgs.imv
      pkgs.killall
      pkgs.microfetch
      pkgs.p7zip
      pkgs.ripgrep
      pkgs.serie
      pkgs.sshfs
      pkgs.tree-sitter
      pkgs.unzip
      pkgs.wget
      pkgs.zip
      pkgs.zoxide

      # wrapped
      self'.packages.fzf
      self'.packages.git
      self'.packages.helix
      self'.packages.jjui
      self'.packages.jujutsu
      self'.packages.nix-check-bin
      self'.packages.oh-my-posh
      self'.packages.zellij
    ];
    combinedCompletions = pkgs.buildEnv {
      name = "env-completions";
      paths = myTools;
      pathsToLink = ["/share/zsh/site-functions"];
    };
  in {
    # My whole desktop in one package, includes kityy terminal
    packages.desktop = inputs.wrapper-modules.wrappers.niri.wrap {
      inherit pkgs;
      imports = [self.wrappersModules.niri];
      terminal = lib.getExe self'.packages.terminal;
      env = {
        EDITOR = lib.getExe self'.packages.helix;
      };
    };

    # My primary flake terminal
    packages.terminal = self'.packages.ghostty;

    # My primary flake shell with all of it's packages
    packages.environment = inputs.wrappers.lib.wrapPackage {
      inherit pkgs;
      package = self'.packages.zsh;
      runtimeInputs = myTools;
      env = {
        EDITOR = lib.getExe self'.packages.helix;
      };
    };

    packages.completions = combinedCompletions;

    packages.nix-check-bin = pkgs.writeShellApplication {
      name = "nix-check-bin";
      text = ''
        $EDITOR "$(nix build "$1" --no-link --print-out-paths)/bin"
      '';
    };
  };
}
