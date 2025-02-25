{pkgs, ...}: {
  stylix = {
    enable = true;
    polarity = "dark";
    autoEnable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/porple.yaml";
  };
}
