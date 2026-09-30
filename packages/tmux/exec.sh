# Run direct tmux commands in the same allowed environment as an interactive pane.
# direnv searches parents too, including across nested Git/Jujutsu repositories.
interactive=false
if [[ $# == 0 ]]; then
  interactive=true
  set -- "${SHELL:-bash}" -i
fi

directory=$PWD
while :; do
  if [[ -f "$directory/.envrc" ]]; then
    exec direnv exec "$PWD" "$@"
  fi
  [[ "$directory" == / ]] && break
  directory=${directory%/*}
  [[ -n "$directory" ]] || directory=/
done

if [[ $interactive == true ]]; then
  if [[ -f devenv.nix ]]; then
    exec devenv shell -- "$@"
  elif [[ -f flake.nix ]]; then
    exec nix develop --command "$@"
  fi
fi
exec "$@"
