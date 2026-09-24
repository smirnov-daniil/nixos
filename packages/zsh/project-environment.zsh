# Keep the wrapper's standard completions when a project modifies PATH in place.
typeset -ga _flake_base_fpath
_flake_base_fpath=($fpath)

_flake_project_completions() {
  [[ ${_flake_completion_path-} == "$PATH" ]] && return
  _flake_completion_path=$PATH
  local bin directory
  local -a directories
  for bin in $path; do
    for directory in "$bin/../share/zsh/site-functions" "$bin/../share/zsh/vendor-completions"; do
      [[ -d $directory ]] && directories+=(${directory:A})
    done
  done
  local -a previous_fpath
  previous_fpath=($fpath)
  typeset -gU fpath
  fpath=($directories $_flake_base_fpath)
  if [[ ${(j.:.)previous_fpath} != ${(j.:.)fpath} ]]; then
    autoload -Uz compinit
    compinit -u
  fi
}
