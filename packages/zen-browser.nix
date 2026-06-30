{
  inputs,
  ...
}: {
  perSystem = {pkgs, ...}: let
    inherit (pkgs) lib;
    nixglhost = inputs.nix-gl-host.packages.${pkgs.system}.default;

    extension = shortId: guid: {
      name = guid;
      value = {
        install_url = "https://addons.mozilla.org/en-US/firefox/downloads/latest/${shortId}/latest.xpi";
        installation_mode = "normal_installed";
      };
    };

    prefs = {
      "extensions.autoDisableScopes" = 0;
      "extensions.pocket.enabled" = false;
      "zen.workspaces.continue-where-left-off" = true;
      "zen.workspaces.natural-scroll" = true;
      "zen.view.compact.hide-tabbar" = true;
      "zen.view.compact.hide-toolbar" = true;
      "zen.view.compact.animate-sidebar" = false;
      "zen.welcome-screen.seen" = true;
      "zen.urlbar.behavior" = "float";
      "zen.tabs.vertical.right-side" = true;
    };

    extensions = [
      (extension "ublock-origin" "uBlock0@raymondhill.net")
      (extension "bitwarden-password-manager" "446900e4-71c2-419f-a6a7-df9c091e268b")
    ];

    zen =
      pkgs.wrapFirefox
      inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.zen-browser-unwrapped
      {
        extraPrefs = lib.concatLines (
          lib.mapAttrsToList (
            name: value: ''lockPref(${lib.strings.toJSON name}, ${lib.strings.toJSON value});''
          )
          prefs
        );

        extraPolicies = {
          ExtensionSettings = builtins.listToAttrs extensions;
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

          SearchEngines = {
            Default = "ddg";
            Add = [
              {
                Name = "nixpkgs packages";
                URLTemplate = "https://search.nixos.org/packages?query={searchTerms}";
                IconURL = "https://wiki.nixos.org/favicon.ico";
                Alias = "@np";
              }
              {
                Name = "NixOS options";
                URLTemplate = "https://search.nixos.org/options?query={searchTerms}";
                IconURL = "https://wiki.nixos.org/favicon.ico";
                Alias = "@no";
              }
              {
                Name = "NixOS Wiki";
                URLTemplate = "https://wiki.nixos.org/w/index.php?search={searchTerms}";
                IconURL = "https://wiki.nixos.org/favicon.ico";
                Alias = "@nw";
              }
              {
                Name = "noogle";
                URLTemplate = "https://noogle.dev/q?term={searchTerms}";
                IconURL = "https://noogle.dev/favicon.ico";
                Alias = "@ng";
              }
            ];
          };
        };
      };
  in {
    # Launch zen through nixglhost so it uses the host NVIDIA OpenGL drivers
    # (GPU WebRender / WebGL / HW video decode) on non-NixOS. The desktop file
    # uses a bare `zen` Exec resolved via PATH, so menu launches hit this
    # wrapper too — no Exec rewrite needed (unlike ghostty).
    packages.zen-browser = pkgs.symlinkJoin {
      name = "zen-browser-nixglhost";
      paths = [zen];
      nativeBuildInputs = [pkgs.makeWrapper];
      postBuild = ''
        rm $out/bin/zen
        makeWrapper ${nixglhost}/bin/nixglhost $out/bin/zen \
          --add-flags "-- ${zen}/bin/zen"
      '';
      meta = (zen.meta or {}) // {mainProgram = "zen";};
    };
  };
}
