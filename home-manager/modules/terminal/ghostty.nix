{
  programs.ghostty = {
    enable = true;
    settings = {
      background-blur-radius = 15;
      background-opacity = 0.75;
      unfocused-split-opacity = 0.8;
      gtk-titlebar = false;
      mouse-hide-while-typing = true;
      window-decoration = true;
      keybind = [
        "performable:ctrl+c=copy_to_clipboard"
        "performable:ctrl+v=paste_from_clipboard"

        "ctrl+equal=increase_font_size:1"
        "ctrl+minus=decrease_font_size:1"

        "alt+h=goto_split:left"
        "alt+j=goto_split:down"
        "alt+k=goto_split:top"
        "alt+l=goto_split:right"

        "alt+1=goto_tab:1"
        "alt+2=goto_tab:2"
        "alt+3=goto_tab:3"
        "alt+4=goto_tab:4"
        "alt+5=goto_tab:5"
        "alt+6=goto_tab:6"
        "alt+7=goto_tab:7"
        "alt+8=goto_tab:8"
        "alt+9=goto_tab:9"
        "alt+0=goto_tab:10"

        "alt+enter=new_tab"
        "ctrl+n=next_tab"
        "ctrl+p=previous_tab"

        "alt+v=new_split:right"
        "alt+s=new_split:down"

        "alt+c=close_surface"
        "alt+q=close_tab"
      ];
    };

    clearDefaultKeybinds = true;
  };
}
