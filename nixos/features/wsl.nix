{inputs, ...}: {
  flake.nixosModules.wsl = {
    pkgs,
    config,
    ...
  }: {
    imports = [inputs.nixos-wsl.nixosModules.default];
    wsl = {
      enable = true;
      interop.register = true;
      docker-desktop.enable = true;
      defaultUser = "${config.preferences.user.name}";
      startMenuLaunchers = true;
    };
  };
}
