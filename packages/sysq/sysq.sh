set -eu

model="${SYSQ_MODEL:-}"
model_explicit=0
[ -z "$model" ] || model_explicit=1
mode="ask"
return_file=""
use_web=0
refresh=0
verbosity="brief"

usage() {
  printf '%s\n' \
    'Usage: sysq [--model PROVIDER/MODEL] [--web] [--refresh] [--brief|--teach] [QUESTION...]' \
    '       sysq explain [--return-file PATH] COMMAND...' \
    '       sysq fix|safer|nix|error [TEXT...]' \
    '       sysq last' \
    '       sysq history QUERY...' \
    '       sysq new' \
    '       sysq context' \
    '       sysq models' \
    '       sysq model [PROVIDER/MODEL]' \
    '       sysq init zsh' \
    '       sysq doctor' \
    '' \
    'Model: --model, then SYSQ_MODEL, then the saved selection.' \
    'Run sysq model to choose and save an available Pi model.'
}

die() {
  printf 'sysq: %s\n' "$*" >&2
  exit 1
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --model)
      [ "$#" -ge 2 ] && [ -n "$2" ] || die '--model requires PROVIDER/MODEL'
      model=$2
      model_explicit=1
      shift 2
      ;;
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
    context|model|models|doctor)
      mode=$1
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

command -v pi >/dev/null 2>&1 || die 'pi is not available in PATH; install it and use /login in Pi'

state_dir="${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}/sysq-${UID}}/sysq"
cache_dir="${XDG_CACHE_HOME:-${HOME}/.cache}/sysq"
session_file="$state_dir/session"
model_file="$cache_dir/model"
mkdir -p "$state_dir" "$cache_dir"
if [ -z "$model" ] && [ -r "$model_file" ]; then
  model=$(cat "$model_file")
fi

pi_options=(--offline --no-extensions --no-skills --no-prompt-templates --no-themes --no-context-files --no-approve)

list_models() {
  local catalog
  catalog=$(pi "${pi_options[@]}" --list-models) || die 'could not list Pi models; check Pi authentication and configuration'
  printf '%s\n' "$catalog" | awk '
    $1 == "provider" && $2 == "model" { table = 1; next }
    table && NF >= 6 { print $1 "/" $2 }
  ' | sort -u
}

select_model() {
  local available selected matches
  available=$(list_models)
  [ -n "$available" ] || die 'no available Pi models; use /login in Pi or configure models.json'
  matches=$(printf '%s\n' "$available" | awk -v selected="$model" '$0 == selected')
  if [ -z "$matches" ]; then
    matches=$(printf '%s\n' "$available" | awk -v selected="$model" 'substr($0, index($0, "/") + 1) == selected')
  fi
  if [ -n "$matches" ] && [ "$(printf '%s\n' "$matches" | wc -l)" -eq 1 ]; then
    model=$matches
  elif [ -n "$model" ] && [ "$model_explicit" -eq 1 ]; then
    die "model '$model' is unavailable or ambiguous; run sysq models and use PROVIDER/MODEL"
  elif [ -t 0 ] && [ -t 1 ]; then
    selected=$(printf '%s\n' "$available" | gum filter --header 'Choose a Pi model') || exit 0
    [ -n "$selected" ] || exit 0
    printf '%s\n' "$available" | grep -Fxq -- "$selected" || die 'invalid model selection'
    model=$selected
    printf '%s\n' "$model" >"$model_file"
  else
    printf 'Available Pi models:\n%s\n' "$available" >&2
    die 'choose a model with sysq model, --model PROVIDER/MODEL or SYSQ_MODEL'
  fi
}

case "$mode" in
  models)
    list_models
    exit 0
    ;;
  model)
    if [ "$#" -gt 0 ]; then
      [ "$#" -eq 1 ] || die 'sysq model accepts one PROVIDER/MODEL'
      model=$1
      model_explicit=1
    else
      model=""
      model_explicit=0
    fi
    select_model
    printf '%s\n' "$model" >"$model_file"
    printf 'Saved Pi model: %s\n' "$model"
    exit 0
    ;;
  doctor)
    printf 'pi: %s\n' "$(pi --version)"
    printf 'model: %s\n' "${model:-not selected (run sysq model)}"
    printf 'ui: gum %s\n' "$(gum --version)"
    printf '\nAvailable Pi models:\n'
    list_models
    exit 0
    ;;
