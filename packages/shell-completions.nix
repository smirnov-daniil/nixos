{lib, ...}: {
  perSystem = {pkgs, ...}: {
    packages.shell-completions = pkgs.linkFarm "shell-completions" (
      lib.mapAttrsToList (name: text: {
        name = "share/zsh/site-functions/${name}";
        path = pkgs.writeText name text;
      }) {
        _codex = ''
          #compdef codex
          local completion
          completion=$(codex completion zsh) || return
          eval "$completion"
          _codex "$@"
        '';
        _claude = ''
          #compdef claude
          # Read only help, including nested commands recognized by the CLI.
          local help_text word
          local -a invocation subcommands options
          invocation=(claude)
          local -i index=2
          while true; do
            help_text=$(command "''${invocation[@]}" --help 2>/dev/null) || return
            subcommands=("''${(@f)$(printf '%s\n' "$help_text" | awk '
              /^Commands:/ { commands = 1; next }
              commands && /^  [[:alnum:]]/ {
                count = split($1, names, "|")
                for (i = 1; i <= count; i++) print names[i]
              }
            ')}")
            (( index < CURRENT )) || break
            word=$words[index]
            (( ''${subcommands[(Ie)$word]} )) || break
            invocation+=("$word")
            (( index++ ))
          done
          if [[ $PREFIX = -* ]]; then
            options=("''${(@f)$(printf '%s\n' "$help_text" | awk '
              /^  *-/ {
                for (i = 1; i <= NF && $i ~ /^-/; i++) {
                  gsub(/,/, "", $i)
                  print $i
                }
              }
            ')}")
            _describe 'option' options
          else
            if (( index == CURRENT )); then
              _describe 'command' subcommands
            fi
            _files
          fi
        '';
        _sysq = ''
          #compdef sysq
          local context state state_descr line
          local -A opt_args
          _arguments -C \
            '--web[Enable web search]' \
            '--refresh[Refresh context]' \
            '(--teach)--brief[Use brief answers]' \
            '(--brief)--teach[Explain in detail]' \
            '--return-file[Write result to a file]:file:_files' \
            '(-h --help)'{-h,--help}'[Show help]' \
            '1:command:(explain fix safer nix error last history new context init doctor)' \
            '*::argument:->args'
          if [[ $state = args ]]; then
            case $line[1] in
              explain) _normal ;;
              init) _values 'shell' zsh ;;
              *) _files ;;
            esac
          fi
        '';
      }
    );
  };
}
