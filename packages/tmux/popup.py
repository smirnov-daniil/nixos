import argparse
import os
import shlex
import shutil
import subprocess
import uuid


def main() -> None:
    parser = argparse.ArgumentParser()
    commands = parser.add_subparsers(dest="command", required=True)
    opening = commands.add_parser("open")
    opening.add_argument("tool", choices=["tuicr", "jjui"])
    opening.add_argument("pane")
    opening.add_argument("client")
    promotion = commands.add_parser("promote")
    promotion.add_argument("pane")
    args = parser.parse_args()
    socket = os.environ["TMUX"].rsplit(",", 2)[0]
    command = [shutil.which("tmux") or "tmux", "-S", socket]

    def tmux(*arguments: str) -> str:
        return subprocess.check_output([*command, *arguments], text=True).rstrip("\n")

    session = tmux("display-message", "-p", "-t", args.pane, "#{session_id}")
    if args.command == "promote":
        parent = tmux("show-options", "-qv", "-t", session, "@mux-popup-parent")
        if not parent:
            tmux("break-pane", "-s", args.pane)
            return
        client = tmux("show-options", "-qv", "-t", session, "@mux-popup-client")
        window = tmux("break-pane", "-d", "-s", args.pane, "-t", parent + ":",
                      "-P", "-F", "#{window_id}")
        tmux("select-window", "-t", window)
        tmux("switch-client", "-c", client, "-t", parent)
        tmux("display-popup", "-C", "-c", client)
        return

    cwd = tmux("display-message", "-p", "-t", args.pane, "#{pane_current_path}")
    temporary = "mux-popup-" + uuid.uuid4().hex
    try:
        temporary = tmux("new-session", "-d", "-s", temporary, "-c", cwd,
                         "-e", "PATH=" + os.environ["PATH"], "-P", "-F", "#{session_id}",
                         shlex.join(["mux-repo", args.tool]))
        tmux("set-option", "-t", temporary, "@mux-popup-parent", session,
             ";", "set-option", "-t", temporary, "@mux-popup-client", args.client,
             ";", "set-option", "-t", temporary, "status", "off",
             ";", "set-option", "-t", temporary, "detach-on-destroy", "on")
        nested = "unset TMUX; exec " + shlex.join([*command, "attach-session", "-t", temporary])
        displayed = subprocess.run(
            [*command, "display-popup", "-E", "-w", "95%", "-h", "95%", "-d", cwd,
             "-c", args.client, "-T", args.tool + " | Ctrl+Space !: move to tab", nested],
            check=False,
        )
        if displayed.returncode not in (0, 129, 130):
            displayed.check_returncode()
    finally:
        subprocess.run([*command, "kill-session", "-t", temporary],
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=False)


if __name__ == "__main__":
    main()
