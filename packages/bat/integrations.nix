{
  lib,
  inputs,
  ...
}: {
  perSystem = {
    pkgs,
    self',
    ...
  }: let
    extras = pkgs.bat-extras;
    wrapExtra = package: runtimeInputs:
      inputs.wrappers.lib.wrapPackage {
        inherit pkgs package;
        runtimeInputs = [self'.packages.bat pkgs.coreutils pkgs.gnused] ++ runtimeInputs;
      };
  in {
    packages = {
      batgrep = wrapExtra extras.batgrep [];
      batman = wrapExtra extras.batman [pkgs.bash pkgs.man-db self'.packages.fzf extras.batman];
      batwatch = wrapExtra extras.batwatch [];

      bat-man-pager = pkgs.writeShellApplication {
        name = "bat-man-pager";
        text = ''
          export BATMAN_IS_BEING_MANPAGER=yes
          exec ${lib.getExe self'.packages.batman} "$@"
        '';
      };

      batfd = pkgs.writeShellApplication {
        name = "batfd";
        runtimeInputs = [pkgs.fd self'.packages.bat];
        text = ''
          exec fd --type f --exec-batch bat -- ';' "$@"
        '';
      };

      battail = pkgs.writeShellApplication {
        name = "battail";
        runtimeInputs = [pkgs.coreutils self'.packages.bat];
        text = ''
          if (( $# == 0 )); then
            printf 'Usage: battail [tail options] FILE...\n' >&2
            exit 2
          fi
          tail --follow=name --retry "$@" | bat --paging=never --style=plain --language=log
        '';
      };
    };

    checks.bat-integrations =
      pkgs.runCommand "bat-integration-tests" {
        nativeBuildInputs = [
          pkgs.python3
          pkgs.man-db
          pkgs.groff
          self'.packages.batfd
          self'.packages.batgrep
          self'.packages.batman
          self'.packages.battail
          self'.packages.batwatch
        ];
        MANPAGER = lib.getExe self'.packages.bat-man-pager;
        MANROFFOPT = "-c";
        BAT_TEST_FZF_FILES = lib.getExe self'.packages.fzf-files;
        BAT_TEST_FZF = lib.getExe self'.packages.fzf;
        BAT_TEST_BAT = lib.getExe self'.packages.bat;
      } ''
        export HOME="$TMPDIR/home"
        mkdir -p "$HOME"
        python3 -B ${./test_integrations.py} -v
        touch "$out"
      '';
  };
}
