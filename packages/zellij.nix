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
        # Locked by default so zellij's normal-mode binds (ctrl+o/s/b/p/n/h/t,
        # alt+i/o/n/-) never shadow helix defaults; ctrl+g unlocks the full
        # zellij bindings. The locked-mode alt binds below are keys helix does
        # not use, so pane navigation works without unlocking.
        "config.kdl".path =
          pkgs.writeText "config"
          ''
            default_layout "default"
            default_mode "locked"

            keybinds {
                locked {
                    bind "Alt h" "Alt Left" { MoveFocusOrTab "Left"; }
                    bind "Alt l" "Alt Right" { MoveFocusOrTab "Right"; }
                    bind "Alt j" "Alt Down" { MoveFocus "Down"; }
                    bind "Alt k" "Alt Up" { MoveFocus "Up"; }
                    bind "Alt f" { ToggleFloatingPanes; }
                }
            }
          '';
      }).wrapper;
  };
}
