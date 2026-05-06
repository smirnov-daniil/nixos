{
  inputs,
  lib,
  ...
}: {
  perSystem = {pkgs, ...}: {
    packages.helix =
      (inputs.wrappers.wrapperModules.helix.apply {
        inherit pkgs;
      }).wrapper;
  };
}
