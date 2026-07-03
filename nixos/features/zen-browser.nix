{self, ...}: {
  flake.nixosModules.zen-browser = {pkgs, ...}: {
    # Same zen build as packages/zen-browser.nix (prefs, extensions,
    # policies live there) — just without the nixglhost entrypoint,
    # which is only needed on non-NixOS hosts.
    environment.systemPackages = [
      self.packages.${pkgs.stdenv.hostPlatform.system}.zen-browser-plain
    ];
  };
}
