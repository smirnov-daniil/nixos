# Run direct tmux commands in the same allowed environment as an interactive pane.
project_root=$(devenv hook-should-activate) || exit "$?"

if [[ $# == 0 ]]; then
  if [[ -z "$project_root" && -f flake.nix ]]; then
    exec nix develop --command "${SHELL:-bash}" -i
  fi
  exec "${SHELL:-bash}" -i
fi

if [[ -n "$project_root" && ${DEVENV_ROOT:-} != "$project_root" ]]; then
  original_pwd=$PWD
  cd -- "$project_root" || exit "$?"
  exec devenv --no-tui shell -- bash -c $'cd -- "$1" || exit "$?"; shift; exec "$@"' mux-exec "$original_pwd" "$@"
fi
exec "$@"
