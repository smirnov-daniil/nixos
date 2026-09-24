"""Select a numbered tmux space or an agent in the calling space."""

import json
import subprocess
import sys


def output(argv):
    return subprocess.check_output(argv, text=True).strip()


def main():
    kind, selection, pane = sys.argv[1:]
    if kind == "space":
        # Creation order keeps Alt+Shift+number stable when names change.
        rows = output(["tmux", "list-sessions", "-F", "#{session_created}\t#{session_id}"]).splitlines()
        targets = [line.split("\t")[1] for line in sorted(rows, key=lambda s: (int(s.split("\t")[0]), int(s.split("$")[-1])))]
    else:
        space = output(["tmux", "display-message", "-p", "-t", pane, "#{session_name}"])
        sessions = json.loads(output(["ccmux", "show", "--json"]))
        live = output(["tmux", "list-panes", "-s", "-t", space, "-F", "#{pane_id}"]).splitlines()
        targets = list(dict.fromkeys(s["tmuxPane"] for s in sessions if s.get("tmuxPane") in live))
        targets.sort(key=lambda value: int(value[1:]))
    if not targets:
        return
    if selection in ("next", "previous"):
        position = targets.index(pane) if pane in targets else (-1 if selection == "next" else 0)
        index = (position + (1 if selection == "next" else -1)) % len(targets)
    else:
        index = int(selection) - 1
        if index >= len(targets):
            return
    if kind == "space":
        subprocess.run(["tmux", "switch-client", "-t", targets[index]], check=True)
    else:
        subprocess.run(["tmux", "select-window", "-t", targets[index]], check=True)
        subprocess.run(["tmux", "select-pane", "-t", targets[index]], check=True)


if __name__ == "__main__":
    main()
