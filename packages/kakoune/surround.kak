# Helix-style surround: <space>m then s/d/r and a delimiter key.

declare-user-mode surround
map global surround s ': surround-add-key<ret>' -docstring 'add pair around selections'
map global surround d ': surround-delete-key<ret>' -docstring 'delete pair around selections'
map global surround r ': surround-replace-key<ret>' -docstring 'replace pair around selections'

define-command -hidden surround-add-key %{
    echo -markup '{Information}surround: add which pair?'
    on-key %{ surround-add %val{key} }
}
define-command -hidden surround-delete-key %{
    echo -markup '{Information}surround: delete which pair?'
    on-key %{ surround-delete %val{key} }
}
define-command -hidden surround-replace-key %{
    echo -markup '{Information}surround: replace which pair?'
    on-key %{
        set-register s %val{key}
        echo -markup '{Information}surround: with which pair?'
        on-key %{ surround-replace %reg{s} %val{key} }
    }
}

define-command surround-add -params 1 -docstring 'surround-add <key>: wrap every selection in the matching pair' %{
    evaluate-commands %sh{
        case "$1" in
            '('|')') o='('; c=')' ;;
            '['|']') o='['; c=']' ;;
            '{'|'}') o='{'; c='}' ;;
            '<lt>'|'<gt>') o='<lt>'; c='<gt>' ;;
            *) o=$(printf %s "$1" | sed 's/"/""/g'); c=$o ;;
        esac
        printf 'execute-keys -itersel "Za%s<esc>zi%s<esc>"\n' "$c" "$o"
    }
}

define-command surround-delete -params 1 -docstring 'surround-delete <key>: remove the pair enclosing every selection' %{
    evaluate-commands %sh{
        key=$(printf %s "$1" | sed 's/"/""/g')
        printf 'execute-keys -itersel "<a-a>%ss\\A.|.\\z<ret>d"\n' "$key"
    }
}

define-command surround-replace -params 2 -docstring 'surround-replace <old> <new>: swap the pair enclosing every selection' %{
    evaluate-commands %sh{
        old=$(printf %s "$1" | sed 's/"/""/g')
        case "$2" in
            '('|')') o='('; c=')' ;;
            '['|']') o='['; c=']' ;;
            '{'|'}') o='{'; c='}' ;;
            '<lt>'|'<gt>') o='<lt>'; c='<gt>' ;;
            *) o=$(printf %s "$2" | sed 's/"/""/g'); c=$o ;;
        esac
        printf 'execute-keys -itersel "<a-a>%sZ<a-:>;r%sz<a-;>;r%s"\n' "$old" "$c" "$o"
    }
}
