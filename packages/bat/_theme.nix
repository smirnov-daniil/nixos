{
  lib,
  theme,
}:
lib.generators.toPlist {escape = true;} {
  name = "flake";
  settings = [
    {
      settings = {
        foreground = theme.base05;
        background = theme.base00;
        caret = theme.base05;
        selection = theme.base02;
        lineHighlight = theme.base01;
        gutterForeground = theme.base04;
        gutter = theme.base00;
      };
    }
    {
      scope = "comment, punctuation.definition.comment";
      settings.foreground = theme.base03;
    }
    {
      scope = "string";
      settings.foreground = theme.base0B;
    }
    {
      scope = "constant.numeric, constant.language, constant.character, constant.other";
      settings.foreground = theme.base09;
    }
    {
      scope = "keyword, storage";
      settings.foreground = theme.base0E;
    }
    {
      scope = "entity.name.function, support.function";
      settings.foreground = theme.base0D;
    }
    {
      scope = "entity.name.type, entity.name.class, support.type, support.class";
      settings.foreground = theme.base0A;
    }
    {
      scope = "invalid, message.error, markup.error";
      settings.foreground = theme.base08;
    }
    {
      scope = "markup.warning";
      settings.foreground = theme.base0A;
    }
    {
      scope = "markup.info";
      settings.foreground = theme.base0B;
    }
    {
      scope = "markup.heading";
      settings = {
        foreground = theme.base0D;
        fontStyle = "bold";
      };
    }
    {
      scope = "entity.name.command-line-option, entity.name.command, support.constant.environment-variable";
      settings.foreground = theme.base0C;
    }
    {
      scope = "markup.inserted";
      settings.foreground = theme.base0B;
    }
    {
      scope = "markup.deleted";
      settings.foreground = theme.base08;
    }
    {
      scope = "markup.changed";
      settings.foreground = theme.base0A;
    }
    {
      scope = "meta.diff.header, meta.diff.range";
      settings.foreground = theme.base0C;
    }
  ];
}
