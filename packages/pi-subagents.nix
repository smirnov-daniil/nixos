{
  inputs,
  lib,
  ...
}: {
  perSystem = {pkgs, ...}: let
    basePi = inputs.pi.packages.${pkgs.stdenv.hostPlatform.system}.coding-agent;
  in {
    packages.pi-subagents = pkgs.buildNpmPackage {
      pname = "pi-subagents";
      version = "0.14.3-unstable-2026-07-31";
      src = inputs.pi-subagents;

      patches = [
        ./pi-subagents/jj-workspaces.patch
        ./pi-subagents/lock-integrity.patch
        ./pi-subagents/provider-portable.patch
        ./pi-subagents/temp-job-storage.patch
      ];

      npmDepsHash = "sha256-H1f6FXgLDjaZy6mdQN5Ax5bud6FS6N7dnIRNx5BrvzM=";
      npmInstallFlags = ["--legacy-peer-deps"];
      dontNpmBuild = true;

      nativeCheckInputs = [
        pkgs.git
        pkgs.jujutsu
      ];
      doCheck = true;
      checkPhase = ''
        runHook preCheck
        ln -s ${basePi}/lib/node_modules/@earendil-works node_modules/@earendil-works
        cp ${./pi-subagents/jj-workspaces.test.ts} test/jj-workspaces.test.ts
        npx vitest run \
          --exclude test/env.test.ts \
          --exclude test/nested-delegation-e2e.test.ts \
          --exclude test/subagent-error-status-e2e.test.ts \
          --exclude test/subagents-print-mode-e2e.test.ts
        npm run typecheck
        runHook postCheck
      '';

      installPhase = ''
        runHook preInstall
        target="$out/lib/node_modules/@tintinweb/pi-subagents"
        mkdir -p "$target"
        cp -r src package.json package-lock.json README.md LICENSE "$target/"
        cp -r node_modules "$target/"
        runHook postInstall
      '';

      meta = {
        description = "Background and steerable subagents for Pi";
        homepage = "https://github.com/tintinweb/pi-subagents";
        license = lib.licenses.mit;
      };
    };
  };
}
