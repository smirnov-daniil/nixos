# QML: javascript highlighting and indentation, qmlls via kakoune-lsp (see kakrc).

hook global BufCreate .*[.]qml %{
    set-option buffer filetype qml
}

hook global BufSetOption filetype=qml %{
    set-option buffer comment_line '//'
    set-option buffer comment_block_begin '/*'
    set-option buffer comment_block_end '*/'
}

hook global WinSetOption filetype=qml %{
    require-module javascript

    hook window ModeChange pop:insert:.* -group qml-trim-indent javascript-trim-indent
    hook window InsertChar .* -group qml-indent javascript-indent-on-char
    hook window InsertChar \n -group qml-insert javascript-insert-on-new-line
    hook window InsertChar \n -group qml-indent javascript-indent-on-new-line

    hook -once -always window WinSetOption filetype=.* %{ remove-hooks window qml-.+ }
}

hook -group qml-highlight global WinSetOption filetype=qml %{
    add-highlighter window/qml ref javascript
    hook -once -always window WinSetOption filetype=.* %{ remove-highlighter window/qml }
}
