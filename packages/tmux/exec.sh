# Run direct tmux commands in the same allowed environment as an interactive pane.
# direnv searches parents too, including across nested Git/Jujutsu repositories.
directory=$PWD
while :; do
  if [[ -f "$directory/.envrc" ]]; then
    exec direnv exec "$PWD" "$@"
  fi
  [[ "$directory" == / ]] && break
  directory=${directory%/*}
  [[ -n "$directory" ]] || directory=/
done
exec "$@"
