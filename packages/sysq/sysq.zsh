_sysq_run() {
  local explain=${1:-0}
  local result_file
  result_file=$(mktemp "${TMPDIR:-/tmp}/sysq-result.XXXXXXXX") || return 1

  if [[ -n "${TMUX:-}" ]] && (( $+commands[tmux] )); then
    local popup_command
    if (( explain )); then
      popup_command="sysq explain --return-file ${(q)result_file} -- ${(q)BUFFER}"
    else
      popup_command="sysq --return-file ${(q)result_file}"
    fi
    tmux display-popup -E -w '80%' -h '65%' "$popup_command"
  elif (( explain )); then
    sysq explain --return-file "$result_file" -- "$BUFFER" </dev/tty >/dev/tty
  else
    sysq --return-file "$result_file" </dev/tty >/dev/tty
  fi
  local exit_code=$?

  if (( exit_code == 0 )) && [[ -s "$result_file" ]]; then
    BUFFER=$(<"$result_file")
    CURSOR=${#BUFFER}
  fi

  rm -f -- "$result_file"
  zle reset-prompt
  return $exit_code
}

_sysq_question_mark() {
  if [[ -n "$BUFFER" ]]; then
    LBUFFER+='?'
    return
  fi

  zle -I
  _sysq_run 0
}

_sysq_explain_buffer() {
  [[ -n "$BUFFER" ]] || return 0
  zle -I
  _sysq_run 1
}

zle -N _sysq_question_mark
zle -N _sysq_explain_buffer

bindkey '?' _sysq_question_mark
bindkey '^[?' _sysq_explain_buffer
