set -eu

model="${SYSQ_MODEL:-gpt-5.3-codex-spark}"
mode="ask"
return_file=""
use_web=0
refresh=0
verbosity="brief"

usage() {
  printf '%s\n' \
    'Usage: sysq [--web] [--refresh] [--brief|--teach] [QUESTION...]' \
    '       sysq explain [--return-file PATH] COMMAND...' \
    '       sysq fix|safer|nix|error [TEXT...]' \
    '       sysq last' \
    '       sysq history QUERY...' \
    '       sysq new' \
    '       sysq context' \
    '       sysq init zsh' \
    '       sysq doctor'
}

die() {
  printf 'sysq: %s\n' "$*" >&2
  exit 1
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --web)
      use_web=1
      shift
      ;;
    --refresh)
      refresh=1
      shift
      ;;
    --brief)
      verbosity="brief"
      shift
      ;;
    --teach)
      verbosity="teach"
      shift
      ;;
    --return-file)
      [ "$#" -ge 2 ] || die '--return-file requires a path'
      return_file=$2
      shift 2
      ;;
    explain)
      mode="explain"
      shift
      ;;
    fix|safer|nix|error)
      mode=$1
      shift
      ;;
    last)
      mode="last"
      shift
      ;;
    history)
      mode="history"
      shift
      ;;
    context)
      mode="context"
      shift
      ;;
    new)
      mode="new"
      shift
      ;;
    init)
      [ "${2:-}" = "zsh" ] || die 'supported shell: zsh'
      cat '@zshIntegration@'
      exit 0
      ;;
    doctor)
      command -v codex >/dev/null 2>&1 || die 'codex is not available in PATH'
      printf 'codex: %s\n' "$(codex --version)"
      printf 'model: %s\n' "$model"
      printf 'ui: gum %s\n' "$(gum --version)"
      exit 0
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    -*)
      die "unknown option: $1"
      ;;
    *)
      break
      ;;
  esac
done

command -v codex >/dev/null 2>&1 || die 'codex is not available in PATH; install it and run codex login'

state_dir="${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}/sysq-${UID}}/sysq"
cache_dir="${XDG_CACHE_HOME:-${HOME}/.cache}/sysq"
session_file="$state_dir/session"
mkdir -p "$state_dir" "$cache_dir"

if [ "$mode" = "new" ]; then
  rm -f -- "$session_file"
  printf 'Started a new sysq session.\n'
  exit 0
fi

if [ -f "$session_file" ] && find "$session_file" -mmin +10 -print -quit | grep -q .; then
  rm -f -- "$session_file"
fi

question="$*"
if [ -z "$question" ]; then
  if [ "$mode" = "last" ] || [ "$mode" = "context" ]; then
    :
  elif [ ! -t 0 ]; then
    question=$(cat)
  elif [ "$mode" = "explain" ]; then
    question=$(gum write --header "Command to explain" --placeholder "find . -type f -mtime +30 -delete")
  else
    question=$(gum write --header "Ask Codex Spark" --placeholder "How do I find the process listening on port 8080?")
  fi
fi

