{
  flake.nixosModules.base = {lib, ...}: {
    options.preferences = {
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
  };
}
