{inputs}: {
  mkHost = {
    modules,
    system ? "x86_64-linux",
    specialArgs ? {},
  }:
    inputs.nixpkgs.lib.nixosSystem {
      inherit modules specialArgs system;
    };
}
