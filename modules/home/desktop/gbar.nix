{
  lib,
  config,
  inputs,
  ...
}: {
  options = {
    desktop.gbar.enable = lib.mkEnableOption "enables gbar";
  };

  imports = [inputs.gBar.homeManagerModules.x86_64-linux.default];

  config = lib.mkIf config.desktop.gbar.enable {
    programs.gBar = {
      enable = true;
      config = {
        Location = "R"; # B = bottom
        UseHyprlandIPC = true; # hyprland workspaces support
        EnableSNI = true;
        SNIIconSize = {
          Discord = 26;
          OBS = 23;
        };
        NumWorkspaces = 5;
      };
    };
  };
}
