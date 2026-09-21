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

      runtimeDependencies = [pkgs.systemd]; # libudev

      # ANGLE's bundled libGLESv2.so dlopens libEGL.so.1 by soname, and a
      # dlopen from a library searches that library's own RUNPATH rather than
      # the executable's. libglvnd therefore has to land on every ELF here:
      # via runtimeDependencies it only reached the main binary, so the GPU
      # process failed EGL init and fell back to software rendering.
      appendRunpaths = ["${pkgs.lib.getLib pkgs.libglvnd}/lib"];

      # Bundled swiftshader/EGL libs resolve at runtime, not link time.
      autoPatchelfIgnoreMissingDeps = ["libvulkan.so.1"];

      # browbox is a dynamically linked Go binary that autoPatchelfHook rewrites
      # into something which SIGSEGVs on startup, so the sweep is driven by hand
      # here and browbox is installed after it with nothing but its ELF
      # interpreter repointed -- it links only libc, libdl and libpthread.
      # (browray is statically linked, so the hook never touched it.)
      dontAutoPatchelf = true;

      postFixup = ''
        autoPatchelf -- $out

        xray=$out/share/browsec/resources/xray
        install -Dm755 opt/Browsec/resources/xray/browbox $xray/browbox-real
        # Only the interpreter: adding an rpath makes patchelf rewrite the
        # program headers, which is what corrupts it. glibc's own loader
        # already finds libc, libdl and libpthread beside itself.
        patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
          $xray/browbox-real
      '';

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

        # Manual privilege mode (BROWSEC_PRIVILEGE_MODE below): the app spawns
        # browbox itself rather than through sudo/pkexec. File capabilities
        # cannot be set inside the nix store, so the real binary is set aside
        # for nixosModules.browsec to wrap with setcap, and the path the app
        # spawns becomes a shim that execs that wrapper.
        xray=$out/share/browsec/resources/xray
        rm "$xray/browbox"
        cat > "$xray/browbox" <<'SHIM'
        #!/bin/sh
        exec /run/wrappers/bin/browsec-browbox "$@"
        SHIM
        chmod +x "$xray/browbox"

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
        # Skip the app's sudo/pkexec provisioning: its sudoers check parses
        # 'sudo -n -l' and needs NOPASSWD and the browbox path on one line,
        # which a ~105-char store path can never satisfy at sudo's 80-column
        # no-tty width. browbox carries cap_net_admin itself instead.
        export BROWSEC_PRIVILEGE_MODE=manual
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

  # Opt-in host module: installs the app and gives browbox the capabilities it
  # needs to run unprivileged. The app is built with BROWSEC_PRIVILEGE_MODE=manual
  # so it spawns browbox directly; its sudo/pkexec provisioning cannot work here
  # (the sudoers self-check needs NOPASSWD and the browbox path on one line of
  # `sudo -n -l`, and a nix store path always wraps at sudo's 80-column no-tty
  # width), and no polkit agent runs under niri anyway.
  flake.nixosModules.browsec = {
    pkgs,
    config,
    lib,
    ...
  }: let
    cfg = config.programs.browsec;
    browsec = cfg.package;
  in {
    options.programs.browsec.package = lib.mkOption {
      type = lib.types.package;
      default = self.packages.${pkgs.stdenv.hostPlatform.system}.browsec;
    };

    config = {
      environment.systemPackages = [browsec];

      # File capabilities cannot live in the nix store, so this wrapper is what
      # actually carries them; the browbox inside the package is a shim that
      # execs it. cap_net_admin creates the TUN device and manages routes and
      # nftables; cap_net_raw covers the connectivity probes.
      security.wrappers.browsec-browbox = {
        source = "${browsec}/share/browsec/resources/xray/browbox-real";
        capabilities = "cap_net_admin,cap_net_raw+ep";
        owner = "root";
        group = "root";
      };
    };
  };
}
