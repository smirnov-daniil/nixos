{self, ...}: {
  flake.nixosModules.sanctum = {
    imports = [
      self.nixosModules.sanctum-core
      self.nixosModules.sanctum-bazarr
      self.nixosModules.sanctum-croc
      self.nixosModules.sanctum-homepage
      self.nixosModules.sanctum-jellyfin
      self.nixosModules.sanctum-jellyseerr
      self.nixosModules.sanctum-lidarr
      self.nixosModules.sanctum-microbin
      self.nixosModules.sanctum-nginx
      self.nixosModules.sanctum-prowlarr
      self.nixosModules.sanctum-qbittorrent
      self.nixosModules.sanctum-radarr
      self.nixosModules.sanctum-sonarr
      self.nixosModules.sanctum-skinem
      self.nixosModules.sanctum-vaultwarden
    ];
  };
}
