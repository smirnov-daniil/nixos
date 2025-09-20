{
  lib,
  config,
  inputs,
  ...
}: {
  imports = [
    inputs.vscode-server.homeModules.default
  ];
  options = {
    misc.vscode-server.enable = lib.mkEnableOption "enables vscode-server";
  };

  config = lib.mkIf config.misc.vscode-server.enable {
    services.vscode-server.enable = true;
  };
}
