{
  lib,
  config,
  ...
}: {
  config = lib.mkIf config.desktop.hyprland.enable {
    wayland.windowManager.hyprland.settings = {
      windowrulev2 = [
        "bordersize 0, floating:0, onworkspace:w[t1]"

        "float,class:(mpv)|(imv)|(showmethekey-gtk)"
        "move 990 60,size 900 170,pin,noinitialfocus,class:(showmethekey-gtk)"
        "noborder,nofocus,class:(showmethekey-gtk)"

        "workspace 1,title:(zen)"
        "workspace 2,title:^(.*tty.*)$"
        "workspace 3,title:^(.*[T|t]elegram.*)$"
        "workspace 4,class:(code)"
        "workspace 5,title:(com.obsproject.Studio)"

        "suppressevent maximize, class:.*"
        "nofocus,class:^$,title:^$,xwayland:1,floating:1,fullscreen:0,pinned:0"
      ];
    };
  };
}
