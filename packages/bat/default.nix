{
  inputs,
  self,
  ...
}: {
  perSystem = {
    pkgs,
    self',
    ...
  }: let
    theme = pkgs.writeText "flake.tmTheme" (import ./_theme.nix {
      inherit (pkgs) lib;
      inherit (self) theme;
    });
    assets = pkgs.runCommand "bat-flake-assets" {} ''
      mkdir -p source/themes
      cp ${theme} source/themes/flake.tmTheme
      BAT_CONFIG_PATH=/dev/null ${pkgs.bat}/bin/bat cache --build --source source --target "$out"
    '';
  in {
    packages.bat = inputs.wrappers.lib.wrapPackage {
      inherit pkgs;
      package = pkgs.bat;
      runtimeInputs = [pkgs.less];
      env = {
        BAT_CACHE_PATH = "${assets}";
        BAT_THEME = "flake";
      };
    };
    checks.bat-theme =
      pkgs.runCommand "bat-theme-tests" {
        nativeBuildInputs = [pkgs.python3];
        BAT_TEST_WRAPPER = pkgs.lib.getExe self'.packages.bat;
        BAT_TEST_UPSTREAM = pkgs.lib.getExe pkgs.bat;
        BAT_TEST_PALETTE = pkgs.writeText "bat-palette.json" (builtins.toJSON self.theme);
        BAT_TEST_THEME = theme;
      } ''
        python3 ${./test_theme.py}
        touch "$out"
      '';
  };
}
