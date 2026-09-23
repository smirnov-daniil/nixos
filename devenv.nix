{
  pkgs,
  lib,
  config,
  ...
}: let
  command = action: ''exec bash "$DEVENV_ROOT/tools/flake-dev.sh" ${action} "$@"'';
  task = exec: {
    inherit exec;
    cwd = config.devenv.root;
    showOutput = true;
  };
in {
  languages.nix.enable = true;
  packages = with pkgs; [alejandra jq jujutsu ripgrep python3 shellcheck actionlint];
  dotenv.enable = false;
  dotenv.disableHint = true;

  scripts = {
    flake-fmt.exec = command "format";
    flake-eval.exec = command "eval";
    flake-check.exec = command "check";
    flake-build.exec = command "build";
    flake-host.exec = command "host";
    flake-deploy-check.exec = command "deploy-check";
    flake-deploy.exec = command "deploy";
  };

  profiles =
    lib.genAttrs ["aku" "gru" "lich" "tai-lung"] (host: {
      module.env.FLAKE_HOST = host;
    })
    // {
      claude.module = import ./tools/_claude.nix;
      ci.module = {lib, ...}: {
        languages.nix.lsp.enable = false;
        tasks."flake:test".after = lib.mkForce ["flake:format-check" "flake:workflow-test"];
      };
      # Explicit opt-in: default tests only evaluate, never build whole systems.
      full.module = {config, ...}: {
        tasks."flake:check".before = lib.optional config.devenv.isTesting "devenv:enterTest";
      };
    };

  tasks = {
    "flake:format" = task "flake-fmt";
    "flake:format-check" = task "flake-fmt --check";
    "flake:workflow-test" = task ''
      python3 -m unittest discover -s tools -p 'test_*.py' -v
      shellcheck tools/flake-dev.sh
      actionlint
    '';
    "flake:eval" = task "flake-eval";
    "flake:check" = task "flake-check";
    "flake:host" = task "flake-host";
    # Deployment itself needs a terminal for confirmation and interactive sudo.
    # Only the local, build-free preflight is exposed as a task.
    "flake:deploy-check" = task "flake-deploy-check";
    "flake:test" =
      (task "true")
      // {
        after = ["flake:format-check" "flake:workflow-test" "flake:eval"];
        before = lib.optional config.devenv.isTesting "devenv:enterTest";
      };
  };

  enterShell = ''
    echo 'flake: flake-fmt | flake-eval | flake-build PACKAGE | flake-host HOST'
    echo 'Tests: devenv test; build all checks: devenv --profile full test'
    echo 'Deploy: flake-deploy-check NODE (local); flake-deploy NODE (interactive)'
  '';
}
