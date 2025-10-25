{
  config,
  lib,
  ...
}: let
  service = "homepage";
  cfg = config.sanctum."${service}";
  sanctum = config.sanctum;

  collectServices = let
    servicesByCategory = let
      sanctumServices =
        lib.attrsets.filterAttrs (
          _name: value: value ? homepage
        )
        sanctum.services;
    in
      lib.lists.foldl (
        acc: serviceName: let
          serviceCfg = sanctum.services.${serviceName};
          category = serviceCfg."${service}".category or "Services";
        in
          if serviceCfg.enable && serviceName != "${service}"
          then
            acc
            // {
              ${category} =
                (acc.${category} or [])
                ++ [
                  {
                    "${serviceCfg."${service}".name or serviceCfg.description}" = {
                      icon = serviceCfg."${service}".icon or "${serviceName}.svg";
                      description = serviceCfg."${service}".description or serviceCfg.description;
                      href = "https://${serviceCfg.domain}";
                      siteMonitor = "https://${serviceCfg.domain}";
                    };
                  }
                ];
            }
          else acc
      ) {} (lib.attrNames sanctumServices);

    # Преобразуем в формат homepage
    homepageServices =
      lib.attrsets.mapAttrs (category: services: {
        ${category} = services;
      })
      servicesByCategory;
  in
    lib.attrsets.attrValues homepageServices;
in {
  options.sanctum."${service}" = {
    enable = lib.mkEnableOption {
      description = "Enable homepage dashboard";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8080;
      description = "Port for homepage";
    };

    title = lib.mkOption {
      type = lib.types.str;
      default = "Sanctum Dashboard";
      description = "Dashboard title";
    };

    misc = lib.mkOption {
      default = [];
      type = lib.types.listOf (
        lib.types.attrsOf (
          lib.types.submodule {
            options = {
              description = lib.mkOption {
                type = lib.types.str;
              };
              href = lib.mkOption {
                type = lib.types.str;
              };
              siteMonitor = lib.mkOption {
                type = lib.types.str;
              };
              icon = lib.mkOption {
                type = lib.types.str;
              };
            };
          }
        )
      );
    };
  };

  config = lib.mkIf cfg.enable {
    # Добавляем метаданные homepage в sanctum
    sanctum.services."${service}" = {
      enable = true;
      domain = "home.${sanctum.domain}";
      port = cfg.port;
      description = "Dashboard";
    };

    # Включаем glances для мониторинга системы
    services.glances.enable = true;

    services.homepage-dashboard = {
      enable = true;

      listenPort = cfg.port;

      allowedHosts = "home.${sanctum.domain}";
      # Кастомный CSS (как в оригинале)
      customCSS = ''
        body, html {
          font-family: SF Pro Display, Helvetica, Arial, sans-serif !important;
        }
        .font-medium {
          font-weight: 700 !important;
        }
        .font-light {
          font-weight: 500 !important;
        }
        .font-thin {
          font-weight: 400 !important;
        }
        #information-widgets {
          padding-left: 1.5rem;
          padding-right: 1.5rem;
        }
        div#footer {
          display: none;
        }
        .services-group.basis-full.flex-1.px-1.-my-1 {
          padding-bottom: 3rem;
        };
      '';

      settings = {
        layout = [
          {
            Glances = {
              header = false;
              style = "row";
              columns = 4;
            };
          }
          {
            Services = {
              header = true;
              style = "column";
            };
          }
          {
            Media = {
              header = true;
              style = "column";
            };
          }
          {
            Downloads = {
              header = true;
              style = "column";
            };
          }
          {
            Monitoring = {
              header = true;
              style = "column";
            };
          }
        ];
        headerStyle = "clean";
        statusStyle = "dot";
        hideVersion = "true";
      };

      services =
        collectServices
        ++ [{Misc = cfg.misc;}]
        ++ [
          {
            Glances = let
              port = toString config.services.glances.port;
            in [
              {
                Info = {
                  widget = {
                    type = "glances";
                    url = "http://localhost:${port}";
                    metric = "info";
                    chart = false;
                    version = 4;
                  };
                };
              }
              {
                "CPU Temp" = {
                  widget = {
                    type = "glances";
                    url = "http://localhost:${port}";
                    metric = "sensor:Package id 0";
                    chart = false;
                    version = 4;
                  };
                };
              }
              {
                Processes = {
                  widget = {
                    type = "glances";
                    url = "http://localhost:${port}";
                    metric = "process";
                    chart = false;
                    version = 4;
                  };
                };
              }
              {
                Network = {
                  widget = {
                    type = "glances";
                    url = "http://localhost:${port}";
                    metric = "network:enp2s0";
                    chart = false;
                    version = 4;
                  };
                };
              }
            ];
          }
        ];
    };
  };
}
