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
    vscode-server.use = lib.mkEnableOption "enables vscode-server";
  };

  config = lib.mkIf config.vscode-server.use {
    services.vscode-server.enable = true;
  };
}
