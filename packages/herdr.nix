{inputs, lib, ...}: {
  perSystem = {pkgs, ...}: let
    herdrSrc = pkgs.fetchFromGitHub {
      owner = "herdrdev";
      repo = "herdr";
      rev = "ef4c23f5775bb8cfec05f05d0844226ff959a07a";
      hash = "sha256-3BA8eredGku+vsL2Af7sUf43QiArR5XTHNrI+X11vFM=";
    };
    herdrBase = pkgs.callPackage "${herdrSrc}/nix/package.nix" {};
    herdrMirrorVersion = "0.1.15";
    herdrMirrorSrc = pkgs.fetchFromGitHub {
      owner = "nikok6";
      repo = "herdr-mirror";
      rev = "ac72ab54689fd63fbd13cd0eaca525c7f3ab7f81";
      hash = "sha256-29PS68pDy5B5LCvTR31wUcRVNAzGP4menVBBEl7WSMo=";
    };
    hostsTemplate = pkgs.writeText "herdr-mirror-hosts.toml" ''
      [hosts.work]
      target = "user@workbox"
    '';
    herdrMirrorInit = pkgs.writeShellApplication {
      name = "herdr-mirror-init";
      runtimeInputs = [pkgs.coreutils];
      text = ''
        config_dir="''${XDG_CONFIG_HOME:-$HOME/.config}/herdr-mirror"
        config_file="$config_dir/hosts.toml"

        mkdir -p "$config_dir"

        if [ -e "$config_file" ]; then
          printf '%s\n' "$config_file already exists"
          exit 0
        fi

        cp ${hostsTemplate} "$config_file"
        printf '%s\n' "Wrote $config_file"
      '';
    };
    herdrMirrorBin = pkgs.rustPlatform.buildRustPackage {
      pname = "herdr-mirror-bin";
      version = herdrMirrorVersion;
      src = herdrMirrorSrc;
      cargoLock = {
        lockFile = "${herdrMirrorSrc}/Cargo.lock";
      };
    };
    herdrMirror = pkgs.stdenvNoCC.mkDerivation {
      pname = "herdr-mirror";
      version = herdrMirrorVersion;
      dontUnpack = true;
      nativeBuildInputs = [pkgs.makeWrapper];
      installPhase = ''
        runHook preInstall
        mkdir -p $out/bin $out/target/release $out/share/herdr-mirror
        cp ${herdrMirrorSrc}/herdr-plugin.toml $out/herdr-plugin.toml
        cp ${herdrMirrorSrc}/README.md $out/share/herdr-mirror/README.md
        cp ${hostsTemplate} $out/share/herdr-mirror/hosts.toml.example
        ln -s ${herdrMirrorInit}/bin/herdr-mirror-init $out/bin/herdr-mirror-init
        makeWrapper ${herdrMirrorBin}/bin/herdr-mirror $out/target/release/herdr-mirror \
          --prefix PATH : ${lib.makeBinPath [pkgs.openssh]}
        ln -s ../target/release/herdr-mirror $out/bin/herdr-mirror
        runHook postInstall
      '';
      meta = {
        description = "Herdr plugin that mirrors remote Herdr workspaces into a local session";
        homepage = "https://github.com/nikok6/herdr-mirror";
        license = lib.licenses.mit;
        mainProgram = "herdr-mirror";
        platforms = lib.platforms.linux ++ lib.platforms.darwin;
      };
    };
    herdrWrapped = inputs.wrappers.lib.wrapPackage {
      inherit pkgs;
      package = herdrBase;
      env = {
        HERDR_CONFIG_PATH = pkgs.writeText "herdr-config.toml" ''
          onboarding = false

          [keys]
          focus_pane_left = "alt+h"
          focus_pane_right = "alt+l"
          focus_pane_down = "alt+j"
          focus_pane_up = "alt+k"
          zoom = "alt+f"

          [[keys.command]]
          key = "prefix+shift+m"
          type = "plugin_action"
          command = "mirror.start"

          [[keys.command]]
          key = "prefix+shift+s"
          type = "plugin_action"
          command = "mirror.pause"

          [[keys.command]]
          key = "prefix+shift+b"
          type = "plugin_action"
          command = "mirror.restore"

          [[keys.command]]
          key = "prefix+alt+d"
          type = "plugin_action"
          command = "mirror.teardown"

          [[keys.command]]
          key = "prefix+alt+n"
          type = "plugin_action"
          command = "mirror.remote-new-workspace"

          [[keys.command]]
          key = "prefix+alt+c"
          type = "plugin_action"
          command = "mirror.remote-new-tab"

          [[keys.command]]
          key = "prefix+alt+v"
          type = "plugin_action"
          command = "mirror.remote-split-right"

          [[keys.command]]
          key = "prefix+alt+minus"
          type = "plugin_action"
          command = "mirror.remote-split-down"
        '';
      };
    };
  in {
    packages = {
      herdr-mirror = herdrMirror;
      herdr = pkgs.symlinkJoin {
        name = "herdr";
        paths = [
          herdrWrapped
          herdrMirror
        ];
        postBuild = ''
          rm $out/bin/herdr
          cat > $out/bin/herdr <<EOF
          #!${pkgs.runtimeShell}
          ${herdrWrapped}/bin/herdr plugin link ${herdrMirror} >/dev/null 2>&1 || true
          exec ${herdrWrapped}/bin/herdr "\$@"
          EOF
          chmod +x $out/bin/herdr
        '';
        meta = (herdrWrapped.meta or {}) // {mainProgram = "herdr";};
      };
    };
  };
}
