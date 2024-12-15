{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    # asus tools
    supergfxctl
    asusctl
  ];
}
