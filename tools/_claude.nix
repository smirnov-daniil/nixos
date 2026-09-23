{
  pkgs,
  lib,
  ...
}: {
  packages = [pkgs.claude-code];

  claude.code = {
    enable = true;
    # Relative paths let devenv clean up its symlinks when leaving the profile.
    settingsPath = ".claude/settings.json";
    hooks.git-hooks-run = {
      enable = false;
      command = "true";
    };
    # No automatic connections to the upstream module's default remote MCP.
    mcpServers = lib.mkForce {};

    permissions = {
      defaultMode = "default";
      disableBypassPermissionsMode = true;
      # These are permission prompts, not a shell sandbox. Do not grant blanket
      # Bash/devenv permissions: wrappers can execute arbitrary commands.
      rules.Bash.ask = [
        "nh *"
        "nixos-rebuild *"
        "deploy *"
        "flake-deploy"
        "flake-deploy *"
        "sudo *"
        "doas *"
        "ssh *"
        "systemctl *"
        "*switch-to-configuration*"
        "sops *"
        "age *"
      ];
    };

    commands = {
      flake-check = ''
        ---
        description: Check formatting, workflow tests, and flake evaluation without building hosts
        ---
        Read CLAUDE.md and AGENTS.md. Run `devenv --profile claude test` from
        the repository root, preserving the Claude profile's generated files.
        Report failures and warnings separately. Do not use the full profile,
        update lock files, decrypt secrets, activate systems, or deploy.
        If the private skinem input is inaccessible, report that limitation;
        do not substitute a stub or claim full validation passed.
      '';
      flake-format = ''
        ---
        description: Format repository Nix sources and review the Jujutsu diff
        ---
        Read CLAUDE.md and AGENTS.md. Inspect `jj status` and `jj diff` first.
        Create or reuse a suitably described change before modifying files.
        Run `flake-fmt`, then `flake-fmt --check`. Review `jj diff` and report
        which files changed. Preserve unrelated user edits. Do not squash,
        rebase, publish, deploy, or start full checks as part of formatting.
      '';
    };
  };
}
