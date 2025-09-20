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
    vscode-server.enable = lib.mkEnableOption "enables vscode-server";
  };

  config = lib.mkIf config.vscode-server.enable {
    services.vscode-server.enable = true;
  };
}
