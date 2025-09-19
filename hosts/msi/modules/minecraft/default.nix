{pkgs, lib, inputs, ...}:
{
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 25565 ];
  };

  imports = [ inputs.nix-minecraft.nixosModules.minecraft-servers ];
  nixpkgs.overlays = [ inputs.nix-minecraft.overlay ];

  services.minecraft-servers = {
    enable = true;
    eula = true;

    openFirewall = true;

    servers = {
      minecraft-server = {
        enable = true;

        package = pkgs.vanillaServers.vanilla-1_21;

        serverProperties = {
          gamemode = "survival";
          difficulty = "hard";
          simulation-distance = 32;
        };
        
        jvmOpts = "-Xmx6G -Xms2G";
      };
    };
  };
}

