{inputs, ...}: {
  flake.nixosModules.wireguard = {
    config,
    lib,
    ...
  }: let
    cfg = config.features.wireguard;

    # envsubst fills every profile from one EnvironmentFile shared by the whole
    # ensure-profiles service, so each interface gets its own variable prefix.
    prefixOf = name: lib.toUpper (builtins.replaceStrings ["-" "."] ["_" "_"] name);

    mkProfile = name: iface: let
      var = suffix: "$" + prefixOf name + "_" + suffix;
    in {
      connection = {
        inherit (iface) id autoconnect;
        type = "wireguard";
        interface-name = name;
      };
      wireguard = {
        private-key = var "PRIVATE_KEY";
        mtu = var "MTU";
      };
      "wireguard-peer.${var "PEER_PUBLIC_KEY"}" = {
        endpoint = var "PEER_ENDPOINT";
        allowed-ips = var "PEER_ALLOWED_IPS";
        persistent-keepalive = var "PEER_KEEPALIVE";
      };
      ipv4 = {
        address1 = var "ADDRESS";
        dns = var "DNS";
        method = "manual";
      };
    };
  in {
    imports = [inputs.sops-nix.nixosModules.default];

    options.features.wireguard.interfaces = lib.mkOption {
      default = {};
      example = lib.literalExpression ''{wg0.envSecret = "wireguard/wg0-env";}'';
      description = ''
        WireGuard NetworkManager profiles whose values all come from sops.

        Nothing about the tunnel reaches the Nix store: the generated profile is
        a skeleton of envsubst placeholders that NetworkManager-ensure-profiles
        substitutes from the named secret at runtime.
      '';
      type = lib.types.attrsOf (lib.types.submodule ({name, ...}: {
        options = {
          envSecret = lib.mkOption {
            type = lib.types.str;
            description = ''
              Name of the sops secret holding this interface's EnvironmentFile.
              It must define PREFIX_PRIVATE_KEY, PREFIX_MTU, PREFIX_ADDRESS,
              PREFIX_DNS, PREFIX_PEER_PUBLIC_KEY, PREFIX_PEER_ENDPOINT,
              PREFIX_PEER_ALLOWED_IPS and PREFIX_PEER_KEEPALIVE, where PREFIX is
              the interface name uppercased (wg0 -> WG0). An undefined variable
              substitutes to the empty string, so a typo yields a profile
              NetworkManager rejects rather than an evaluation error.
            '';
          };
          id = lib.mkOption {
            type = lib.types.str;
            default = name;
            description = "Connection name NetworkManager shows for the profile.";
          };
          autoconnect = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Bring the tunnel up automatically instead of on demand.";
          };
        };
      }));
    };

    config = lib.mkIf (cfg.interfaces != {}) {
      # /run/secrets.d rotates on activation, and ensure-profiles only reads its
      # EnvironmentFile at start, so it has to be restarted with the secret.
      sops.secrets = lib.mapAttrs' (_: iface:
        lib.nameValuePair iface.envSecret {
          restartUnits = ["NetworkManager-ensure-profiles.service"];
        })
      cfg.interfaces;

      networking.networkmanager.ensureProfiles = {
        environmentFiles =
          lib.mapAttrsToList (_: iface: config.sops.secrets.${iface.envSecret}.path)
          cfg.interfaces;
        profiles = lib.mapAttrs mkProfile cfg.interfaces;
      };
    };
  };
}
