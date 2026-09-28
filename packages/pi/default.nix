{inputs, ...}: {
  perSystem = {
    pkgs,
    self',
    ...
  }: {
    packages.pi-unwrapped = inputs.pi.packages.${pkgs.stdenv.hostPlatform.system}.coding-agent;

    # Personal resources are a native local Pi package; the runtime only adds tools.
    packages.pi = inputs.wrappers.lib.wrapPackage {
      inherit pkgs;
      package = self'.packages.pi-unwrapped;
      runtimeInputs = [
        pkgs.clang-tools
        pkgs.eza
        pkgs.fd
        pkgs.gh
        pkgs.git
        pkgs.jujutsu
        pkgs.nodejs
        pkgs.ripgrep
        self'.packages.tuicr-agent-review
      ];
    };

    checks.pi-runtime = pkgs.runCommand "pi-runtime-check" {} ''
      export HOME="$TMPDIR/home"
      export PI_CODING_AGENT_DIR="$HOME/.pi/agent"
      mkdir -p "$PI_CODING_AGENT_DIR/agents" "$out"
      printf '%s\n' '{"defaultModel":"personal-model","theme":"light","packages":[]}' > "$PI_CODING_AGENT_DIR/settings.json"
      printf '%s\n' 'personal role' > "$PI_CODING_AGENT_DIR/agents/scout.md"
      cp -r "$PI_CODING_AGENT_DIR" before
      ${self'.packages.pi}/bin/pi --version > "$out/version"
      diff -r before "$PI_CODING_AGENT_DIR"
      export PI_CODING_AGENT_DIR="$HOME/unused-agent-dir"
      ${self'.packages.pi}/bin/pi --help > "$out/help"
      for resource in settings.json models.json APPEND_SYSTEM.md agents; do
        test ! -e "$PI_CODING_AGENT_DIR/$resource"
      done
    '';
  };
}
