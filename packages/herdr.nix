{inputs, ...}: {
  perSystem = {pkgs, ...}: {
    # No premade wrapperModules.herdr in Lassulus/wrappers (unlike zellij), so
    # this is plain wrapPackage + HERDR_CONFIG_PATH, same idiom as
    # quickshell.nix's QS_FLAKE_THEME_FILE: a Nix-store config, no runtime
    # $HOME mutation needed (herdr reads HERDR_CONFIG_PATH directly).
    packages.herdr = inputs.wrappers.lib.wrapPackage {
      inherit pkgs;
      package = pkgs.herdr;
      env = {
        HERDR_CONFIG_PATH = pkgs.writeText "herdr-config.toml" ''
          onboarding = false

          # herdr has no locked/unlocked mode like zellij; the default prefix
          # (ctrl+b) already avoids shadowing normal typing, so these direct
          # Alt chords just replicate zellij's old pane-navigation feel.
          # herdr has no floating-pane concept — zoom (fullscreen-toggle one
          # pane) is the closest equivalent to zellij's ToggleFloatingPanes.
          [keys]
          focus_pane_left = "alt+h"
          focus_pane_right = "alt+l"
          focus_pane_down = "alt+j"
          focus_pane_up = "alt+k"
          zoom = "alt+f"
        '';
      };
    };
  };
}
