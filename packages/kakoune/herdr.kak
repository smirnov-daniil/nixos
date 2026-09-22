# Kakoune windowing module for herdr (terminal workspace manager).
# Detected only when the server was started inside herdr; other multiplexers
# fall through to kakoune's builtin modules (tmux, zellij, kitty, niri, ...).
#
# `herdr pane run` types its arguments into the pane's shell as plain text, so
# the command is pre-quoted into a single string and sent once the shell has
# drawn its prompt.

provide-module herdr %{

evaluate-commands %sh{
    [ -z "${kak_opt_windowing_modules}" ] || [ -n "$HERDR_ENV" ] || echo 'fail herdr not detected'
}

define-command -hidden herdr-terminal-impl -params 2.. %{
    nop %sh{
        direction=$1
        shift
        quoted=""
        for arg; do
            quoted="$quoted '$(printf %s "$arg" | sed "s/'/'\\''/g")'"
        done
        pane=$(herdr pane split --pane "${kak_client_env_HERDR_PANE_ID:-$HERDR_PANE_ID}" \
                   --direction "$direction" --ratio 0.35 --focus 2>/dev/null |
               sed -n 's/.*"pane_id":"\([^"]*\)".*/\1/p' | head -n 1)
        [ -n "$pane" ] || exit 0
        {
            # wait for the shell prompt before typing into the pane
            i=0
            while [ $i -lt 30 ]; do
                if herdr pane read "$pane" 2>/dev/null | grep -q '[^[:space:]]'; then
                    break
                fi
                sleep 0.1
                i=$((i + 1))
            done
            sleep 0.1
            herdr pane run "$pane" "$quoted; herdr pane close \"\$HERDR_PANE_ID\""
        } >/dev/null 2>&1 </dev/null &
    }
}

define-command herdr-terminal-vertical -params 1.. -docstring '
herdr-terminal-vertical <program> [<arguments>]: run program in a new pane below the current one' %{
    herdr-terminal-impl down %arg{@}
}
complete-command herdr-terminal-vertical shell

define-command herdr-terminal-horizontal -params 1.. -docstring '
herdr-terminal-horizontal <program> [<arguments>]: run program in a new pane right of the current one' %{
    herdr-terminal-impl right %arg{@}
}
complete-command herdr-terminal-horizontal shell

define-command herdr-terminal-window -params 1.. -docstring '
herdr-terminal-window <program> [<arguments>]: run program in a new pane (herdr has no detached windows)' %{
    herdr-terminal-impl down %arg{@}
}
complete-command herdr-terminal-window shell

define-command herdr-focus -params ..1 -docstring '
herdr-focus [<client>]: focusing another client is not supported under herdr' %{
    nop
}

alias global focus herdr-focus

}
