"""Install upstream Claude/Codex hooks, then give their scripts Nix runtimes."""

from datetime import datetime, timezone
import json
import os
from pathlib import Path
import shlex
import shutil
import subprocess
import sys


def main() -> None:
    ccmux, bash, path = sys.argv[1:]
    home = Path.home()
    claude_dirs = {home / ".claude"}
    if os.environ.get("CLAUDE_CONFIG_DIR"):
        claude_dirs.add(Path(os.environ["CLAUDE_CONFIG_DIR"]).expanduser())
    prefs_file = Path(os.environ.get("CCMUX_HOME", home / ".config/ccmux")) / "ccmux.json"
    if prefs_file.is_file():
        extra = json.loads(prefs_file.read_text()).get("additionalClaudeConfigDirs", [])
        if isinstance(extra, list):
            claude_dirs.update(Path(item).expanduser() for item in extra if isinstance(item, str) and item)
    codex_dir = Path(os.environ.get("CODEX_HOME", home / ".codex")).expanduser()
    settings = [directory / "settings.json" for directory in claude_dirs]
    settings += [codex_dir / "hooks.json", codex_dir / "config.toml"]
    # Upstream writes these files. Managed symlinks must be updated at their source.
    for file in settings:
        if file.is_symlink():
            sys.exit(f"Refusing to overwrite managed settings: {file}")
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ")
    for file in settings:
        if file.is_file():
            backup = file.with_name(f"{file.name}.before-ccmux-{stamp}")
            shutil.copy2(file, backup)
            backup.chmod(0o600)
    result = subprocess.run([ccmux, "setup", "--agent", "claude", "--agent", "codex"], check=False)
    # Also fix scripts installed by a successful adapter if the other one failed.
    hooks = {
        directory / "hooks" / f"ccmux-{event}.sh"
        for directory in claude_dirs
        for event in ["session-start", "session-end", "state-notify"]
    }
    hooks.update(codex_dir / "hooks" / f"ccmux-{event}.sh"
                 for event in ["session-start", "stop", "permission-request"])
    for hook in sorted(hooks):
        if not hook.is_file() or hook.is_symlink():
            continue
        script = hook.read_text()
        if script.startswith("#!/bin/bash\n"):
            hook.write_text(f"#!{bash}\nexport PATH={shlex.quote(path)}:\"$PATH\"\n" + script.split("\n", 1)[1])
            print(f"Nix runtime: {hook}")
    sys.exit(result.returncode)


if __name__ == "__main__":
    main()
