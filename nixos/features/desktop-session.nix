{
  self,
  inputs,
  ...
}: {
  flake.nixosModules.desktop-session = {
    pkgs,
    config,
    lib,
    ...
  }: let
    cfg = config."desktop-session";
    quickshellExe = lib.getExe cfg.quickshellPackage;
    idle = pkgs.writeShellApplication {
      name = "idle";
      runtimeInputs = [pkgs.swayidle];
      text = ''
        exec swayidle -w \
          timeout 300 '${quickshellExe} ipc call lock lock' \
          timeout 600 '${lib.getExe pkgs.niri} msg action power-off-monitors' \
          before-sleep '${quickshellExe} ipc call lock lock'
      '';
    };
  in {
    imports = [self.nixosModules.preferences];

    options."desktop-session" = {
      terminalPackage = lib.mkOption {
        type = lib.types.package;
        default = self.packages.${pkgs.stdenv.hostPlatform.system}.terminal;
      };
      quickshellPackage = lib.mkOption {
        type = lib.types.package;
        default = self.packages.${pkgs.stdenv.hostPlatform.system}.quickshellWrapped;
      };
    };

    config = {
      programs.niri.enable = true;
      programs.niri.package = inputs.wrapper-modules.wrappers.niri.wrap {
        inherit pkgs;
        imports = [self.wrappersModules.niri];
        terminal = lib.getExe cfg.terminalPackage;
        quickshell = cfg.quickshellPackage;
        autostart = config.preferences.autostart ++ [idle];
        renderDrmDevice = config.preferences.niri.renderDrmDevice;
      };

      security = {
        polkit = {
          enable = true;
          # The setuid pkexec wrapper became opt-in in nixpkgs; without it the
          # only pkexec on PATH is the plain non-setuid binary, exiting 127.
          enablePkexecWrapper = true;
        };
        soteria.enable = true;
      };

      environment.systemPackages = [
        cfg.terminalPackage
        cfg.quickshellPackage
      ];

      services = {
        greetd = {
          enable = true;
          useTextGreeter = true;
          settings.default_session = {
            command = "${lib.getExe pkgs.tuigreet} --time --remember --cmd niri-session";
            user = "greeter";
          };
        };
        upower.enable = true;
        power-profiles-daemon.enable = true;
      };

      systemd.tmpfiles.rules = ["d /var/cache/tuigreet 0755 greeter greeter -"];
    };
  };
}
