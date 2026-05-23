{
  inputs,
  self,
  lib,
  ...
}: {
  perSystem = {
    pkgs,
    self',
    ...
  }: {
    packages.zellij =
      (inputs.wrappers.wrapperModules.zellij.apply {
        inherit pkgs;
        "config.kdl".path =
          pkgs.writeText "config"
          ''
            default_layout "compact"
          '';
      }).wrapper;
  };
}
