"""Explicitly install the packaged review skill without replacing personal skills."""

import os
from pathlib import Path
import sys


def install(source, destinations):
    for destination in destinations:
        if destination.is_symlink():
            old = str(destination.readlink())
            if old == str(source):
                continue
            if not old.startswith("/nix/store/") or not old.endswith("/share/agent-skills/tuicr-review"):
                raise RuntimeError(f"Personal skill exists: {destination}")
        elif destination.exists():
            raise RuntimeError(f"Personal skill exists: {destination}")
    for destination in destinations:
        destination.parent.mkdir(parents=True, exist_ok=True)
        temporary = destination.with_name(f".{destination.name}.{os.getpid()}")
        temporary.symlink_to(source)
        temporary.replace(destination)
        print(destination)


if __name__ == "__main__":
    source = Path(sys.argv[1])
    install(source, [Path.home() / ".agents/skills/tuicr-review",
                    Path(os.environ.get("CLAUDE_CONFIG_DIR", Path.home() / ".claude")) / "skills/tuicr-review"])
