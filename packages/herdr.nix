{inputs, ...}: {
  perSystem = {
    pkgs,
    self',
    ...
  }: let
    herdrSrc = pkgs.fetchFromGitHub {
      owner = "herdrdev";
      repo = "herdr";
      rev = "cca4af8dfad160bc5fb5ae133b70882b5fe28f61";
      hash = "sha256-SUYF4bbaYwNgoe498VoCUzuLPcjBLQXR0o0DWjjoSnI=";
    };
    herdrBase = pkgs.callPackage "${herdrSrc}/nix/package.nix" {};
  in {
    packages.herdr = inputs.wrappers.lib.wrapPackage {
      inherit pkgs;
      package = herdrBase;
      env = {
        HERDR_CONFIG_PATH = pkgs.writeText "herdr-config.toml" ''
          onboarding = false

          [theme]
          name = "terminal"

          [keys]
          focus_pane_left = ["prefix+h", "alt+h"]
          focus_pane_down = ["prefix+j", "alt+j"]
          focus_pane_up = ["prefix+k", "alt+k"]
          focus_pane_right = ["prefix+l", "alt+l"]
          zoom = ["prefix+z", "alt+f"]
          switch_tab = ["prefix+1..9", "alt+1..9"]
          next_tab = ["prefix+n", "alt+]"]
          previous_tab = ["prefix+p", "alt+["]
          next_workspace = ["prefix+}", "alt+}"]
          previous_workspace = ["prefix+{", "alt+{"]
          switch_workspace = ["prefix+shift+1..9", "alt+shift+1..9"]
          workspace_picker = ["prefix+w", "alt+w"]
          goto = ["prefix+g", "alt+g"]
          next_agent = ["prefix+alt+]", "ctrl+alt+]"]
          previous_agent = ["prefix+alt+[", "ctrl+alt+["]
          focus_agent = ["prefix+alt+1..9", "ctrl+alt+1..9"]

          [[keys.command]]
          key = "prefix+shift+a"
          type = "popup"
          command = "${self'.packages.sysq}/bin/sysq"
          description = "ask Codex Spark"
          width = "80%"
          height = "65%"
        '';
      };
    };
  };
}
