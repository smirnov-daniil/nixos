{lib, ...}: {
  perSystem = {
    pkgs,
    self',
    ...
  }: let
    python = pkgs.python3.withPackages (p: [p.pyyaml]);
    review = pkgs.stdenvNoCC.mkDerivation {
      pname = "tuicr-agent-review";
      version = "1";
      src = ./.;
      nativeBuildInputs = [pkgs.makeWrapper];
      installPhase = ''
        mkdir -p "$out/lib/review" "$out/share/agent-skills"
        cp reviewctl.py setup.py "$out/lib/review/"
        cp ${../tmux/repo.py} "$out/lib/review/repo.py"
        cp -r tuicr-review "$out/share/agent-skills/"
        makeWrapper ${python}/bin/python3 "$out/bin/reviewctl" \
          --add-flags "$out/lib/review/reviewctl.py" \
          --set REVIEWCTL_BIN "$out/bin/reviewctl" \
          --prefix PATH : ${lib.makeBinPath [self'.packages.tuicr self'.packages.jujutsu pkgs.git pkgs.tmux pkgs.fzf]}
        makeWrapper ${python}/bin/python3 "$out/bin/reviewctl-setup" \
          --add-flags "$out/lib/review/setup.py" \
          --add-flags "$out/share/agent-skills/tuicr-review"
      '';
      meta.mainProgram = "reviewctl";
    };
  in {
    packages.tuicr-agent-review = review;
    checks.tuicr-agent-review =
      pkgs.runCommand "tuicr-agent-review-tests" {
        nativeBuildInputs = [python pkgs.git self'.packages.jujutsu];
      } ''
        cp -r ${./.} source
        chmod -R u+w source
        cp ${../tmux/repo.py} source/repo.py
        cd source
        python3 -B -m unittest discover -v
        touch "$out"
      '';
  };
}
