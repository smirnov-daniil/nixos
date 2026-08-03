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
    tuicrSkill = inputs.tuicr + "/skills/tuicr";

    piReviewSource = pkgs.applyPatches {
      name = "pi-review-f1de050";
      src = inputs.pi-review;
      patches = [./patches/pi-review-jj.patch];
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
              (extension "tuicr-review.ts")
              "${piReviewSource}/review.ts"
            ];

            skills = [
              ./skills/code-review
              ./skills/simplify
              ./skills/verify
              ./skills/security-review
              ./skills/skillopt-learned
              ./skills/skillopt-sleep
              ./skills/run
              ./skills/graphify
              ./skills/jujutsu
              ./skills/markitdown
              tuicrSkill
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
        pkgs.clang-tools
        pkgs.eza
        pkgs.gh
        pkgs.git
        pkgs.jujutsu
      ];
      env.TUICR_HERDR_WRAPPER = "${tuicrSkill}/tuicr-wrapper-herdr.sh";
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
