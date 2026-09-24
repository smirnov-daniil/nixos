# Modular Nix configuration

This flake builds reusable packages and NixOS modules for `aku`, `gru`, `lich`, and `tai-lung`. It uses `flake-parts` with recursive module discovery, so additions need little wiring but must follow the contracts below.

## Development environment

Use Nix with flakes enabled and devenv 2.3.1 or newer. The standard CLI environment includes devenv. To bootstrap it without rebuilding your system:

```bash
cd ~/flake
nix run --inputs-from path:. nixpkgs#devenv -- shell
```

Once the CLI is installed, use `devenv shell`, or run `direnv allow` once to enable automatic activation through `.envrc`. Shell entry provides Nix tooling (`nixd`, Alejandra, Statix, deadnix), Jujutsu, and the commands below. It does not format files, install Git hooks, decrypt secrets, evaluate hosts, or activate a system.

```bash
devenv test                         # format, workflow regression tests, whole-flake evaluation
devenv tasks run flake:format        # format repository Nix files
devenv tasks run flake:eval          # evaluate without building checks
devenv --profile full test          # also build all flake checks; potentially expensive
devenv shell flake-build environment # build one package
devenv --profile gru tasks run flake:host # build Gru, never switch it
```

Inside the shell, `flake-fmt [--check]`, `flake-eval`, `flake-check`, `flake-build PACKAGE`, and `flake-host HOST` are available directly. The `aku`, `gru`, `lich`, and `tai-lung` profiles select the default host for `flake-host`; an explicit argument overrides the profile. Profiles can be combined, for example `devenv --profile gru --profile full shell`. Build result links live in `.devenv/builds/`.

Checks and builds use a filtered source snapshot: new/uncommitted files are included, but VCS metadata, `.devenv`, `.direnv`, local overrides, `.env*`, and build result links are excluded. Keep plaintext credentials outside the source tree; this filter is not a general secret scanner. `devenv.local.nix` and `devenv.local.yaml` are ignored personal overrides. No services or containers are needed for maintaining this repository, so use `devenv shell` and tasks, not `devenv up`.

The private `skinem` input still needs your SSH access (or an already fetched source) for whole-flake evaluation/builds. Devenv does not provide credentials. Activation and deployment remain explicit operations described below.

