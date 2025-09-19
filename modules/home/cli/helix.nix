{
  lib,
  config,
  pkgs,
  ...
}: {
  options = {
    helix.use = lib.mkEnableOption "enables helix";
  };

  config = lib.mkIf config.helix.use {
    programs.helix = {
      enable = true;
      settings = {
        editor.cursor-shape = {
          normal = "block";
          insert = "bar";
          select = "underline";
        };
      };
      languages.language = [
        {
          name = "nix";
          scope = "source.nix";
          file-types = ["nix"];
          auto-format = true;
          formatter = {
            command = "${pkgs.alejandra}/bin/alejandra";
            args = ["--quiet"];
          };
        }
      ];
    };
  };
}
