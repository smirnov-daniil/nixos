{lib, ...}: {
  perSystem = {pkgs, ...}: let
    # Preserve the embedded Bun bundle and OpenTUI assets during ELF patching.
    ccmux = pkgs.stdenv.mkDerivation rec {
      pname = "ccmux";
      version = "1.4.2";
      src = pkgs.fetchurl {
        url = "https://github.com/epilande/ccmux/releases/download/v${version}/ccmux-linux-x64";
        hash = "sha256-tO7vaqwAf38BaZZHpl+U+5cmBVS4KrAS+xV3o429S1s=";
      };
      dontUnpack = true;
      dontStrip = true;
      nativeBuildInputs = [pkgs.autoPatchelfHook];
      buildInputs = [pkgs.stdenv.cc.cc.lib];
      installPhase = ''
        runHook preInstall
        install -Dm755 "$src" "$out/bin/ccmux"
        runHook postInstall
      '';
      meta = {
        description = "Agent status, navigation and notifications for tmux";
        homepage = "https://github.com/epilande/ccmux";
        license = lib.licenses.mit;
        platforms = ["x86_64-linux"];
        mainProgram = "ccmux";
      };
    };
    defaults = pkgs.writeText "ccmux.json" (builtins.toJSON {
      groupBy = "session";
      showPreview = true;
      promptDisplay = "row2";
      sidebar = {
        width = 32;
        position = "left";
      };
      notifications = {
        enabled = true;
        events = ["waiting" "finished"];
        backend = "auto";
      };
    });
  in {
    packages.ccmux = pkgs.symlinkJoin {
      name = "ccmux-${ccmux.version}";
      paths = [ccmux];
      nativeBuildInputs = [pkgs.makeWrapper];
      postBuild = ''
        wrapProgram "$out/bin/ccmux" \
          --prefix PATH : ${lib.makeBinPath [pkgs.tmux pkgs.git pkgs.procps pkgs.lsof pkgs.libnotify pkgs.jq pkgs.coreutils pkgs.gnugrep pkgs.bash]} \
          --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [pkgs.stdenv.cc.cc.lib]} \
          --run 'ccmux_dir="''${CCMUX_HOME:-$HOME/.config/ccmux}"; if [ ! -e "$ccmux_dir/ccmux.json" ]; then mkdir -p "$ccmux_dir"; cp -n ${defaults} "$ccmux_dir/ccmux.json"; chmod u+w "$ccmux_dir/ccmux.json"; fi'
        makeWrapper ${pkgs.python3}/bin/python3 "$out/bin/ccmux-setup" \
          --add-flags ${./setup.py} \
          --add-flags "$out/bin/ccmux" \
          --add-flags ${pkgs.bash}/bin/bash \
          --add-flags ${lib.makeBinPath [pkgs.jq pkgs.procps pkgs.coreutils pkgs.gnugrep pkgs.gnused]}
      '';
      inherit (ccmux) meta;
    };
  };
}
