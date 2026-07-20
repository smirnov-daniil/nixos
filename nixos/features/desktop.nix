{
  self,
  inputs,
  ...
}: {
  flake.nixosModules.desktop = {
    pkgs,
    config,
    lib,
    ...
  }: let
    selfpkgs = self.packages."${pkgs.stdenv.hostPlatform.system}";
    quickshellExe = lib.getExe selfpkgs.quickshellWrapped;
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
    imports = [
      self.nixosModules.gtk

      self.nixosModules.pipewire
      self.nixosModules.zen-browser
    ];

    networking.networkmanager.enable = true;

    programs.niri.enable = true;
    # Rewrap niri per-host so preferences.autostart lands in spawn-at-startup.
    programs.niri.package = inputs.wrapper-modules.wrappers.niri.wrap {
      inherit pkgs;
      imports = [self.wrappersModules.niri];
      autostart = config.preferences.autostart ++ [idle];
    };

    security.polkit.enable = true;
    security.soteria.enable = true;

    environment.systemPackages = [
      selfpkgs.terminal
      selfpkgs.quickshellWrapped
    ];

    fonts.packages = with pkgs; [
      nerd-fonts.jetbrains-mono
      ubuntu-sans
      cm_unicode
      corefonts
      unifont
    ];

    fonts.fontconfig.defaultFonts = {
      serif = ["Ubuntu Sans"];
      sansSerif = ["Ubuntu Sans"];
      monospace = ["JetBrainsMono Nerd Font"];
    };

    time.timeZone = "Europe/Moscow";

    services = {
      greetd = {
        enable = true;
        settings.default_session = {
          command = "${lib.getExe pkgs.tuigreet} --time --remember --cmd niri-session";
          user = "greeter";
        };
      };

      # Battery/power data for the quickshell bar (UPower DBus).
      upower.enable = true;
      power-profiles-daemon.enable = true;
    };

    # tuigreet --remember needs a writable cache dir.
    systemd.tmpfiles.rules = ["d /var/cache/tuigreet 0755 greeter greeter -"];

    hardware = {
      bluetooth.enable = true;
      bluetooth.powerOnBoot = true;
    };
  };
}
