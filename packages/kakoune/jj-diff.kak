# Gutter flags for lines changed relative to a jj revset (default: trunk()).
# Complements kakoune's builtin `git show-diff`, which flags the working copy
# against HEAD (= the parent of @ in a colocated jj repo).

declare-option -hidden line-specs jj_diff_flags
declare-option -docstring 'revset the buffer is compared against by jj-show-diff' str jj_diff_base 'trunk()'

define-command jj-show-diff -docstring 'jj-show-diff: flag lines changed relative to %opt{jj_diff_base}' %{
    try %{ add-highlighter window/jj-diff flag-lines Default jj_diff_flags }
    jj-update-diff
    hook -group jj-diff window BufWritePost .* jj-update-diff
    hook -group jj-diff window BufReload .* jj-update-diff
}

define-command jj-hide-diff -docstring 'jj-hide-diff: remove the jj diff flags' %{
    try %{ remove-highlighter window/jj-diff }
    remove-hooks window jj-diff
}

define-command -hidden jj-update-diff %{
    evaluate-commands %sh{
        dir=$(dirname "$kak_buffile")
        root=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null) || exit 0
        base=$(jj -R "$root" log --ignore-working-copy --no-graph -r "$kak_opt_jj_diff_base" -T commit_id 2>/dev/null) || exit 0
        [ -n "$base" ] || exit 0
        rel=${kak_buffile#"$root/"}
        echo >"$kak_command_fifo" "evaluate-commands -no-hooks write $kak_response_fifo"
        flags=$( { git -C "$root" show "$base:$rel" 2>/dev/null || true; } |
            diff -U0 - "$kak_response_fifo" |
            awk '/^@@/ {
                split(substr($2, 2), a, ","); fc = (a[2] == "" ? 1 : a[2])
                split(substr($3, 2), b, ","); tl = b[1]; tc = (b[2] == "" ? 1 : b[2])
                if (fc == 0) {
                    for (i = 0; i < tc; i++) printf " %d|{green}+", tl + i
                } else if (tc == 0) {
                    if (tl == 0) printf " 1|{red}‾"; else printf " %d|{red}_", tl
                } else if (fc == tc) {
                    for (i = 0; i < tc; i++) printf " %d|{blue}~", tl + i
                } else if (fc < tc) {
                    for (i = 0; i < fc; i++) printf " %d|{blue}~", tl + i
                    for (i = fc; i < tc; i++) printf " %d|{green}+", tl + i
                } else {
                    for (i = 0; i < tc - 1; i++) printf " %d|{blue}~", tl + i
                    printf " %d|{blue+u}~", tl + tc - 1
                }
            }')
        printf 'set-option window jj_diff_flags %s%s\n' "$kak_timestamp" "$flags"
    }
}
