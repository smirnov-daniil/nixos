{
  inputs,
  self,
  ...
}: {
  perSystem = {pkgs, ...}: let
    wrapped = inputs.wrappers.lib.wrapPackage {
      inherit pkgs;
      package = pkgs.quickshell;
      runtimeInputs = [
        pkgs.brightnessctl # OSD + control center brightness slider
        pkgs.cliphist
        pkgs.gammastep
        pkgs.grim
        pkgs.iproute2 # ip link, for the Browsec tunnel state
        pkgs.libnotify # notify-send for battery alerts (loops back into the shell)
        pkgs.networkmanager # nmcli for the wifi service
        pkgs.procps # pkill, to stop browbox
        pkgs.slurp
        pkgs.systemd
        pkgs.wf-recorder
        pkgs.wl-clipboard
      ];
      env = {
        # theme.nix is the single source of truth; Common/Theme.qml loads this.
        "QS_FLAKE_THEME_FILE" = pkgs.writeText "quickshell-theme.json" (builtins.toJSON self.theme);
        # Qt 6 blocks XHR on file:// by default; Theme.qml needs it.
        "QML_XHR_ALLOW_FILE_READ" = "1";
      };
      flags = {
        "-c" = toString ./.;
      };
    };
  in {
    # Repoint bin/qs at the wrapped entrypoint — wrapPackage only wraps the
    # main binary, and an unwrapped `qs` (no -c, no env) is a footgun.
    packages.quickshellWrapped = pkgs.symlinkJoin {
      name = "quickshell-wrapped";
      paths = [wrapped];
      postBuild = ''
        rm $out/bin/qs
        ln -s $out/bin/quickshell $out/bin/qs
      '';
      meta = (wrapped.meta or {}) // {mainProgram = "quickshell";};
    };
  };
}
