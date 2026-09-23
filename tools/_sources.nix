let
  ignored = name:
    builtins.match "(\\.git|\\.jj|\\.devenv|\\.direnv|\\.skillopt-sleep|__pycache__|result(-.*)?|devenv\\.local\\.(nix|yaml)|\\.env(\\..*)?)" name != null;

  claudeState = [
    ".claude/settings.json"
    ".claude/settings.local.json"
    ".claude/commands/flake-check.md"
    ".claude/commands/flake-format.md"
  ];

  # Never follow symlinks or traverse tool state when discovering modules.
  nixFiles = root: let
    entries = builtins.readDir root;
    visit = name: let
      path = root + "/${name}";
      type = entries.${name};
    in
      if ignored name || builtins.substring 0 1 name == "."
      then []
      else if type == "directory"
      then nixFiles path
      else if type == "regular" && builtins.match ".*\\.nix" name != null
      then [path]
      else [];
  in
    builtins.concatMap visit (builtins.attrNames entries);
in {
  inherit nixFiles;

  moduleFiles = root:
    builtins.filter (path: let
      name = builtins.baseNameOf path;
    in
      name
      != "flake.nix"
      && name != "devenv.nix"
      && builtins.substring 0 1 name != "_") (nixFiles root);

  # Includes uncommitted/new files, but not mutable runtime state or local env.
  # Unlike path:., this stays stable while devenv updates its SQLite databases.
  snapshot = root:
    builtins.path {
      path = builtins.toPath root;
      name = "flake-dev-source";
      filter = path: _type:
        !ignored (builtins.baseNameOf path)
        && !builtins.elem path (map (suffix: "${toString root}/${suffix}") claudeState);
    };
}
