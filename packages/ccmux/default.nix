{
  inputs,
  lib,
  self,
  ...
}: {
  perSystem = {
    pkgs,
    self',
    ...
  }: let
    dependencies = pkgs.stdenvNoCC.mkDerivation {
      pname = "ccmux-bun-dependencies";
      version = "1.4.2";
      src = inputs.ccmux;
      nativeBuildInputs = [pkgs.bun pkgs.cacert];
      dontConfigure = true;
      dontFixup = true;
      buildPhase = ''
        export BUN_INSTALL_CACHE_DIR="$TMPDIR/bun-cache"
        bun install --frozen-lockfile --ignore-scripts
      '';
      installPhase = ''cp -r node_modules "$out"'';
      outputHashMode = "recursive";
      outputHashAlgo = "sha256";
      outputHash = "sha256-KNkX4E+TRboYW8UuZaisOvv7xH27Hj9RaqyBTrY8IMs=";
    };
    ccmux = pkgs.stdenv.mkDerivation rec {
      pname = "ccmux";
      version = "1.4.2";
      src = inputs.ccmux;
      nativeBuildInputs = [pkgs.bun pkgs.autoPatchelfHook pkgs.makeWrapper];
      buildInputs = [pkgs.stdenv.cc.cc.lib];
      # Bun's executable embeds the platform OpenTUI module and native assets.
      # Keep that payload intact when autoPatchelf adjusts the ELF loader.
      dontStrip = true;
      patches = [./tuicr.patch ./no-pane-flash.patch ./theme-background.patch ./agent-project-session.patch ./existing-agent-pane.patch];
      postPatch = ''
        cp ${./tuicr-review.ts} src/tui/utils/tuicr-review.ts
        cp ${./tuicr-review.test.ts} src/tui/utils/tuicr-review.test.ts
        cp ${./agent-project-session.ts} src/tui/utils/agent-project-session.ts
        cp ${./agent-project-session.test.ts} src/tui/utils/agent-project-session.test.ts
        cp ${./existing-agent-pane.ts} src/tui/utils/existing-agent-pane.ts
        cp ${./existing-agent-pane.test.ts} src/tui/utils/existing-agent-pane.test.ts
      '';
      buildPhase = ''
        runHook preBuild
        cp -r ${dependencies} node_modules
        chmod -R u+w node_modules
        bun node_modules/typescript/bin/tsc --noEmit
        bun test src/tui/utils/tuicr-review.test.ts
        bun test src/tui/utils/agent-project-session.test.ts src/tui/utils/existing-agent-pane.test.ts src/tui/utils/tmux.test.ts
        bun run build.ts
        bun build dist/index.js --compile --no-compile-autoload-bunfig --outfile ccmux
        runHook postBuild
      '';
      installPhase = ''
        runHook preInstall
        install -Dm755 ccmux "$out/bin/ccmux"
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
      theme = {
        colors = with self.theme; {
          base = base00;
          surface = base01;
          border = base02;
          overlay = base03;
          subtext = base04;
          text = base05;
          rosewater = base0D;
          red = base08;
          peach = base09;
          yellow = base0A;
          green = base0B;
          teal = base0C;
          blue = base0D;
          mauve = base0E;
        };
        ansi = with self.theme; {
          black = base00;
          red = base08;
          green = base0B;
          yellow = base0A;
          blue = base0D;
          magenta = base0E;
          cyan = base0C;
          white = base05;
          brightBlack = base03;
          brightRed = base08;
          brightGreen = base0B;
          brightYellow = base0A;
          brightBlue = base0D;
          brightMagenta = base0E;
          brightCyan = base0C;
          brightWhite = base07;
        };
      };
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
          --prefix PATH : ${lib.makeBinPath [self'.packages.tuicr-agent-review pkgs.tmux pkgs.git pkgs.procps pkgs.lsof pkgs.libnotify pkgs.jq pkgs.coreutils pkgs.gnugrep pkgs.bash]} \
          --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [pkgs.stdenv.cc.cc.lib]} \
          --run 'ccmux_dir="''${CCMUX_HOME:-$HOME/.config/ccmux}"; if [ ! -e "$ccmux_dir/ccmux.json" ]; then mkdir -p "$ccmux_dir"; cp -n ${defaults} "$ccmux_dir/ccmux.json"; chmod u+w "$ccmux_dir/ccmux.json"; fi'
        makeWrapper ${pkgs.python3}/bin/python3 "$out/bin/ccmux-setup" \
          --add-flags ${./setup.py} \
          --add-flags "$out/bin/ccmux" \
          --add-flags ${pkgs.bash}/bin/bash \
          --add-flags ${lib.makeBinPath [pkgs.jq pkgs.procps pkgs.coreutils pkgs.gnugrep pkgs.gnused]}
      '';
      inherit (ccmux) meta;
      passthru.defaultConfig = defaults;
    };
  };
}
