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
        editor = {
          line-number = "relative";
          mouse = false;
          auto-completion = true;
          auto-format = true;
          auto-info = true;
          cursor-shape = {
            normal = "block";
            insert = "bar";
            select = "underline";
          };
        };
      };
      languages.language = [
        {
          name = "nix";
          scope = "source.nix";
          file-types = ["nix"];
          auto-format = true;
          comment-token = "#";
          block-comment-tokens = {
            start = "/*";
            end = "*/";
          };
          formatter = {
            command = "${pkgs.alejandra}/bin/alejandra";
            args = ["--quiet"];
          };
        }
      ];
    };
  };
}
