{self, ...}: {
  flake.nixosModules.sanctum-nginx = {
    config,
    pkgs,
    lib,
    ...
  }:
    with lib; let
      cfg = config.sanctum.nginx;
      sanctum = config.sanctum;
      ssh = cfg.sshOverTls;

      sanctumServices =
        lib.attrsets.filterAttrs (
          _name: value: value.enable && value.reverseProxy
        )
        sanctum.services;

      makeServiceVirtualHost = serviceName: serviceCfg: {
        "${serviceCfg.domain}" = {
          forceSSL = true;
          enableACME = true;
          extraConfig = optionalString (serviceCfg.allowedNetworks != []) (
            concatMapStrings (network: "allow ${network};\n") serviceCfg.allowedNetworks
            + "deny all;\n"
          );
          locations."/" = {
            proxyPass = "http://127.0.0.1:${toString serviceCfg.port}";
            proxyWebsockets = true;
          };
        };
      };

      serviceVirtualHosts = concatMapAttrs makeServiceVirtualHost sanctumServices;

      mainVirtualHost = {
        "${sanctum.domain}" = {
          forceSSL = true;
          enableACME = true;
          default = true;
          locations."/" = {
            root = pkgs.writeTextDir "index.html" ''
              <html>
                <body>
                  <h1>Server Ready!</h1>
                </body>
              </html>
            '';
          };
        };
      };

      # The SNI name only needs a certificate; HTTPS requests that somehow reach
      # the HTTP server for it (never through the public port) get 404.
      sshVirtualHost = optionalAttrs ssh.enable {
        "${ssh.domain}" = {
          forceSSL = true;
          enableACME = true;
          locations."/".return = "404";
        };
      };

      allVirtualHosts = mainVirtualHost // serviceVirtualHosts // sshVirtualHost;

      loopback = "127.0.0.1";
      loopbackUpstream = port: "${loopback}:${toString port}";
      sshCertDir = config.security.acme.certs.${ssh.domain}.directory;

      # Public HTTPS port: a stream server peeks at the TLS ClientHello and
      # dispatches by SNI. Plain SSH never sends a ClientHello, so its preread
      # protocol is empty and it can be routed to sshd as well. Backends behind
      # the dispatcher receive PROXY protocol so nginx keeps real client IPs.
      sshStreamConfig = ''
        map $ssl_preread_server_name $sanctum_sni_upstream {
          ${ssh.domain} ${loopbackUpstream ssh.internalPorts.sshTls};
          default ${loopbackUpstream ssh.internalPorts.https};
        }

        map $ssl_preread_protocol $sanctum_stream_upstream {
          "" ${loopbackUpstream (
          if ssh.plainSsh
          then ssh.internalPorts.ssh
          else ssh.internalPorts.https
        )};
          default $sanctum_sni_upstream;
        }

        server {
          listen 0.0.0.0:${toString cfg.httpsPort};
          listen [::0]:${toString cfg.httpsPort};
          ssl_preread on;
          proxy_protocol on;
          proxy_pass $sanctum_stream_upstream;
        }

        server {
          listen ${loopbackUpstream ssh.internalPorts.ssh} proxy_protocol;
          proxy_pass ${loopbackUpstream ssh.sshPort};
        }

        server {
          listen ${loopbackUpstream ssh.internalPorts.sshTls} ssl proxy_protocol;
          ssl_certificate ${sshCertDir}/fullchain.pem;
          ssl_certificate_key ${sshCertDir}/key.pem;
          ssl_protocols TLSv1.2 TLSv1.3;
          proxy_pass ${loopbackUpstream ssh.sshPort};
        }
      '';
    in {
      # Imported both by the aggregate and by independently usable service leaves.
      key = toString ./default.nix;
      imports = [self.nixosModules.sanctum-core];

      options.sanctum.nginx = {
        enable = mkEnableOption "nginx web server";

        httpPort = mkOption {
          type = types.port;
          default = 80;
          description = "HTTP порт";
        };

        httpsPort = mkOption {
          type = types.port;
          default = 443;
          description = "HTTPS порт";
        };

        acmeEmail = mkOption {
          type = types.str;
          default = "admin@example.com";
          description = "Email для Let's Encrypt";
        };

        sshOverTls = {
          enable = mkEnableOption "SSH multiplexed on the HTTPS port: TLS with SNI, optionally plain SSH";

          domain = mkOption {
            type = types.str;
            default = "remote.${sanctum.domain}";
            description = "SNI name whose TLS sessions on the HTTPS port carry SSH.";
          };

          sshPort = mkOption {
            type = types.port;
            default = 22;
            description = "Local sshd port that receives the multiplexed connections.";
          };

          plainSsh = mkOption {
            type = types.bool;
            default = true;
            description = "Also pass non-TLS connections on the HTTPS port to sshd (`ssh -p 443`).";
          };

          internalPorts = {
            https = mkOption {
              type = types.port;
              default = 8443;
              description = "Loopback port where the HTTP server listens for HTTPS behind the dispatcher.";
            };
            ssh = mkOption {
              type = types.port;
              default = 8022;
              description = "Loopback port that strips PROXY protocol for plain SSH.";
            };
            sshTls = mkOption {
              type = types.port;
              default = 8023;
              description = "Loopback port that terminates TLS for SSH.";
            };
          };
        };
      };

      config = mkIf cfg.enable (mkMerge [
        {
          networking.firewall.allowedTCPPorts = [cfg.httpPort cfg.httpsPort];

          services.nginx = {
            enable = true;
            recommendedProxySettings = true;
            recommendedTlsSettings = true;
            recommendedOptimisation = true;
            recommendedGzipSettings = true;

            virtualHosts = allVirtualHosts;
          };

          security.acme = {
            acceptTerms = true;
            defaults.email = cfg.acmeEmail;
          };
        }

        (mkIf ssh.enable {
          assertions = [
            {
              assertion = config.services.openssh.enable;
              message = "sanctum.nginx.sshOverTls needs services.openssh";
            }
            {
              assertion = length (unique (attrValues ssh.internalPorts ++ [ssh.sshPort cfg.httpPort cfg.httpsPort])) == 6;
              message = "sanctum.nginx.sshOverTls: internal, ssh, http and https ports must differ";
            }
          ];

          services.nginx = {
            # Move HTTPS off the public port; the stream dispatcher owns it.
            defaultListen = [
              {
                addr = "0.0.0.0";
                port = cfg.httpPort;
                ssl = false;
              }
              {
                addr = "[::0]";
                port = cfg.httpPort;
                ssl = false;
              }
              {
                addr = loopback;
                port = ssh.internalPorts.https;
                ssl = true;
                proxyProtocol = true;
              }
            ];
            commonHttpConfig = ''
              set_real_ip_from ${loopback};
              real_ip_header proxy_protocol;
            '';
            streamConfig = sshStreamConfig;
          };
        })
      ]);
    };
}
