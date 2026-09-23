#!/usr/bin/env bash
set -euo pipefail

cd "${DEVENV_ROOT:-$(dirname "${BASH_SOURCE[0]}")/..}"
export FLAKE_DEV_ROOT="$PWD"

source_snapshot() {
  nix eval --impure --raw --expr \
    '(import ./tools/_sources.nix).snapshot (builtins.getEnv "FLAKE_DEV_ROOT")'
}

skinem_input_flags=()
if [[ -n ${FLAKE_SKINEM_SOURCE:-} ]]; then
  if [[ $FLAKE_SKINEM_SOURCE != /* || ! -f $FLAKE_SKINEM_SOURCE/flake.nix ]]; then
    echo 'FLAKE_SKINEM_SOURCE must be an absolute path to a skinem flake checkout.' >&2
    exit 2
  fi
  skinem_input_flags=(--override-input skinem "path:$FLAKE_SKINEM_SOURCE")
fi

format_nix() {
  local files
  files=$(nix eval --impure --json --expr \
    '(import ./tools/_sources.nix).nixFiles (builtins.toPath (builtins.getEnv "FLAKE_DEV_ROOT"))')
  printf '%s' "$files" | jq --raw-output0 '.[]' | xargs -0 -r alejandra "$@"
}

build_output() {
  local attribute=$1 link=$2 source
  source=$(source_snapshot)
  mkdir -p .devenv/builds
  nix build "path:$source#$attribute" --no-write-lock-file --show-trace \
    "${skinem_input_flags[@]}" --out-link "$PWD/.devenv/builds/$link"
}

command=${1:-help}
shift || true
case "$command" in
  format) format_nix "$@" ;;
  eval|check)
    flags=()
    [[ $command == eval ]] && flags+=(--no-build)
    source=$(source_snapshot)
    nix flake check "path:$source" --no-write-lock-file --show-trace \
      "${skinem_input_flags[@]}" "${flags[@]}"
    ;;
  build)
    if [[ $# != 1 || ! $1 =~ ^[a-zA-Z0-9_][a-zA-Z0-9_-]*$ ]]; then
      echo 'Usage: flake-build <package-output>, e.g. environment' >&2
      exit 2
    fi
    build_output "$1" "$1"
    ;;
  host)
    host=${1:-${FLAKE_HOST:-}}
    if [[ $# -gt 1 ]]; then
      echo 'Usage: flake-host [aku|gru|lich|tai-lung]' >&2
      exit 2
    fi
    case "$host" in
      aku|gru|lich|tai-lung) ;;
      *) echo 'Choose a host argument or a devenv host profile: aku, gru, lich, tai-lung.' >&2; exit 2 ;;
    esac
    build_output "nixosConfigurations.$host.config.system.build.toplevel" "host-$host"
    ;;
  *)
    echo 'Usage: bash tools/flake-dev.sh {format [--check]|eval|check|build PACKAGE|host HOST}' >&2
    exit 2
    ;;
esac