esac

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
    question=$(gum write --header "Ask Pi" --placeholder "How do I find the process listening on port 8080?")
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
system_file="$tmpdir/system"
result_file="$tmpdir/result.json"
output_file="$tmpdir/pi-output"
log_file="$tmpdir/pi.log"
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
    "${model:-not selected (run sysq model)}" "$(uname -srm)" "${SHELL:-unknown}" "$PWD" "$verbosity" "$use_web"
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

select_model

tools='read,grep,find,ls'
if [ "$use_web" -eq 1 ]; then
  agent_dir="${PI_CODING_AGENT_DIR:-${HOME}/.pi/agent}"
  search_extension="${SYSQ_WEB_SEARCH_EXTENSION:-$agent_dir/npm/node_modules/pi-smart-web-search/index.ts}"
  fetch_extension="${SYSQ_WEB_FETCH_EXTENSION:-$agent_dir/npm/node_modules/pi-smart-fetch/dist/index.js}"
  [ -r "$search_extension" ] && [ -r "$fetch_extension" ] || die '--web requires Pi packages pi-smart-web-search and pi-smart-fetch; install them with pi install npm:PACKAGE or set SYSQ_WEB_SEARCH_EXTENSION and SYSQ_WEB_FETCH_EXTENSION'
  pi_options+=(-e "$search_extension" -e "$fetch_extension")
  tools+=',web_search,web_fetch,batch_web_fetch'
fi

{
  cat '@skillPrompt@'
  printf '\n\nReturn only a JSON object matching this schema, without Markdown fences or extra text:\n'
  cat '@responseSchema@'
  if [ "$use_web" -eq 0 ]; then
    printf '\nWeb access is disabled. Use only the supplied context and local read-only tools.\n'
  else
    printf '\nWeb search is enabled. Use web_search and fetch primary sources when current information matters.\n'
  fi
} >"$system_file"

{
  printf '## Runtime context\n\n'
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

cache_key=$(printf '%s\n' 'pi-v1' "$model" "$use_web" "$(cat "$system_file")" "$(cat "$prompt_file")" | sha256sum | cut -d' ' -f1)
cache_file="$cache_dir/$cache_key.json"
cache_hit=0
if [ "$refresh" -eq 0 ] && [ "$mode" = "ask" ] && [ ! -s "$session_file" ] && [ -f "$cache_file" ] && ! find "$cache_file" -mmin +1440 -print -quit | grep -q .; then
  cp "$cache_file" "$result_file"
  cache_hit=1
  printf 'cached response · use --refresh to update\n\n'
fi

set -- pi "${pi_options[@]}" \
  --provider "${model%%/*}" \
  --model "${model#*/}" \
  --tools "$tools" \
  --system-prompt "$(cat "$system_file")" \
  --append-system-prompt '' \
  --no-session \
  --print

# The single-quoted program is evaluated by the child shell, not this one.
# shellcheck disable=SC2016
set -- sh -c '
  prompt_file=$1
  output_file=$2
  log_file=$3
  shift 3
  exec "$@" <"$prompt_file" >"$output_file" 2>"$log_file"
' sh "$prompt_file" "$output_file" "$log_file" "$@"

if [ -t 1 ]; then
  set -- gum spin \
    --spinner moon \
    --spinner.foreground 212 \
    --title "Pi · $model думает…  Ctrl-C — отменить" \
    -- "$@"
fi

if [ "$cache_hit" -eq 0 ] && ! "$@"; then
  printf 'Pi failed:\n' >&2
  tail -n 20 "$log_file" >&2
  exit 1
fi

if [ "$cache_hit" -eq 0 ]; then
  jq -Rs 'sub("^\\s*```(?:json)?\\s*\\n"; "") | sub("\\n```\\s*$"; "") | fromjson' "$output_file" >"$result_file" 2>/dev/null || die 'Pi returned an invalid JSON response'
fi

jq -e '
  type == "object" and keys == ["answer", "commands", "needs_clarification"] and
  (.answer | type == "string") and
  (.needs_clarification | type == "boolean") and
  (.commands | type == "array" and all(.[];
    type == "object" and keys == ["command", "description", "risk"] and
    (.command | type == "string") and
    (.description | type == "string") and
    (.risk | . == "read-only" or . == "changes-files" or . == "destructive")
  ))
' "$result_file" >/dev/null 2>&1 || die 'Pi returned a response that does not match the sysq schema'

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
