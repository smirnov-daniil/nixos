{
  lib,
  config,
  inputs,
  ...
}: {
  options = {
    gbar.use = lib.mkEnableOption "enables gbar";
  };

  config = lib.mkIf config.gbar.use {
    imports = [ inputs.gBar.homeManagerModules.x86_64-linux.default ];
    programs.gBar = {
      enables = true;

      config = {
        Location = "B";
        WorspaceSymbols = ["1" "2" "3" "4" "5"];
        EnableSNI = true;
      }
    }
  };
}
