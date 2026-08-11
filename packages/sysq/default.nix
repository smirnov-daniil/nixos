{...}: {
  perSystem = {pkgs, ...}: let
    responseSchema = pkgs.writeText "sysq-response-schema.json" (builtins.readFile ./response-schema.json);
    skillPrompt = pkgs.writeText "sysq-shell-guide.md" (builtins.readFile ./skill/SKILL.md);
    zshIntegration = pkgs.writeText "sysq.zsh" (builtins.readFile ./sysq.zsh);

    sysq = pkgs.writeShellApplication {
      name = "sysq";
      runtimeInputs = with pkgs; [
        coreutils
        findutils
        gawk
        gnugrep
        gum
        jq
        gnused
        sqlite
      ];
      text =
        builtins.replaceStrings
        ["@responseSchema@" "@skillPrompt@" "@zshIntegration@"]
        ["${responseSchema}" "${skillPrompt}" "${zshIntegration}"]
        (builtins.readFile ./sysq.sh);
    };
  in {
    packages.sysq = pkgs.symlinkJoin {
      name = "sysq";
      paths = [sysq];
      postBuild = ''
        mkdir -p "$out/share/zsh/site-functions"
        cp ${./sysq.zsh} "$out/share/zsh/site-functions/sysq.zsh"

        mkdir -p "$out/share/codex/skills/shell-guide"
        cp ${./skill/SKILL.md} "$out/share/codex/skills/shell-guide/SKILL.md"
      '';
    };

    apps.sysq = {
      type = "app";
      program = "${sysq}/bin/sysq";
    };
  };
}
