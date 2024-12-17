{
  programs.git = {
    enable = true;
    userName = "Daniil Smirnov";
    userEmail = "dsmirnov.ds2+github@yandex.com";

    aliases = {
      ci = "commit";
      st = "status";
    };

    extraConfig = {
      pull = {
        rebase = true;
      };
    };
  };
}
