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
    packages.ghostty = let
      nixglhost = inputs.nix-gl-host.packages.${pkgs.system}.default;
      ghosttyWrapped =
        (inputs.wrappers.wrapperModules.ghostty.apply {
          inherit pkgs;
          settings = {
            gtk-titlebar = false;
            mouse-hide-while-typing = true;
            window-show-tab-bar = "never";
            # window-decoration = false;
            #
            quick-terminal-position = "center";
            quick-terminal-size = "25%";

            palette = [
              "0=${self.theme.base00}"
              "1=${self.theme.base08}"
              "2=${self.theme.base0B}"
              "3=${self.theme.base0A}"
              "4=${self.theme.base0D}"
              "5=${self.theme.base0E}"
              "6=${self.theme.base0C}"
              "7=${self.theme.base05}"
              "8=${self.theme.base03}"
              "9=${self.theme.base08}"
              "10=${self.theme.base0B}"
              "11=${self.theme.base0A}"
              "12=${self.theme.base0D}"
              "13=${self.theme.base0E}"
              "14=${self.theme.base0C}"
              "15=${self.theme.base07}"
            ];

            background = self.themeNoHash.base00;
            cursor-color = self.themeNoHash.base05;
            foreground = self.themeNoHash.base05;
            selection-background = self.themeNoHash.base02;
            selection-foreground = self.themeNoHash.base05;

            # Multiplexing (splits/tabs) is zellij's job; alt binds here would
            # shadow zellij and helix defaults. Font size stays on ghostty's
            # default ctrl+equal/ctrl+minus.
            keybind = [
              "performable:ctrl+c=copy_to_clipboard"
              "performable:ctrl+v=paste_from_clipboard"

              "alt+t=toggle_quick_terminal"
            ];
          };
        }).wrapper;
    in
      # Launch ghostty through nixglhost so it picks up the host's NVIDIA
      # OpenGL drivers on non-NixOS. symlinkJoin keeps the wrapper's desktop
      # file, terminfo and shell integration; only the entrypoint is replaced.
      pkgs.symlinkJoin {
        name = "ghostty-nixglhost";
        paths = [ghosttyWrapped];
        nativeBuildInputs = [pkgs.makeWrapper];
        postBuild = ''
          rm $out/bin/ghostty
          makeWrapper ${nixglhost}/bin/nixglhost $out/bin/ghostty \
            --add-flags "-- ${ghosttyWrapped}/bin/ghostty"

          # Repoint the desktop launcher at the nixglhost entrypoint so menu
          # launches also pick up the host OpenGL drivers (the upstream
          # desktop file hardcodes the raw ghostty binary path).
          desktop=$out/share/applications/com.mitchellh.ghostty.desktop
          if [ -e "$desktop" ]; then
            src=$(readlink -f "$desktop")
            rm -f "$desktop"
            sed "s|^Exec=[^ ]*/bin/ghostty|Exec=$out/bin/ghostty|" "$src" > "$desktop"
          fi
        '';
        meta = (ghosttyWrapped.meta or {}) // {mainProgram = "ghostty";};
      };
  };
}
