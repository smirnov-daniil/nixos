{...}: {
  perSystem = {
    pkgs,
    self',
    ...
  }: let
    responseSchema = pkgs.writeText "sysq-response-schema.json" (builtins.readFile ./response-schema.json);
    skillPrompt = pkgs.writeText "sysq-shell-guide.md" (builtins.readFile ./skill/SKILL.md);
    zshIntegration = pkgs.writeText "sysq.zsh" (builtins.readFile ./sysq.zsh);

    sysq = pkgs.writeShellApplication {
      name = "sysq";
      runtimeInputs = with pkgs; [
        self'.packages.pi
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

        mkdir -p "$out/share/pi/skills/shell-guide"
        cp ${./skill/SKILL.md} "$out/share/pi/skills/shell-guide/SKILL.md"
      '';
    };

    apps.sysq = {
      type = "app";
      program = "${sysq}/bin/sysq";
    };

    checks.sysq =
      pkgs.runCommand "sysq-tests" {
        nativeBuildInputs = with pkgs; [python3 bash coreutils findutils gawk gnugrep gnused jq shellcheck];
      } ''
        cp -r ${./.} sysq
        cd sysq
        python3 -B -m unittest discover -v
        shellcheck -s bash sysq.sh
        touch "$out"
      '';
  };
}
