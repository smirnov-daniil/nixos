{
  self,
  inputs,
  ...
}: {
  flake.nixosModules.desktop = {
    pkgs,
    config,
    ...
  }: let
    selfpkgs = self.packages."${pkgs.stdenv.hostPlatform.system}";
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
      autostart = config.preferences.autostart;
    };

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

    # Battery/power data for the quickshell bar (UPower DBus).
    services.upower.enable = true;
    services.power-profiles-daemon.enable = true;

    hardware = {
      bluetooth.enable = true;
      bluetooth.powerOnBoot = true;
    };
  };
}
