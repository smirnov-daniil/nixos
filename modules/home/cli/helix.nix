{
  lib,
  config,
  pkgs,
  ...
}: {
  options = {
    cli.helix.enable = lib.mkEnableOption "enables helix";
  };

  config = lib.mkIf config.cli.helix.enable {
    programs.helix = {
      enable = true;

      package = pkgs.helix;

      settings = {
        editor = {
          line-number = "relative";
          mouse = false;
          auto-completion = true;
          auto-format = true;
          auto-info = true;
          idle-timeout = 0;
          cursor-shape = {
            normal = "block";
            insert = "bar";
            select = "underline";
          };
          lsp = {
            display-inlay-hints = true;
            display-messages = true;
          };
          indent-guides = {
            render = true;
          };
        };
        keys.normal = {
          space.space = "file_picker";
          space.w = ":w";
          space.q = ":q";
        };
      };

      languages = {
        language = [
          {
            name = "nix";
            language-servers = ["nixd"];
            auto-format = true;
            formatter = {
              command = "${pkgs.alejandra}/bin/alejandra";
              args = ["--quiet"];
            };
          }
          {
            name = "rust";
            language-servers = ["rust-analyzer"];
            auto-format = true;
            formatter = {
              command = "rustfmt";
            };
          }
          {
            name = "haskell";
            language-servers = ["haskell-language-server"];
            auto-format = true;
            formatter = {
              command = "stylish-haskell";
            };
          }
        ];

        language-server = {
          rust-analyzer = {
            command = "rust-analyzer";
            config.check = {
              command = "clippy";
            };
          };
          nixd = {
            command = "${pkgs.nixd}/bin/nixd";
          };
          haskell-language-server = {
            command = "haskell-language-server";
            args = ["--lsp"];
            config = {
              haskell = {
                formattingProvider = "stylish-haskell";
                checkProject = true;
              };
            };
          };
        };
      };
    };
  };
}
