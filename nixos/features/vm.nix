{inputs, ...}: {
  flake.nixosModules.vm = {
    pkgs,
    config,
    ...
  }: {
    imports = [];
    virtualisation.incus.enable = true;
    networking.nftables.enable = true;
    users.users."${config.preferences.user.name}".extraGroups = ["incus-admin"];
  };
}
