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
      pkgs.nil
      pkgs.nixd
      pkgs.statix
      pkgs.alejandra
      pkgs.manix
      pkgs.nix-inspect
      self'.packages.nh

      # other
      pkgs.file
      pkgs.unzip
      pkgs.zip
      pkgs.p7zip
      pkgs.wget
      pkgs.killall
      pkgs.sshfs
      pkgs.fzf
      pkgs.htop
      pkgs.btop
      pkgs.eza
      pkgs.fd
      pkgs.zoxide
      # pkgs.dust
      pkgs.ripgrep
      pkgs.microfetch
      pkgs.tree-sitter
      pkgs.imagemagick
      pkgs.imv
      pkgs.ffmpeg-full
      # pkgs.yt-dlp
      pkgs.serie

      # wrapped
      self'.packages.oh-my-posh
      self'.packages.helix
      # self'.packages.neovimDynamic
      # self'.packages.qalc
      # self'.packages.lf
      self'.packages.git
      # self'.packages.jujutsu
      # self'.packages.jjui
      self'.packages.nix-check-bin
    ];
    combinedCompletions =
      pkgs.runCommand "env-completions"
      {
        dirs = lib.concatMapStringsSep " " (p: "${lib.getOutput "out" p}/share/zsh/site-functions") myTools;
      }
      ''
        mkdir -p $out
        for dir in $dirs; do
          if [ -d "$dir" ]; then
            for f in "$dir"/*; do
              ln -s "$f" $out/
            done
          fi
        done
      '';
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
