{
  inputs,
  lib,
  self,
  ...
}: {
  perSystem = {
    pkgs,
    self',
    ...
  }: let
    python = pkgs.python3.withPackages (p: [p.pyyaml]);
    testPython = pkgs.python3.withPackages (p: [p.pyyaml p.pyte]);
    # Popup clipping uses terminal coordinates, including the top status line.
    # tmux 3.7c otherwise overwrites its upper border when a pane scrolls.
    tmuxCore = pkgs.tmux.overrideAttrs (old: {
      patches = (old.patches or []) ++ [./popup-status-offset.patch];
    });
    repoPicker = pkgs.writeShellApplication {
      name = "mux-repo";
      runtimeInputs = [pkgs.fzf self'.packages.tuicr-agent-review self'.packages.jjui self'.packages.jujutsu];
      text = ''exec ${python}/bin/python3 ${./repo.py} "$@"'';
    };
    navigate = pkgs.writeShellApplication {
      name = "mux-navigate";
      runtimeInputs = [tmuxCore self'.packages.ccmux];
      text = ''exec ${python}/bin/python3 ${./navigate.py} "$@"'';
    };
    config = pkgs.writeText "tmux.conf" ''
      set -g default-terminal 'tmux-256color'
      set -as terminal-features ',xterm-ghostty:RGB:extkeys'
      set -s extended-keys on
      set -s escape-time 10
      set -g focus-events on
      set -g allow-passthrough on
      set -g mouse on
      set -g history-limit 50000
      set -g base-index 1
      setw -g pane-base-index 1
      set -g renumber-windows on
      set -g detach-on-destroy off
      set -g set-clipboard on
      set -g mode-keys vi
      set -ag update-environment ' DISPLAY WAYLAND_DISPLAY DBUS_SESSION_BUS_ADDRESS XDG_RUNTIME_DIR SSH_AUTH_SOCK'

      # Herdr's direct navigation layer; these keys are owned by tmux.
      bind -n M-h select-pane -L
      bind -n M-j select-pane -D
      bind -n M-k select-pane -U
      bind -n M-l select-pane -R
      bind -n M-f resize-pane -Z
      bind -n 'M-[' previous-window
      bind -n 'M-]' next-window
      bind -n 'M-{' switch-client -p
      bind -n 'M-}' switch-client -n
      bind -n M-w choose-tree -Zs
      bind -n M-g choose-tree -Zw
      bind -n 'C-M-[' run-shell '${navigate}/bin/mux-navigate agent previous #{pane_id}'
      bind -n 'C-M-]' run-shell '${navigate}/bin/mux-navigate agent next #{pane_id}'
      ${lib.concatMapStringsSep "\n" (n: ''
        bind -n M-${toString n} select-window -t :${toString n}
        bind -n C-M-${toString n} run-shell '${navigate}/bin/mux-navigate agent ${toString n} #{pane_id}'
      '') (lib.range 1 9)}
      ${lib.concatImapStringsSep "\n" (n: key: ''
        bind -n 'M-${key}' run-shell '${navigate}/bin/mux-navigate space ${toString n} #{pane_id}'
      '') ["!" "@" "#" "$" "%" "^" "&" "*" "("]}

      # Prefix shortcuts remain available alongside the Alt layer.
      bind c new-window -c '#{pane_current_path}'
      bind v split-window -h -c '#{pane_current_path}'
      bind - split-window -v -c '#{pane_current_path}'
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R
      bind -r H resize-pane -L 5
      bind -r J resize-pane -D 5
      bind -r K resize-pane -U 5
      bind -r L resize-pane -R 5
      bind w choose-tree -Zs
      # Expand the launching client's tty before display-popup runs its command.
      bind a run-shell -C 'display-popup -E -w 90% -h 85% "${self'.packages.ccmux}/bin/ccmux --client-tty #{client_tty}"'
      bind A run-shell '${self'.packages.ccmux}/bin/ccmux sidebar --toggle'
      bind e new-window -c '#{pane_current_path}' -n code '${self'.packages.kakoune}/bin/kak'
      bind r display-popup -E -w 95% -h 95% -d '#{pane_current_path}' '${repoPicker}/bin/mux-repo tuicr'
      bind g display-popup -E -w 95% -h 95% -d '#{pane_current_path}' '${repoPicker}/bin/mux-repo jjui'
      bind Space display-popup -E -w 80% -h 65% -d '#{pane_current_path}' '${self'.packages.sysq}/bin/sysq'

      # Start monitoring on terminal attachment, not on shell/devenv entry.
      set-hook -g client-attached 'run-shell -b "${self'.packages.ccmux}/bin/ccmux show >/dev/null 2>&1"'

      set -g status-position top
      set -g status-interval 5
      set -g status-style 'bg=${self.theme.base00},fg=${self.theme.base04}'
      set -g status-left '#[fg=${self.theme.base0D},bold] #S #[default] '
      set -g status-left-length 40
      set -g status-right '#[fg=${self.theme.base03}] ^b a agents | ^b w spaces | %H:%M '
      set -g status-right-length 55
      setw -g window-status-format ' #I:#W '
      setw -g window-status-current-format '#[fg=${self.theme.base00},bg=${self.theme.base0D},bold] #I:#W #[default]'
      set -g pane-border-style 'fg=${self.theme.base02}'
      set -g pane-active-border-style 'fg=${self.theme.base0D}'
      set -g message-style 'fg=${self.theme.base05},bg=${self.theme.base01}'
      set -g popup-style 'fg=${self.theme.base05},bg=${self.theme.base00}'
      set -g popup-border-style 'fg=${self.theme.base0D},bg=${self.theme.base00}'
    '';
    tmux = inputs.wrappers.lib.wrapPackage {
      inherit pkgs;
      package = tmuxCore;
      # Server-side background jobs inherit this PATH, independently of popups.
      runtimeInputs = [tmuxCore pkgs.coreutils self'.packages.ccmux self'.packages.kakoune self'.packages.jujutsu pkgs.jq pkgs.procps pkgs.wl-clipboard];
      flags."-f" = toString config;
    };
    project = pkgs.writeShellApplication {
      name = "mux";
      runtimeInputs = [tmux self'.packages.kakoune];
      text = ''exec ${python}/bin/python3 ${./.}/project.py "$@"'';
    };
  in {
    packages = {
      inherit tmux;
      tmux-project = project;
      tmux-repo = repoPicker;
    };
    checks.tmux-workflow =
      pkgs.runCommand "tmux-workflow-tests" {
        nativeBuildInputs = [testPython];
        TMUX_TEST_WRAPPER = lib.getExe tmux;
        TMUX_TEST_SHELL = lib.getExe pkgs.bash;
      } ''
        cp -r ${./.} source
        cd source
        python3 -B -m unittest discover -v
        touch "$out"
      '';
  };
}
