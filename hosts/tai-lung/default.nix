{
  inputs,
  self,
  ...
}: let
  inherit (import ../_lib.nix {inherit inputs;}) mkHost;
  modules = [
    self.nixosModules.tai-lung-configuration
    self.nixosModules.tai-lung-hardware
  ];
in {
  flake = {
    nixosModules.tai-lung.imports = modules;
    nixosConfigurations.tai-lung = mkHost {
      modules = [self.nixosModules.tai-lung];
    };

    deploy.nodes.tai-lung = {
      hostname = "ssmirnovd.online";
      sshUser = "server";
      interactiveSudo = true;
      profiles.system = {
        user = "root";
        path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.tai-lung;
      };
    };
  };
}
