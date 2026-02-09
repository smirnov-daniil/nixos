{
  pkgs,
  lib,
  config,
  inputs,
  ...
}: {
  imports = [
    inputs.zen-browser.homeModules.beta
  ];

  options = {
    gui.browser.enable = lib.mkEnableOption "enables browser";
  };

  config = lib.mkIf config.gui.browser.enable {
    programs.zen-browser = {
      enable = true;
      profiles = {
        default = rec {
          extensions.packages = with inputs.firefox-addons.packages.${pkgs.stdenv.hostPlatform.system}; [
            ublock-origin
            bitwarden
          ];

          settings = {
            "zen.workspaces.continue-where-left-off" = true;
            "zen.workspaces.natural-scroll" = true;
            "zen.view.compact.hide-tabbar" = true;
            "zen.view.compact.hide-toolbar" = true;
            "zen.view.compact.animate-sidebar" = false;
            "zen.welcome-screen.seen" = true;
            "zen.urlbar.behavior" = "float";
            "zen.tabs.vertical.right-side" = true;
          };

          pinsForce = true;
          pins = {
            "GitHub" = {
              id = "7fb14076-a147-4d09-8487-bdd830332b61";
              workspace = spaces."DefaultSpace".id;
              url = "https://github.com";
              position = 100;
              isEssential = true;
            };
            "Deepseek" = {
              id = "4ecfbb32-81eb-4a5f-ab1a-68b3ebf1f5fa";
              workspace = spaces."DefaultSpace".id;
              url = "https://chat.deepseek.com/";
              position = 101;
              isEssential = true;
            };
          };

          spacesForce = true;
          spaces = {
            "DefaultSpace" = {
              id = "1d674ff6-8b4f-4cfb-9635-c7d569280a0b";
              icon = "";
              position = 1000;
            };
          };

          search = {
            force = true;
            default = "google";
            engines = let
              nixSnowflakeIcon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
            in {
              "Nix Packages" = {
                urls = [
                  {
                    template = "https://search.nixos.org/packages";
                    params = [
                      {
                        name = "type";
                        value = "packages";
                      }
                      {
                        name = "channel";
                        value = "unstable";
                      }
                      {
                        name = "query";
                        value = "{searchTerms}";
                      }
                    ];
                  }
                ];
                icon = nixSnowflakeIcon;
                definedAliases = ["np"];
              };
              "Nix Options" = {
                urls = [
                  {
                    template = "https://search.nixos.org/options";
                    params = [
                      {
                        name = "channel";
                        value = "unstable";
                      }
                      {
                        name = "query";
                        value = "{searchTerms}";
                      }
                    ];
                  }
                ];
                icon = nixSnowflakeIcon;
                definedAliases = ["nop"];
              };
              "Home Manager Options" = {
                urls = [
                  {
                    template = "https://home-manager-options.extranix.com/";
                    params = [
                      {
                        name = "query";
                        value = "{searchTerms}";
                      }
                      {
                        name = "release";
                        value = "master"; # unstable
                      }
                    ];
                  }
                ];
                icon = nixSnowflakeIcon;
                definedAliases = ["hmop"];
              };
              bing.metaData.hidden = "true";
            };
          };
        };
      };

      nativeMessagingHosts = [pkgs.firefoxpwa];

      policies = {
        Proxy = {
          Mode = "manual";
          Locked = false;
          HTTPProxy = "localhost:1080";
          UseHTTPProxyForAllProtocols = true;
          SOCKSVersion = 5;
          Passthrough = "reddit.com, *.yandex.ru";
          AutoLogin = true;
          UseProxyForDNS = true;
        };
        AutofillAddressEnabled = true;
        AutofillCreditCardEnabled = false;
        DisableAppUpdate = true;
        DisableFeedbackCommands = true;
        DisableFirefoxStudies = true;
        DisablePocket = true;
        DisableTelemetry = true;
        DontCheckDefaultBrowser = true;
        NoDefaultBookmarks = true;
        OfferToSaveLogins = false;
        EnableTrackingProtection = {
          Value = true;
          Locked = true;
          Cryptomining = true;
          Fingerprinting = true;
        };
      };
    };
    stylix.targets.zen-browser.profileNames = ["default"];
  };
}
