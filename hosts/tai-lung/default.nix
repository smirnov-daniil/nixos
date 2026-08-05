{
  inputs,
  self,
  ...
}: {
  flake = {
    nixosConfigurations.tai-lung = inputs.nixpkgs.lib.nixosSystem {
      modules = [self.nixosModules.tai-lung];
    };

    deploy.nodes.tai-lung = {
      hostname = "tai-lung.ssmirnovd.online";
      sshUser = "server";
      sshOpts = [
        "-i"
        "~/.ssh/personal"
        "-o"
        "IdentitiesOnly=yes"
      ];
      interactiveSudo = true;
      profiles.system = {
        user = "root";
        path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.tai-lung;
      };
    };
  };
}
