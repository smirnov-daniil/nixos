{
  inputs,
  lib,
  self,
  ...
}: {
  perSystem = {pkgs, ...}: let
    inherit (self) theme;
    # base16 -> helix theme generated from theme.nix (self.theme).
    flakeTheme = {
      "ui.background" = {bg = "base00";};
      "ui.text" = {fg = "base05";};
      "ui.text.focus" = {fg = "base06";};
      "ui.menu" = {
        fg = "base05";
        bg = "base01";
      };
      "ui.menu.selected" = {
        fg = "base01";
        bg = "base04";
      };
      "ui.menu.scroll" = {
        fg = "base04";
        bg = "base01";
      };
      "ui.linenr" = {fg = "base03";};
      "ui.linenr.selected" = {fg = "base05";};
      "ui.popup" = {
        fg = "base05";
        bg = "base01";
      };
      "ui.popup.info" = {
        fg = "base05";
        bg = "base01";
      };
      "ui.window" = {fg = "base03";};
      "ui.selection" = {bg = "base02";};
      "ui.selection.primary" = {bg = "base02";};
      "ui.cursor" = {
        fg = "base05";
        modifiers = ["reversed"];
      };
      "ui.cursor.primary" = {
        fg = "base05";
        modifiers = ["reversed"];
      };
      "ui.cursor.match" = {
        fg = "base0A";
        modifiers = ["underlined"];
      };
      "ui.cursorline.primary" = {bg = "base01";};
      "ui.virtual.whitespace" = {fg = "base03";};
      "ui.virtual.ruler" = {bg = "base01";};
      "ui.virtual.indent-guide" = {fg = "base03";};
      "ui.virtual.inlay-hint" = {fg = "base03";};
      "ui.help" = {
        fg = "base06";
        bg = "base01";
      };
      "ui.gutter" = {bg = "base00";};
      "ui.statusline" = {
        fg = "base04";
        bg = "base01";
      };
      "ui.statusline.inactive" = {
        fg = "base03";
        bg = "base01";
      };
      "ui.statusline.normal" = {
        fg = "base01";
        bg = "base0D";
      };
      "ui.statusline.insert" = {
        fg = "base01";
        bg = "base0B";
      };
      "ui.statusline.select" = {
        fg = "base01";
        bg = "base0E";
      };

      "comment" = {
        fg = "base03";
        modifiers = ["italic"];
      };
      "variable" = "base08";
      "variable.builtin" = "base09";
      "variable.parameter" = "base08";
      "variable.other.member" = "base08";
      "constant" = "base09";
      "constant.builtin" = "base09";
      "constant.character" = "base0C";
      "constant.character.escape" = "base0C";
      "constant.numeric" = "base09";
      "string" = "base0B";
      "string.regexp" = "base0C";
      "string.special" = "base0D";
      "label" = "base0E";
      "type" = "base0A";
      "type.builtin" = "base0A";
      "type.enum.variant" = "base09";
      "constructor" = "base0D";
      "function" = "base0D";
      "function.builtin" = "base0D";
      "function.method" = "base0D";
      "function.macro" = "base0E";
      "attribute" = "base0A";
      "keyword" = "base0E";
      "keyword.control" = "base0E";
      "keyword.directive" = "base0E";
      "operator" = "base05";
      "punctuation" = "base05";
      "punctuation.delimiter" = "base05";
      "punctuation.bracket" = "base05";
      "namespace" = "base0A";
      "special" = "base0D";

      "markup.heading" = "base0D";
      "markup.heading.marker" = "base03";
      "markup.list" = "base08";
      "markup.bold" = {
        fg = "base0A";
        modifiers = ["bold"];
      };
      "markup.italic" = {
        fg = "base0E";
        modifiers = ["italic"];
      };
      "markup.strikethrough" = {modifiers = ["crossed_out"];};
      "markup.link.url" = {
        fg = "base09";
        modifiers = ["underlined"];
      };
      "markup.link.text" = "base08";
      "markup.link.label" = "base0C";
      "markup.quote" = "base0C";
      "markup.raw" = "base0B";

      "diff.plus" = "base0B";
      "diff.minus" = "base08";
      "diff.delta" = "base09";

      "error" = "base08";
      "warning" = "base0A";
      "info" = "base0D";
      "hint" = "base0C";
      "diagnostic.error" = {
        underline = {
          color = "base08";
          style = "curl";
        };
      };
      "diagnostic.warning" = {
        underline = {
          color = "base0A";
          style = "curl";
        };
      };
      "diagnostic.info" = {
        underline = {
          color = "base0D";
          style = "curl";
        };
      };
      "diagnostic.hint" = {
        underline = {
          color = "base0C";
          style = "curl";
        };
      };

      palette = {
        inherit
          (theme)
          base00
          base01
          base02
          base03
          base04
          base05
          base06
          base07
          base08
          base09
          base0A
          base0B
          base0C
          base0D
          base0E
          base0F
          ;
      };
    };
  in {
    packages.helix =
      (inputs.wrappers.wrapperModules.helix.apply {
        inherit pkgs;
        themes.flake = flakeTheme;
        settings = {
          theme = "flake";
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
            space = {
              space = "file_picker";
              w = ":w";
              q = ":q";
            };
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
            {
              name = "cpp";
              language-servers = ["clangd"];
              auto-format = true;
              formatter = {
                command = "${pkgs.clang-tools}/bin/clang-format";
              };
            }
            {
              name = "c";
              language-servers = ["clangd"];
              auto-format = true;
              formatter = {
                command = "${pkgs.clang-tools}/bin/clang-format";
              };
            }
            {
              name = "cmake";
              language-servers = ["cmake-language-server"];
            }
            {
              name = "json";
              language-servers = ["vscode-json-language-server"];
              auto-format = true;
            }
            {
              name = "markdown";
              language-servers = ["marksman"];
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
            clangd = {
              command = "${pkgs.clang-tools}/bin/clangd";
              args = ["--background-index" "--clang-tidy"];
            };
            cmake-language-server = {
              command = "${pkgs.cmake-language-server}/bin/cmake-language-server";
            };
            vscode-json-language-server = {
              command = "${pkgs.vscode-langservers-extracted}/bin/vscode-json-language-server";
              args = ["--stdio"];
            };
            marksman = {
              command = "${pkgs.marksman}/bin/marksman";
              args = ["server"];
            };
          };
        };
      }).wrapper;
  };
}