Both lock files are committed. When updating the root `nixpkgs` input in `flake.lock`, copy its revision into `devenv.yaml` and run `devenv update nixpkgs`; the regression tests check that the pins match. `devenv update` alone does not update the NixOS flake. Official references: [profiles](https://devenv.sh/profiles/), [tasks](https://devenv.sh/tasks/), and [direnv](https://devenv.sh/integrations/direnv/).

The pinned devenv `v2.3.1` release still has `2.2.2` in its upstream `src/modules/latest-version` metadata. Its shell can therefore print a version-mismatch hint even with the correct lock file; this does not indicate a failed setup.

### Deployment

Use the declared deploy-rs node, currently `tai-lung`. A host profile selects a target; it does not create a deployment node or enable SSH access.

```bash
# Local preflight only: evaluate the target and activation derivation, no SSH/build.
devenv --profile tai-lung tasks run flake:deploy-check

# Explicit deployment from a terminal, with SSH access and the server sudo password.
devenv --profile tai-lung shell flake-deploy

# An explicit node argument overrides the selected host profile.
devenv shell flake-deploy tai-lung
```

`flake-deploy-check [NODE]` reports the configured hostname, SSH user, and activation derivation. It validates local evaluation, not connectivity, credentials, or the health of the remote server. `flake-deploy [NODE]` uses the same filtered working-tree snapshot and the `deploy-rs` package exported by this flake, pinned through `flake.lock`. It selects only `NODE.system`, preserves upstream pre-build checks and rollback behavior, and requests interactive confirmation before deployment. Unlike preflight, deployment builds checks and the system, copies its closure over SSH, and activates it; this can take substantial time and disk space.

Deployment requires terminal stdin/stdout and is disabled when `CI` or `GITHUB_ACTIONS` is set. It is not a task, shell-entry hook, or dependency of any test. Use `devenv shell flake-deploy`, not a task runner, so interactive sudo retains the terminal. With the Claude profile active, preserve it: `devenv --profile claude --profile tai-lung shell flake-deploy` (only after explicit approval to deploy).

Tai Lung uses `server@ssmirnovd.online`, root activation, and interactive sudo. Keep SSH keys and credentials outside the repository; devenv does not provision them or decrypt SOPS secrets locally. See [nixos/README.md](nixos/README.md) for access prerequisites. For custom deploy-rs options, the same pinned client is available through `nix run .#deploy-rs -- --help`; use this lower-level interface deliberately, as it does not have the wrapper's terminal/CI safeguards or source filtering.

### Claude Code

The optional `claude` profile provides the pinned Claude Code CLI and the native devenv integration:

```bash
devenv --profile claude shell claude
devenv --profile claude --profile gru shell claude
```

Authenticate in Claude Code using your own account or externally supplied credentials. The profile does not configure a token, a model, or an external MCP server. Only the `claude-code` package is allowlisted as unfree; the default shell and CI do not install it.

Two project commands are generated:

- `/flake-check`: formatting checks, workflow tests, and whole-flake evaluation without building systems.
- `/flake-format`: format Nix sources and review the Jujutsu diff.

`CLAUDE.md` describes the jj change workflow and requires approval before activation, deployment, service restarts, publishing, or secret decryption. Generated Claude permissions also ask before commands such as `nh`, `nixos-rebuild`, `deploy`, `flake-deploy`, `sudo`, and `ssh`; permission bypass is disabled. These are application-level safeguards, not an OS sandbox or a complete parser for arbitrary shell wrappers. No blanket shell permission or automatic edit hook is installed.

Settings and command symlinks under `.claude/` are generated from `tools/_claude.nix`, ignored by VCS, and excluded from build snapshots. Personal `.claude/settings.local.json` is neither read by Nix nor overwritten. Do not edit the generated files directly. Devenv removes its generated symlinks on the next shell entry without the profile, so preserve `--profile claude` in nested invocations, including `devenv --profile claude test`.

### Terminal workspace

Ghostty opens the wrapped tmux in the persistent `main` session. Projects use
separate sessions (spaces), windows are tabs, and splits are panes. `mux PATH`
creates or attaches a project session with `code` (Kakoune), `agents`, and `build`
tabs. It does not create worktrees, change revisions, or launch agents for you.
An `.ff/repo.yml` umbrella remains one space even when `mux` runs inside a
submodule. Session names include a short path hash to distinguish same-named
projects. Kakoune is also the default `$EDITOR`.

```bash
devenv --profile claude shell flake-build environment
./.devenv/builds/environment/bin/zsh
mux ~/fft/baloo
```

Prefix shortcuts start with `Ctrl+b`, then release it and press the second key:

| Key | Action |
| --- | --- |
| `a` / `A` | Agent picker / toggle the ccmux sidebar |
| `w` | Spaces and tabs |
| `c` / `e` | New shell tab / Kakoune tab |
| `v` / `-` | Split right / below |
| `h j k l` / `H J K L` | Focus / resize a pane |
| `z` / `d` | Zoom pane / detach, keeping processes alive |
| `r` / `g` | tuicr review / jjui |
| `Space` | sysq shell assistant |

Herdr-style navigation also works directly, without the prefix:

| Key | Action |
| --- | --- |
| `Alt+h j k l` | Focus a pane |
| `Alt+f` | Zoom pane |
| `Alt+1…9` / `Alt+[` / `Alt+]` | Select / previous / next tab |
| `Alt+Shift+1…9` | Select a space in creation order (US symbols `!…(`) |
| `Alt+{` / `Alt+}` | Previous / next space |
| `Alt+w` / `Alt+g` | Space picker / tab and pane tree |
| `Ctrl+Alt+[` / `Ctrl+Alt+]` | Previous / next agent in this space |
| `Ctrl+Alt+1…9` | Select an agent pane in creation order |

These Alt keys belong to tmux, including while Kakoune is focused. The Ctrl+Alt
combinations require the terminal's extended-key support (enabled for Ghostty).
The agent picker captures its launching client with `run-shell -C` and passes
`--client-tty` to ccmux. Passing `#{client_tty}` directly through `display-popup -e`
leaves a literal format string on tmux 3.7c and prevents switching to an agent.
The tmux wrapper also provides `tmux` and `sleep` on the server's PATH for
background jobs. Pane flashing is disabled in both the ccmux picker and sidebar.
ccmux's UI and ANSI preview palette, as well as tmux popup backgrounds and
borders, use `theme.nix`. Existing ccmux preferences are preserved; the packaged
defaults are available through the `packages.<system>.ccmux.defaultConfig`
attribute when updating an existing theme.

The packaged tmux includes a fix for 3.7c's popup clipping with a top status
line: scrolling panes must clip against terminal coordinates, including the
status offset. A PTY regression test checks popup borders after synchronized
frames while both the background pane and popup update. A running unpatched
server can avoid the bug with `tmux set -g status-position bottom`; the patch
takes effect when a new server starts. Detaching and reattaching alone does
not replace the server; keep running sessions alive until their work is done.

Review and jjui open a repository picker for `.ff/repo.yml` projects, using each
node's real `path`, including nested modules and excluding unloaded modules.
For ordinary repositories they open directly in the nearest repository.
`mux-repo tuicr [PATH]` and `mux-repo jjui [PATH]` expose the same picker in a shell.
After review, select comments, an idle agent, and **Fill composer** or **Send and
run**. Cancel any picker to keep the review without sending it.

[ccmux](https://github.com/epilande/ccmux) is pinned to 1.4.2 and built from source
with locked Bun dependencies and a local tuicr adapter. Its daemon starts when a tmux
client attaches or the agent picker opens. Initial preferences enable Linux
desktop notifications for waiting/finished agents and group agents by tmux
session, so Baloo's modules stay together. Existing `~/.config/ccmux/ccmux.json`
is preserved; `CCMUX_HOME` selects another writable state directory.

Enter on a background Claude agent switches to its existing frontend or named
attach tab; it never creates a new tab. The fleet frontend is recognized by
its unique Claude pane title and project, since its PID differs from the
background worker's. If it cannot be identified, choose **Attach agent** in
the context menu to explicitly open a `ccmux-agent-<id>` tab running
`claude attach <id>`. Existing tabs are reused. New connections open in the
existing project space (including an umbrella's submodules), falling back to
the picker's space if there is no unique match. Only the terminal that opened
the picker is switched.

Run this once from the packaged environment to connect agent lifecycle hooks:

```bash
ccmux-setup
reviewctl-setup
ccmux setup --agent claude --agent codex --status
```

`ccmux-setup` merges upstream hooks with existing settings, saves dated backups,
and gives the hook scripts Nix-provided Bash and utilities. It refuses to overwrite
managed settings symlinks. It is an explicit command, never a shell-entry hook.
Restart agent sessions to load newly installed
hooks; if Codex requests hook trust, review them in `/hooks`. Without hooks,
ccmux can still discover agent panes, with less precise session matching.
`ccmux notify` tests notification delivery. To adjust an existing configuration:
`ccmux config set notifications.enabled true` and `ccmux config set groupBy session`.

### Review with agents

tuicr is pinned to 0.27.0. In the ccmux picker, `d` reviews the selected agent's
working change and `D` reviews its branch (`trunk()..@` for jj; merge base for
Git). Umbrella projects first offer the submodule picker. Save and leave tuicr
with `:wq`; ccmux then offers the human comments back to the selected agent.
`reviewHandback` retains ccmux's `confirm` default, with `fill` and `auto` available
as explicit preferences. The sidebar itself does not launch review; use `Ctrl+b a`.

`reviewctl-setup` installs the same `tuicr-review` skill for
[Codex](https://learn.chatgpt.com/docs/build-skills) in `~/.agents/skills` and
[Claude Code](https://code.claude.com/docs/en/skills) in `~/.claude/skills`
(`CLAUDE_CONFIG_DIR` is respected). It refuses to replace personal skills and is
never run on shell entry. Pi receives the skill through its package.

Ask Claude or Codex to use `tuicr-review` to review the diff and add its findings
to tuicr. The agent can open a review beside its own tmux pane:

```bash
reviewctl open --repo "$PWD" --pane
reviewctl open --repo "$PWD" --pane --revset 'trunk()..@'
reviewctl list
reviewctl context REVIEW_ID
reviewctl comments REVIEW_ID
reviewctl handoff REVIEW_ID [ANOTHER_REVIEW_ID ...]
```

`context` exposes the saved diff path and exact tuicr session. An AI reviewer
uses `reviewctl add REVIEW_ID --author 'Codex AI Reviewer'` with tuicr comment
JSON on stdin; findings refresh in the open tuicr pane. The suffix
` AI Reviewer` distinguishes agent comments. Automatic return to the author
includes only human comments; `handoff` lets you select AI findings too. Multiple
Baloo submodule reviews can be sent together to one agent in the umbrella space.
`--revset` follows tuicr's combined review mode: the selected jj commits plus the
working change, from the oldest selected commit's parent through `@`.

In Pi, `/diff-review [JJ_REVSET]` opens tuicr in a split and pastes that review's
human comments into the composer on exit. `/ai-review REVIEW_ID [instructions]`
adds Pi findings without changing code. It no longer requires Herdr.

Reviews live under `$XDG_STATE_HOME/tuicr-agent-review` (default
`~/.local/state/tuicr-agent-review`; override with `REVIEWCTL_HOME`). Each review
has its own tuicr data directory, shared with agents through `reviewctl`, while
using the normal tuicr config and editor. Native `tuicr review list` therefore
does not mix these reviews with unrelated sessions. Keep the chosen diff scope
unchanged inside tuicr; open another review to change revisions.

Handback checks the diff snapshot, exact recipient, project, and idle status.
It records delivery per comment content and recipient, including composer fills;
delivery does not mean the finding is resolved. A changed diff requires a new
review. Comments remain available if handback fails or is cancelled. No agent
is started and no jj workspace is created by opening a review.

### GitHub Actions

The `check` workflow uses the same pinned devenv environment, with read-only GitHub permissions and no deployment or full NixOS/package-bundle builds:

- Every push, pull request, and manual run executes `devenv --profile ci test`: Alejandra, workflow/profile regression tests, ShellCheck, and actionlint. This profile does not need private inputs or Claude authentication.
- Pushes and manual runs additionally evaluate the entire flake using `devenv --profile ci tasks run flake:eval`. Pull request events do not receive the private source or its token; their coverage is intentionally narrower.
- `flake-eval` disables import-from-derivation (IFD) as well as check builds. Package expressions fetched from upstream must come from locked source inputs (as with `herdr`), not a derivation that needs building during evaluation. This keeps evaluation independent of a warm local build cache.
- Devenv is bootstrapped directly from the public nixpkgs revision in `devenv.lock`. The private `tributum` source is checked out separately over HTTPS at the revision in `flake.lock`, with credential persistence disabled. `FLAKE_SKINEM_SOURCE` supplies this checkout as a temporary input override; neither lock file is rewritten. Local development keeps using the original SSH input unless this variable is explicitly set.

#### Enable private-source evaluation

The default `GITHUB_TOKEN` can read this repository, not a different private repository. Configure a separate read-only token:

1. In your GitHub account, open **Settings → Developer settings → Personal access tokens → Fine-grained tokens → Generate new token**.
2. Select resource owner **smirnov-daniil**, **Only select repositories → tributum**, and repository permission **Contents: Read-only**. Set an expiration and rotate the token before it expires; no write permission is needed.
3. In the **flake repository**, open **Settings → Secrets and variables → Actions → New repository secret**. Name it **`SKINEM_READ_TOKEN`** and paste the token as its value. Do not put it in `devenv.yaml`, a Nix expression, `.env`, or a commit.
4. Publish the updated workflow and trigger a new push or **Actions → check → Run workflow**. Re-running an old workflow run still uses its old workflow revision.

Without the secret, push/manual runs fail with an explicit setup message after the credential-free checks. Expired tokens, missing repository access, or organization approval requirements also need to be resolved in GitHub. Do not use `pull_request_target` to expose credentials to untrusted changes.

References: [fine-grained tokens](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens), [Actions secrets](https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/use-secrets), [Claude Code integration](https://devenv.sh/integrations/claude-code/).

## Architecture

`flake.nix` discovers modules through `tools/_sources.nix`. It recursively imports ordinary `.nix` files, excluding `flake.nix`, `devenv.nix`, underscore-prefixed helpers, hidden directories, local overrides, generated state, and symlinks.

- Ordinary `.nix` files must be valid `flake-parts` modules.
- `_*.nix` files are plain helpers and must be imported explicitly.
- `perSystem` defines outputs such as packages and checks for each system in `parts.nix`.
- `flake.nixosModules.<name>` exports reusable NixOS modules.
- `flake.nixosConfigurations.<name>` exports complete hosts.
- Aggregate modules such as `base`, `general`, `desktop`, `deploy-rs`, and `sanctum` preserve convenient defaults. Feature leaves should remain independently usable.

Repository layout:

- `hosts/<name>/`: host composition, configuration, hardware, and encrypted secrets.
- `nixos/base/`: shared options and minimal foundations.
- `nixos/features/`: independently reusable NixOS features and compatibility aggregates.
- `packages/`: packages, wrappers, and package bundles. Pi-owned implementation and support packages are co-located under `packages/pi/`.
- `checks/`: evaluation checks and host-specific invariants.

See [nixos/README.md](nixos/README.md) for the current module catalog and Tai Lung deployment instructions.

## Add a feature

Create `nixos/features/<name>.nix` as a flake-parts module:

```nix
{self, ...}: {
  flake.nixosModules.example = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.features.example;
  in {
    options.features.example.enable = lib.mkEnableOption "example";

    config = lib.mkIf cfg.enable {
      environment.systemPackages = [pkgs.example];
    };
  };
}
```

Then:

1. Import only the feature's actual prerequisites. Do not import a large aggregate merely to obtain one option.
2. Use an `enable` option when importing the module would otherwise change the system.
3. Add the module to `leaves` in `checks/nixos-modules.nix`.
4. Add an `enabledLeaves` fixture when its enabled configuration should be evaluated too.
5. Add it to an aggregate only when every consumer of that aggregate should receive it.
6. Import it from the selected host's `<host>-configuration` module and enable its options there.

For a Sanctum service, also add the leaf explicitly to `nixos/features/sanctum/default.nix`. Sanctum aggregation is intentionally not automatic: adding a file must not silently enable a production service.

## Add a package

Create `packages/<name>.nix`:

```nix
{...}: {
  perSystem = {pkgs, ...}: {
    packages.example = pkgs.example;
  };
}
```

For a custom derivation, assign it to `packages.example` in the same `perSystem` block. Package references depend on context:

```nix
self'.packages.example
```

Use `self'` inside `perSystem`, where it already represents the current system. In a NixOS module exported by a flake-parts module, capture `self` from the outer argument set and use:

```nix
self.packages.${pkgs.stdenv.hostPlatform.system}.example
```

A package output is not installed automatically. Add it deliberately to one of these consumers:

- a feature's `environment.systemPackages` for host-specific installation;
- `packages.environment` in `packages/environment.nix` for the standard CLI environment;
- another wrapper or aggregate package through `self'.packages`.

Use an underscore-prefixed helper for package data that is not itself a flake-parts module.

## Add a host

Create:

```text
hosts/<name>/
├── default.nix
├── configuration.nix
├── hardware.nix
└── secrets/             optional, encrypted only
```

`configuration.nix` exports a named constituent:

```nix
{self, ...}: {
  flake.nixosModules.example-configuration = {config, pkgs, ...}: {
    imports = [
      self.nixosModules.base
      self.nixosModules.general
    ];

    preferences.hostname = "example";
    system.stateVersion = "25.11";
  };
}
```

Wrap generated hardware configuration as another flake-parts module:

```nix
{
  flake.nixosModules.example-hardware = {config, lib, modulesPath, ...}: {
    imports = [(modulesPath + "/installer/scan/not-detected.nix")];
  };
}
```

Do not copy raw `nixos-generate-config` output over `hardware.nix` without preserving this wrapper.

Compose the host explicitly in `default.nix`:

```nix
{
  inputs,
  self,
  ...
}: let
  inherit (import ../_lib.nix {inherit inputs;}) mkHost;
  modules = [
    self.nixosModules.example-configuration
    self.nixosModules.example-hardware
  ];
in {
  flake = {
    nixosModules.example.imports = modules;
    nixosConfigurations.example = mkHost {
      modules = [self.nixosModules.example];
    };
  };
}
```

The aggregate `nixosModules.example` is retained as a reusable compatibility output. Every exported `nixosConfiguration` automatically gets an evaluation check. Add host-specific assertions separately when persistence, secrets, deployment, or package-footprint invariants need protection.

`mkHost` defaults to `x86_64-linux`. Pass `system` explicitly for another architecture and add that architecture to `systems` in `parts.nix` if per-system outputs are required.

## Validate changes

Prefer `devenv test` during development. It includes new files without copying live devenv state into the flake source. For an environment without devenv, run the equivalent helpers with Nix, Alejandra, and jq available:

```bash
bash tools/flake-dev.sh format --check
bash tools/flake-dev.sh eval
bash tools/flake-dev.sh check
bash tools/flake-dev.sh host <host>
```

Run `statix check .` as an additional lint review; it may report advisory style findings that do not block evaluation.

Apply a local NixOS host with:

```bash
nh os switch
```

Deploy Tai Lung from Gru with:

```bash
devenv --profile tai-lung shell flake-deploy
```

When adding an output, verify its public name directly:

```bash
nix eval --json path:.#nixosModules --apply builtins.attrNames
nix eval --json path:.#nixosConfigurations --apply builtins.attrNames
nix eval --json path:.#packages.x86_64-linux --apply builtins.attrNames
nix eval --json path:.#checks.x86_64-linux --apply builtins.attrNames
```
