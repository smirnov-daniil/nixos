{
  users.groups.media = {};

  fileSystems."/srv/media" = {
    device = "/dev/disk/by-label/data";
    fsType = "btrfs";
    options = [ "subvol=media" "compress=zstd" "noatime" ];
  };

  fileSystems."/srv/backups" = {
    device = "/dev/disk/by-label/data";
    fsType = "btrfs";
    options = [ "subvol=backups" "compress=zstd" "noatime" ];
  };

  fileSystems."/srv/radarr" = {
    device = "/dev/disk/by-label/data";
    fsType = "btrfs";
    options = [ "subvol=radarr" "compress=zstd" "noatime" ];
  };

  fileSystems."/srv/jellyfin" = {
    device = "/dev/disk/by-label/data";
    fsType = "btrfs";
    options = [ "subvol=jellyfin" "compress=zstd" "noatime" ];
  };

  fileSystems."/srv/sonarr" = {
    device = "/dev/disk/by-label/data";
    fsType = "btrfs";
    options = [ "subvol=sonarr" "compress=zstd" "noatime" ];
  };

  fileSystems."/srv/prowlarr" = {
    device = "/dev/disk/by-label/data";
    fsType = "btrfs";
    options = [ "subvol=prowlarr" "compress=zstd" "noatime" ];
  };

  fileSystems."/srv/qbittorrent" = {
    device = "/dev/disk/by-label/data";
    fsType = "btrfs";
    options = [ "subvol=qbittorrent" "compress=zstd" "noatime" ];
  };
  
  fileSystems."/srv/bazarr" = {
    device = "/dev/disk/by-label/data";
    fsType = "btrfs";
    options = [ "subvol=bazarr" "compress=zstd" "noatime" ];
  };

  systemd.tmpfiles.rules = [
    "d /srv/media     2775 root media -"
    "d /srv/backups   0750 root root  -"
  ];
}
