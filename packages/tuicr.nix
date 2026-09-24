{inputs, ...}: {
  perSystem = {pkgs, ...}: {
    packages.tuicr = pkgs.rustPlatform.buildRustPackage {
      pname = "tuicr";
      version = "0.27.0";
      src = inputs.tuicr;
      cargoLock.lockFile = "${inputs.tuicr}/Cargo.lock";
      doCheck = false;
      meta.mainProgram = "tuicr";
    };
  };
}
