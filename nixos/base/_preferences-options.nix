{lib, ...}: {
  options.preferences = {
    autostart = lib.mkOption {
      type = lib.types.listOf (lib.types.either lib.types.str lib.types.package);
      default = [];
    };
    niri.renderDrmDevice = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
    };
    hostname = lib.mkOption {
      type = lib.types.str;
      default = "nixos";
    };
    user = {
      name = lib.mkOption {
        type = lib.types.str;
        default = "ds2";
      };
      fullname = lib.mkOption {
        type = lib.types.str;
        default = "Daniil Smirnov";
      };
      email = lib.mkOption {
        type = lib.types.str;
        default = "dsmirnov.ds2+github@yandex.com";
      };
    };
  };
}
