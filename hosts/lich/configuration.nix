{
  inputs,
  self,
  ...
}: {
  flake.nixosModules.lich = {
    pkgs,
    lib,
    ...
  }: {
    imports = [self.nixosModules.wsl self.nixosModules.base self.nixosModules.general self.nixosModules.pi];
    system.stateVersion = "25.11";
    preferences.hostname = "lich";
    networking = {
      networkmanager.enable = true;
      wireless.enable = lib.mkForce false;
      wireless.iwd.enable = lib.mkForce false;
      proxy = {
        default = "http://dan.smirnov:tGPvOzbheberkG@10.1.252.242:9999";
        noProxy = "localhost,127.0.0.1,::1";
      };
    };
    environment.sessionVariables = {
      http_proxy = "http://dan.smirnov:tGPvOzbheberkG@10.1.252.242:9999";
      https_proxy = "http://dan.smirnov:tGPvOzbheberkG@10.1.252.242:9999";
      # NIX_SSL_CERT_FILE = "/etc/ssl/certs/ca-certificates.crt";
    };
    preferences.user.email = "dan.smirnov@yadro.com";
  };
}
