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
        Location = "L"; # B = bottom
        UseHyprlandIPC = true; # hyprland workspaces support
        EnableSNI = true;
        NumWorkspaces = 5;
      };
    };
  };
}
