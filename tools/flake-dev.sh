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

deployment_node() {
  local node=${1:-${FLAKE_HOST:-}}
  if [[ $# -gt 1 || ! $node =~ ^[a-zA-Z0-9_][a-zA-Z0-9_-]*$ ]]; then
    echo 'Choose one deploy node explicitly or with a host profile, e.g. tai-lung.' >&2
    exit 2
  fi
  printf '%s' "$node"
}

check_deployment() {
  local source=$1 node=$2
  # Resolve the actual activation derivation, not just a similarly named host.
  # No builds, SSH, activation, or hand-written copies of deploy-rs defaults.
  nix eval --json "path:$source#deploy.nodes.$node" \
    --no-write-lock-file --option allow-import-from-derivation false \
    "${skinem_input_flags[@]}" --apply 'node: {
      inherit (node) hostname;
      sshUser = node.sshUser or null;
      activation = node.profiles.system.path.drvPath;
    }'
}

require_deploy_terminal() {
  if [[ -n ${CI:-} || -n ${GITHUB_ACTIONS:-} || ! -t 0 || ! -t 1 ]]; then
    echo 'Deploy requires a local terminal for confirmation and sudo; it is disabled in CI.' >&2
    echo 'Use: devenv --profile tai-lung shell flake-deploy' >&2
    exit 2
  fi
}

deploy_system() {
  local source=$1 node=$2
  # Keep upstream checks, confirmation, sudo, and rollback behavior intact.
  # Forward private-source overrides to BOTH the client and its Nix subprocesses.
  nix run "path:$source#deploy-rs" --no-write-lock-file "${skinem_input_flags[@]}" -- \
    "path:$source#$node.system" --interactive -- \
    --no-write-lock-file --show-trace "${skinem_input_flags[@]}"
}

command=${1:-help}
shift || true
case "$command" in
  format) format_nix "$@" ;;
  eval|check)
    flags=()
    # No hidden builds during evaluation, even on a runner with a cold store.
    [[ $command == eval ]] && flags+=(--no-build --option allow-import-from-derivation false)
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
  deploy|deploy-check)
    node=$(deployment_node "$@")
    [[ $command == deploy ]] && require_deploy_terminal
    source=$(source_snapshot)
    check_deployment "$source" "$node"
    [[ $command == deploy-check ]] || deploy_system "$source" "$node"
    ;;
  *)
    echo 'Usage: bash tools/flake-dev.sh {format [--check]|eval|check|build PACKAGE|host HOST|deploy-check [NODE]|deploy [NODE]}' >&2
    exit 2
    ;;
esac
