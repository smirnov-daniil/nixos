{ inputs, ... }:
{
  programs.nixvim.enable = true;
  imports = [
    inputs.nixvim.homeManagerModules.nixvim
    ./plugins
    ./options.nix
  ];
}
