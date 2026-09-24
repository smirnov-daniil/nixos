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
    c = name: "rgb:${self.themeNoHash.${name}}";

    # base16 -> kakoune faces, generated from theme.nix (self.theme).
    colorscheme = pkgs.writeText "flake.kak" ''
      # builtin ui faces
      face global Default ${c "base05"},${c "base00"}
      face global PrimarySelection default,${c "base02"}
      face global SecondarySelection default,${c "base02"}+d
      face global PrimaryCursor ${c "base00"},${c "base05"}
      face global SecondaryCursor ${c "base00"},${c "base04"}
      face global PrimaryCursorEol ${c "base00"},${c "base0C"}
      face global SecondaryCursorEol ${c "base00"},${c "base0C"}+d
      face global LineNumbers ${c "base03"},${c "base00"}
      face global LineNumberCursor ${c "base05"},${c "base01"}
      face global LineNumbersWrapped ${c "base01"},${c "base00"}
      face global MenuForeground ${c "base01"},${c "base04"}
      face global MenuBackground ${c "base05"},${c "base01"}
      face global MenuInfo ${c "base04"}
      face global Information ${c "base05"},${c "base01"}
      face global Error ${c "base08"},default
      face global StatusLine ${c "base04"},${c "base01"}
      face global StatusLineMode ${c "base0D"},${c "base01"}+b
      face global StatusLineInfo ${c "base0C"},${c "base01"}
      face global StatusLineValue ${c "base0B"},${c "base01"}
      face global StatusCursor ${c "base00"},${c "base05"}
      face global Prompt ${c "base0A"},${c "base01"}
      face global MatchingChar ${c "base0A"}+u
      face global Whitespace ${c "base03"}+f
      face global WhitespaceIndent ${c "base03"}+f
      face global BufferPadding ${c "base03"},${c "base00"}

      # code
      face global value ${c "base09"}
      face global type ${c "base0A"}
      face global variable ${c "base08"}
      face global module ${c "base0A"}
      face global function ${c "base0D"}
      face global string ${c "base0B"}
      face global keyword ${c "base0E"}
      face global operator ${c "base05"}
      face global attribute ${c "base0A"}
      face global comment ${c "base03"}+i
      face global documentation ${c "base03"}+i
      face global meta ${c "base0E"}
      face global builtin ${c "base09"}

      # markup
      face global title ${c "base0D"}+b
      face global header ${c "base0D"}
      face global mono ${c "base0B"}
      face global block ${c "base0B"}
      face global link ${c "base09"}+u
      face global bullet ${c "base08"}
      face global list ${c "base08"}

      # kakoune-lsp
      face global DiagnosticError default,default,${c "base08"}+c
      face global DiagnosticWarning default,default,${c "base0A"}+c
      face global DiagnosticInfo default,default,${c "base0D"}+c
      face global DiagnosticHint default,default,${c "base0C"}+c
      face global InlayDiagnosticError ${c "base08"}+i
      face global InlayDiagnosticWarning ${c "base0A"}+i
      face global InlayDiagnosticInfo ${c "base0D"}+i
      face global InlayDiagnosticHint ${c "base0C"}+i
      face global LineFlagError ${c "base08"}
      face global LineFlagWarning ${c "base0A"}
      face global LineFlagInfo ${c "base0D"}
      face global LineFlagHint ${c "base0C"}
      face global InlayHint ${c "base03"}+i
      face global InlayCodeLens ${c "base03"}
      face global Reference default,${c "base02"}
      face global ReferenceBind default,${c "base02"}+u
    '';

    configDir = pkgs.runCommand "kakoune-config" {} ''
      install -Dm444 ${./kakrc} $out/kakrc
      install -Dm444 ${./herdr.kak} $out/herdr.kak
      install -Dm444 ${./qml.kak} $out/qml.kak
      install -Dm444 ${./surround.kak} $out/surround.kak
      install -Dm444 ${./jj-diff.kak} $out/jj-diff.kak
      install -Dm444 ${colorscheme} $out/colors/flake.kak
    '';

    kakoune = pkgs.kakoune.override {
      plugins = with pkgs.kakounePlugins; [
        auto-pairs-kak
        kak-fzf
      ];
    };
  in {
    # Terminal editor, also used by the tmux project launcher.
    packages.kakoune = inputs.wrappers.lib.wrapPackage {
      inherit pkgs;
      package = kakoune;
      runtimeInputs = [
        # lsp
        pkgs.kakoune-lsp
        pkgs.nixd
        pkgs.alejandra
        pkgs.clang-tools
        pkgs.marksman
        pkgs.tinymist
        pkgs.typstyle
        pkgs.typescript-language-server
        pkgs.vscode-langservers-extracted
        pkgs.kdePackages.qtdeclarative # qmlls

        # pickers and vcs gutter
        pkgs.fzf
        pkgs.fd
        pkgs.ripgrep
        pkgs.bat
        pkgs.gawk
        pkgs.diffutils
        pkgs.perl
        pkgs.wl-clipboard
        self'.packages.git
        self'.packages.jujutsu
      ];
      env.KAKOUNE_CONFIG_DIR = "${configDir}";
    };
  };
}
