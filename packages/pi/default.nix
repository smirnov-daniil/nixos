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
              (extension "prefer-jj.ts")
              (extension "plan-mode.ts")
              (extension "memory.ts")
              (extension "subagent")
              (extension "pipeline.ts")
            ];

            skills = [
              ./skills/code-review
              ./skills/simplify
              ./skills/verify
              ./skills/security-review
              ./skills/run
            ];

            promptTemplates = [./prompts];

            settings = {
              defaultProvider = "anthropic";
              defaultModel = "claude-sonnet-5";
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
