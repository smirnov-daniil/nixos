{self, ...}: {
  perSystem = {pkgs, ...}: let
    pname = "browsec-desktop";
    version = "1.2.2";

    src = pkgs.fetchurl {
      url = "https://github.com/brwinfo/desktop-release/releases/download/v${version}/browsec-desktop_${version}_amd64.deb";
      hash = "sha256-R53L/XKts9Iix0rLBu8Xaq/URyot+Q43vIIAg6VUmJY=";
    };
  in {
    # Electron app repacked from the .deb. Ships resources/xray/{browbox,browray}:
    # a root helper the app runs via sudo (see nixosModules.browsec below for
    # the NOPASSWD rule; without it the app falls back to pkexec prompts).
    packages.browsec = pkgs.stdenv.mkDerivation {
      inherit pname version src;

      nativeBuildInputs = [
        pkgs.dpkg
        pkgs.autoPatchelfHook
      ];

      buildInputs = with pkgs; [
        alsa-lib
        at-spi2-core
        cairo
        cups
        dbus
        expat
        glib
        gtk3
        libdrm
        libgbm
        libnotify
        libsecret
        libuuid
        libxkbcommon
        nspr
        nss
        pango
        systemd # libudev
        libx11
        libxcomposite
        libxdamage
        libxext
        libxfixes
        libxrandr
        libxcb
        libxtst
        libxscrnsaver
      ];

      # libglvnd: ANGLE dlopens libGL.so.1 at runtime; without it the GPU
      # process dies and the app falls back to software rendering.
      runtimeDependencies = [
        pkgs.systemd
        pkgs.libglvnd
      ];

      # Bundled swiftshader/EGL libs resolve at runtime, not link time.
      autoPatchelfIgnoreMissingDeps = ["libvulkan.so.1"];

      unpackPhase = ''
        runHook preUnpack
        dpkg -x $src .
        runHook postUnpack
      '';

      installPhase = ''
        runHook preInstall

        mkdir -p $out/share/browsec $out/share/applications $out/bin $out/share/apparmor.d
        cp -r opt/Browsec/* $out/share/browsec/
        cp -r usr/share/icons $out/share/icons

        # The SUID sandbox can't work from the nix store; user namespaces
        # handle sandboxing on NixOS.
        substituteInPlace usr/share/applications/browsec-desktop.desktop \
          --replace-fail '/opt/Browsec/browsec-desktop' 'browsec-desktop' \
          --replace-fail '--ozone-platform=x11' '--ozone-platform-hint=auto'
        cp usr/share/applications/browsec-desktop.desktop $out/share/applications/

        # Ubuntu 24.04+ denies unprivileged user namespaces to binaries
        # without an AppArmor profile; Chromium then falls back to the SUID
        # sandbox, which can't be setuid in the nix store, and aborts.
        # Installing this profile restores the namespace sandbox.
        cat > $out/share/apparmor.d/browsec-nix <<'PROFILE'
        abi <abi/4.0>,
        include <tunables/global>

        profile browsec-nix /nix/store/*-browsec-desktop-*/share/browsec/browsec-desktop flags=(unconfined) {
          userns,

          include if exists <local/browsec-nix>
        }
        PROFILE

        cat > $out/bin/browsec-desktop <<WRAPPER
        #!${pkgs.runtimeShell}
        extra=""
        if [ "\$(cat /proc/sys/kernel/apparmor_restrict_unprivileged_userns 2>/dev/null)" = "1" ] && [ ! -e /etc/apparmor.d/browsec-nix ]; then
          echo "browsec: AppArmor blocks unprivileged user namespaces on this host; starting with --no-sandbox." >&2
          echo "browsec: restore sandboxing with: sudo install -m644 $out/share/apparmor.d/browsec-nix /etc/apparmor.d/ && sudo apparmor_parser -r /etc/apparmor.d/browsec-nix" >&2
          extra="--no-sandbox"
        fi
        exec $out/share/browsec/browsec-desktop --ozone-platform-hint=auto \$extra "\$@"
        WRAPPER
        chmod +x $out/bin/browsec-desktop

        runHook postInstall
      '';

      meta = {
        description = "Browsec Desktop VPN client (repacked .deb)";
        homepage = "https://github.com/brwinfo/desktop-release";
        platforms = ["x86_64-linux"];
        mainProgram = "browsec-desktop";
      };
    };
  };

  # Opt-in host module: installs the app and grants the bundled root helper
  # passwordless sudo (mirrors what the .deb postinst writes to sudoers.d;
  # without this every VPN toggle tries pkexec, and no polkit agent runs
  # under niri).
  flake.nixosModules.browsec = {
    pkgs,
    config,
    ...
  }: let
    browsec = self.packages.${pkgs.stdenv.hostPlatform.system}.browsec;
    browbox = "${browsec}/share/browsec/resources/xray/browbox";
  in {
    environment.systemPackages = [browsec];

    security.sudo.extraRules = [
      {
        users = [config.preferences.user.name];
        commands = [
          {
            command = browbox;
            options = ["NOPASSWD"];
          }
          {
            # The app invokes the pkill it detects on PATH, so the rule must
            # name that exact path, not a store path.
            command = "/run/current-system/sw/bin/pkill -2 -U 0 browbox";
            options = ["NOPASSWD"];
          }
        ];
      }
    ];
  };
}