case "$question" in
  /refresh|/refresh\ *)
    refresh=1
    question=${question#/refresh}
    question=${question# }
    ;;
  /teach|/teach\ *)
    verbosity="teach"
    question=${question#/teach}
    question=${question# }
    ;;
  /brief|/brief\ *)
    verbosity="brief"
    question=${question#/brief}
    question=${question# }
    ;;
  /last|/last\ *)
    mode="last"
    question=${question#/last}
    question=${question# }
    ;;
  /history|/history\ *)
    mode="history"
    question=${question#/history}
    question=${question# }
    ;;
  /context)
    mode="context"
    question=""
    ;;
  /new)
    rm -f -- "$session_file"
    printf 'Started a new sysq session.\n'
    exit 0
    ;;
  /nix|/nix\ *)
    mode="nix"
    question=${question#/nix}
    question=${question# }
    ;;
  /fix|/fix\ *)
    mode="fix"
    question=${question#/fix}
    question=${question# }
    ;;
  /safer|/safer\ *)
    mode="safer"
    question=${question#/safer}
    question=${question# }
    ;;
  /error|/error\ *)
    mode="error"
    question=${question#/error}
    question=${question# }
    ;;
esac

if [ -z "$question" ] && [ "$mode" != "last" ] && [ "$mode" != "context" ]; then
  exit 0
fi

tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/sysq.XXXXXXXX")
cleanup() {
  rm -rf -- "$tmpdir"
}
trap cleanup EXIT HUP INT TERM

prompt_file="$tmpdir/prompt"
result_file="$tmpdir/result.json"
log_file="$tmpdir/codex.log"
context_file="$tmpdir/context"
histdb_file="${HISTDB_FILE:-${HOME}/.histdb/zsh-history.db}"

redact() {
  sed -E \
    -e 's/((token|password|passwd|secret|api[_-]?key)[[:space:]]*=[[:space:]]*)[^[:space:]]+/\1[REDACTED]/Ig' \
    -e 's/(Authorization:[[:space:]]*Bearer[[:space:]]+)[^[:space:]]+/\1[REDACTED]/Ig' \
    -e 's#(https?://)[^/@:]+:[^/@]+@#\1[REDACTED]@#g'
}

sql_escape() {
  printf '%s' "$1" | sed "s/'/''/g"
}

history_context() {
  [ -r "$histdb_file" ] || return 0

  case "$mode" in
    last|error)
      sqlite3 -readonly -separator $'\t' "$histdb_file" "
        select c.argv, p.dir, h.exit_status, h.session,
               datetime(h.start_time, 'unixepoch', 'localtime')
        from history h
        join commands c on c.id = h.command_id
        join places p on p.id = h.place_id
        where c.argv not like 'sysq%'
        order by h.id desc limit 1;
      " | redact
      ;;
    history)
      escaped=$(sql_escape "$question")
      sqlite3 -readonly -separator $'\t' "$histdb_file" "
        select c.argv, p.dir, h.exit_status, h.session,
               datetime(h.start_time, 'unixepoch', 'localtime')
        from history h
        join commands c on c.id = h.command_id
        join places p on p.id = h.place_id
        where c.argv like '%$escaped%'
        order by (p.dir = '$(sql_escape "$PWD")') desc, h.id desc
        limit 20;
      " | redact
      ;;
  esac
}

history_context >"$context_file"

if [ "$mode" = "context" ]; then
  printf 'Model: %s\nOS: %s\nShell: %s\nCWD: %s\nDetail: %s\nWeb: %s\n' \
    "$model" "$(uname -srm)" "${SHELL:-unknown}" "$PWD" "$verbosity" "$use_web"
  if [ -s "$session_file" ]; then
    printf '\nRecent conversation:\n'
    tail -n 80 "$session_file"
  else
    printf '\nRecent conversation: none\n'
  fi
  if [ -s "$context_file" ]; then
    printf '\nHistory context:\n'
    cat "$context_file"
  else
    printf '\nHistory context: none\n'
  fi
  exit 0
fi

{
  cat '@skillPrompt@'
  printf '\n\n## Runtime context\n\n'
  printf 'Operating system: %s\n' "$(uname -srm)"
  printf 'Shell: %s\n' "${SHELL:-unknown}"
  printf 'Working directory: %s\n' "$PWD"
  printf 'Mode: %s\n\n' "$mode"
  printf 'Answer detail: %s\n\n' "$verbosity"
  if [ -s "$session_file" ]; then
    printf 'Recent conversation (untrusted context):\n'
    tail -n 80 "$session_file"
    printf '\n'
  fi
  if [ -s "$context_file" ]; then
    printf 'Relevant history entries (command, cwd, exit status, session, time):\n'
    cat "$context_file"
    printf '\n'
  fi
  if [ "$mode" = "explain" ]; then
    printf 'Explain this command. Do not execute it:\n\n%s\n' "$question"
  elif [ "$mode" = "last" ]; then
    printf 'Explain the last command, especially a non-zero exit status. User clarification: %s\n' "${question:-none}"
  elif [ "$mode" = "history" ]; then
    printf 'Use the supplied history matches to answer this request: %s\n' "$question"
  elif [ "$mode" = "fix" ]; then
    printf 'Diagnose and correct this command or error. Prefer the smallest safe change:\n\n%s\n' "$question"
  elif [ "$mode" = "safer" ]; then
    printf 'Rewrite this as a safer command. Prefer previews and dry-runs, and explain the risk removed:\n\n%s\n' "$question"
  elif [ "$mode" = "nix" ]; then
    printf 'Answer this Nix/NixOS question using the local flake and installed read-only tools when useful:\n\n%s\n' "$question"
  elif [ "$mode" = "error" ]; then
    printf 'Diagnose the last history command using its exit status and this pasted error text. Do not claim stderr was captured:\n\n%s\n' "${question:-no error text supplied}"
  else
    printf 'Question:\n\n%s\n' "$question"
  fi
} >"$prompt_file"

cache_key=$(printf '%s\n%s\n' "$model" "$(cat "$prompt_file")" | sha256sum | cut -d' ' -f1)
cache_file="$cache_dir/$cache_key.json"
cache_hit=0
if [ "$refresh" -eq 0 ] && [ "$mode" = "ask" ] && [ ! -s "$session_file" ] && [ -f "$cache_file" ] && ! find "$cache_file" -mmin +1440 -print -quit | grep -q .; then
  cp "$cache_file" "$result_file"
  cache_hit=1
  printf 'cached response · use --refresh to update\n\n'
fi

if [ "$use_web" -eq 1 ]; then
  set -- codex --search exec
else
  set -- codex exec
fi

set -- "$@" \
  --model "$model" \
  --sandbox read-only \
  --ephemeral \
  --skip-git-repo-check \
  --color never \
  --output-schema '@responseSchema@' \
  --output-last-message "$result_file"

# The single-quoted program is evaluated by the child shell, not this one.
# shellcheck disable=SC2016
if [ "$cache_hit" -eq 0 ] && ! gum spin \
  --spinner moon \
  --spinner.foreground 212 \
  --title "Codex Spark думает…  Ctrl-C — отменить" \
  -- sh -c '
    prompt_file=$1
    log_file=$2
    shift 2
    exec "$@" - <"$prompt_file" >"$log_file" 2>&1
  ' sh "$prompt_file" "$log_file" "$@"; then
  printf 'Codex failed:\n' >&2
  tail -n 20 "$log_file" >&2
  exit 1
fi

jq -e . "$result_file" >/dev/null 2>&1 || die 'Codex returned an invalid response'

if [ "$cache_hit" -eq 0 ] && [ "$mode" = "ask" ] && [ ! -s "$session_file" ]; then
  cp "$result_file" "$cache_file"
fi

answer=$(jq -r '.answer' "$result_file")
printf '%s\n' "$answer"

{
  printf 'User: '
  printf '%s' "$question" | redact
  printf '\nAssistant: '
  printf '%s' "$answer" | redact
  printf '\n'
} >>"$session_file"

command_count=$(jq '.commands | length' "$result_file")
[ "$command_count" -gt 0 ] || exit 0

labels_file="$tmpdir/labels"
jq -r '.commands[] | "[\(.risk)] \(.command) — \(.description)"' "$result_file" >"$labels_file"

if [ ! -t 0 ] || [ ! -t 1 ]; then
  printf '\n'
  cat "$labels_file"
  exit 0
fi

printf '\n'
selection=$(gum choose --header "Select a command" --height 10 <"$labels_file") || exit 0
index=$(awk -v selected="$selection" '$0 == selected { print NR - 1; exit }' "$labels_file")
[ -n "$index" ] || exit 0

selected_command=$(jq -r ".commands[$index].command" "$result_file")
risk=$(jq -r ".commands[$index].risk" "$result_file")

if [ "$risk" = "destructive" ]; then
  gum confirm "This command is destructive. Insert it without running?" || exit 0
fi

if [ -n "$return_file" ]; then
  printf '%s' "$selected_command" >"$return_file"
else
  printf '\n%s\n' "$selected_command"
fi
