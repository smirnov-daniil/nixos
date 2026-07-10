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
        pkgs.makeWrapper
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

      runtimeDependencies = [pkgs.systemd];

      # Bundled swiftshader/EGL libs resolve at runtime, not link time.
      autoPatchelfIgnoreMissingDeps = ["libvulkan.so.1"];

      unpackPhase = ''
        runHook preUnpack
        dpkg -x $src .
        runHook postUnpack
      '';

      installPhase = ''
        runHook preInstall

        mkdir -p $out/share/browsec $out/share/applications $out/bin
        cp -r opt/Browsec/* $out/share/browsec/
        cp -r usr/share/icons $out/share/icons

        # The SUID sandbox can't work from the nix store; user namespaces
        # handle sandboxing on NixOS.
        substituteInPlace usr/share/applications/browsec-desktop.desktop \
          --replace-fail '/opt/Browsec/browsec-desktop' 'browsec-desktop' \
          --replace-fail '--ozone-platform=x11' '--ozone-platform-hint=auto'
        cp usr/share/applications/browsec-desktop.desktop $out/share/applications/

        makeWrapper $out/share/browsec/browsec-desktop $out/bin/browsec-desktop \
          --add-flags "--ozone-platform-hint=auto"

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
            command = "${pkgs.procps}/bin/pkill -2 -U 0 browbox";
            options = ["NOPASSWD"];
          }
        ];
      }
    ];
  };
}
