{self, ...}: {
  flake.nixosModules.general = {
    pkgs,
    config,
    ...
  }: {
    imports = [
      self.nixosModules.nix
    ];

    users.users.${config.preferences.user.name} = {
      isNormalUser = true;
      description = "${config.preferences.user.name}'s account";
      extraGroups = ["wheel" "networkmanager"];
      shell = self.packages.${pkgs.stdenv.hostPlatform.system}.environment;

      # hashedPasswordFile = "/persist/passwd";
      # initialPassword = "12345";
    };
    environment.variables = {
      "GIT_AUTHOR_EMAIL" = "${config.preferences.user.email}";
    };
  };
}
