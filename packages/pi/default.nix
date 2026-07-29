{
  inputs,
  lib,
  ...
}: {
  perSystem = {pkgs, ...}: let
    # Reference the whole extensions/ tree as one store path so relative
    # imports between sibling files (./_lib/toggle-mode.ts, subagent's own
    # ./agents.ts) resolve at runtime — passing individual ./extensions/foo.ts
    # paths would each copy only that single file to the store.
    extDir = ./extensions;
    extension = name: "${extDir}/${name}";

    piReviewSource = pkgs.applyPatches {
      name = "pi-review-f1de050";
      src = inputs.pi-review;
      patches = [./patches/pi-review-jj.patch];
    };

    glimpseChromium = pkgs.writeShellScriptBin "chromium" ''
      if [[ -x /run/wrappers/bin/__chromium-suid-sandbox ]]; then
        exec ${lib.getExe pkgs.chromium} "$@"
      fi
      if [[ -r /proc/sys/kernel/apparmor_restrict_unprivileged_userns && "$(</proc/sys/kernel/apparmor_restrict_unprivileged_userns)" == 1 ]] \
        || [[ -r /proc/sys/kernel/unprivileged_userns_clone && "$(</proc/sys/kernel/unprivileged_userns_clone)" == 0 ]] \
        || [[ -r /proc/sys/user/max_user_namespaces && "$(</proc/sys/user/max_user_namespaces)" == 0 ]]; then
        exec ${lib.getExe pkgs.chromium} --no-sandbox --test-type "$@"
      fi
      exec ${lib.getExe pkgs.chromium} --disable-setuid-sandbox --test-type "$@"
    '';

    piReviewLoop = pkgs.buildNpmPackage {
      pname = "pi-review-loop-runtime";
      version = "0.3.0-3822e12";
      src = inputs.pi-review-loop;
      patches = [./patches/pi-review-loop.patch];
      postPatch = ''
        cp ${./review-loop-runtime/package.json} package.json
        cp ${./review-loop-runtime/package-lock.json} package-lock.json
        ${lib.getExe pkgs.nodejs} ${./review-loop-runtime/inject-ui.mjs} web/dist/index.html
      '';
      npmDepsHash = "sha256-GDU9ka2cH3GqAqH5vJ2ABbIPYdZxMyD3MQFXEpXyboU=";
      npmInstallFlags = ["--ignore-scripts"];
      dontNpmBuild = true;
      dontNpmPrune = true;
    };

    agent = inputs.pi.lib.mkCodingAgent {
      inherit pkgs;
      modules = [
        {
          pi.coding-agent = {
            models = ./models.json;
            rules = ./APPEND_SYSTEM.md;

            extensions = [
              (extension "prefer-rg.ts")
              (extension "prefer-fd.ts")
              (extension "prefer-eza.ts")
              (extension "prefer-jj.ts")
              (extension "plan-mode.ts")
              (extension "memory.ts")
              (extension "handoff.ts")
              (extension "notify.ts")
              (extension "subagent")
              (extension "pipeline.ts")
              "${piReviewSource}/review.ts"
              "${piReviewLoop}/lib/node_modules/pi-review-loop-runtime/src/index.ts"
            ];

            skills = [
              ./skills/code-review
              ./skills/simplify
              ./skills/verify
              ./skills/security-review
              ./skills/run
              ./skills/graphify
              ./skills/jujutsu
              ./skills/markitdown
            ];

            promptTemplates = [./prompts];

            settings = {
              defaultProvider = "openai-codex";
              defaultModel = "gpt-5.4";
              defaultThinkingLevel = "xhigh";
              enableSkillCommands = true;
              theme = "dark";
            };
          };
        }
      ];
    };

    roleFiles = builtins.attrNames (builtins.readDir ./agents);
  in {
    packages.pi = inputs.wrappers.lib.wrapPackage {
      inherit pkgs;
      inherit (agent) package;
      runtimeInputs = [
        glimpseChromium
        pkgs.clang-tools
        pkgs.eza
        pkgs.gh
        pkgs.git
        pkgs.jujutsu
        pkgs.xdotool
      ];
      env = {
        GLIMPSE_BACKEND = "chromium";
        GLIMPSE_CHROME_PATH = "${glimpseChromium}/bin/chromium";
      };
      # mkCodingAgent has no option for installing arbitrary resource dirs
      # like ~/.pi/agent/agents/*.md (that's specific to the vendored
      # subagent extension's own discovery, not a pi-core concept), so this
      # is the one place a plain wrapPackage preHook is still needed —
      # mirrors the idempotent-install idiom pi.nix uses for models.json,
      # except role files are flake-managed and always overwritten (a user's
      # own hand-written roles under a different filename are left alone).
      preHook = ''
        agent_dir="''${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}"
        mkdir -p "$agent_dir/agents"
        ${lib.concatMapStringsSep "\n" (f: ''
            install -m 0644 ${./agents}/${f} "$agent_dir/agents/${f}"
          '')
          roleFiles}
      '';
    };
  };
}
