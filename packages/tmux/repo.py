"""Choose a repository inside an umbrella checkout, then open its review/VCS UI."""

import argparse
import os
from pathlib import Path
import subprocess

import yaml


def project_root(path: Path) -> Path:
    path = path.resolve()
    if path.is_file():
        path = path.parent
    parents = [path, *path.parents]
    # A nested repository still belongs to the same terminal project.
    for parent in parents:
        if (parent / ".ff/repo.yml").is_file():
            return parent
    for parent in parents:
        if (parent / ".jj").is_dir() or (parent / ".git").exists():
            return parent
    return path


def repositories(root: Path) -> list[tuple[str, Path]]:
    result = [(". (root)", root)]
    manifest = root / ".ff/repo.yml"
    if not manifest.is_file():
        return result
    graph = yaml.safe_load(manifest.read_text()) or {}
    seen = {root.resolve()}
    for node in graph.get("nodes", {}).values():
        relative = node.get("path")
        if not isinstance(relative, str):
            continue
        path = (root / relative).resolve()
        if path in seen or not path.is_relative_to(root.resolve()):
            continue
        if not ((path / ".jj").is_dir() or (path / ".git").exists()):
            continue
        seen.add(path)
        result.append((str(path.relative_to(root)), path))
    return [result[0], *sorted(result[1:])]


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("tool", choices=["tuicr", "jjui"])
    parser.add_argument("path", nargs="?", type=Path, default=Path.cwd())
    args = parser.parse_args()
    candidates = repositories(project_root(args.path))
    if len(candidates) == 1:
        selected = candidates[0][1]
    else:
        choices = dict(candidates)
        picked = subprocess.run(
            ["fzf", "--read0", "--print0", "--no-multi", "--prompt", f"{args.tool} repo> "],
            input="\0".join(choices).encode() + b"\0",
            stdout=subprocess.PIPE,
            check=False,
        )
        if picked.returncode in (1, 130):
            return
        picked.check_returncode()
        selected = choices[picked.stdout.decode().rstrip("\0")]
    os.chdir(selected)
    if args.tool == "tuicr":
        os.execvp("mux-exec", ["mux-exec", "reviewctl", "open", "--repo", str(selected), "--handoff"])
    os.execvp("mux-exec", ["mux-exec", args.tool])


if __name__ == "__main__":
    main()
