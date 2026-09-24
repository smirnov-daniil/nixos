"""Create or attach a terminal space for a project, without changing its VCS."""

import argparse
import hashlib
import os
from pathlib import Path
import re
import subprocess

from repo import project_root


def session_name(root: Path) -> str:
    label = re.sub(r"[^\w-]", "-", root.name) or "project"
    suffix = hashlib.sha256(os.fsencode(root)).hexdigest()[:6]
    return f"{label}-{suffix}"


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("path", nargs="?", type=Path, default=Path.cwd())
    args = parser.parse_args()
    if not args.path.is_dir():
        parser.error(f"not a directory: {args.path}")
    root = project_root(args.path)
    name = session_name(root)
    target = "=" + name
    exists = subprocess.run(
        ["tmux", "has-session", "-t", target],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=False,
    ).returncode == 0
    if not exists:
        subprocess.run(
            ["tmux", "new-session", "-d", "-s", name, "-c", str(root), "-n", "code", "kak", "-s", name],
            check=True,
        )
        for window in ["agents", "build"]:
            subprocess.run(
                ["tmux", "new-window", "-d", "-t", target, "-c", str(root), "-n", window],
                check=True,
            )
    action = "switch-client" if os.environ.get("TMUX") else "attach-session"
    os.execvp("tmux", ["tmux", action, "-t", target])


if __name__ == "__main__":
    main()
