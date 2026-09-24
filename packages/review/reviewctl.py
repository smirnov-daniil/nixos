"""Persist a tuicr review, its diff, and its handoff to a specific agent."""

import argparse
from contextlib import contextmanager
from datetime import datetime, timezone
import fcntl
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import time
import urllib.request
import urllib.parse

from repo import project_root, repositories


class ReviewError(Exception):
    pass


def run(argv, cwd=None, *, env=None, input=None):
    result = subprocess.run(argv, cwd=cwd, env=env, input=input, capture_output=True)
    if result.returncode:
        raise ReviewError(result.stderr.decode(errors="replace").strip() or f"{argv[0]} exited {result.returncode}")
    return result.stdout


def state_dir():
    path = Path(os.environ.get("REVIEWCTL_HOME", Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state")) / "tuicr-agent-review"))
    path.mkdir(parents=True, exist_ok=True, mode=0o700)
    return path.resolve()


def ticket_dir(ticket):
    if not re.fullmatch(r"[0-9a-f]{20}", ticket):
        raise ReviewError("Invalid review ID")
    return state_dir() / ticket


def save(path, data):
    tmp = path.with_name(f".{path.name}.{os.getpid()}.tmp")
    tmp.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n")
    tmp.replace(path)


@contextmanager
def locked(path, *, nonblocking=False):
    with path.open("a") as file:
        try:
            fcntl.flock(file, fcntl.LOCK_EX | (fcntl.LOCK_NB if nonblocking else 0))
        except BlockingIOError:
            raise ReviewError("This review is already open") from None
        yield


def load(ticket):
    return json.loads((ticket_dir(ticket) / "review.json").read_text())


def repo_root(path):
    path = Path(path).resolve()
    # Stop at a submodule boundary, even when its parent is a jj checkout.
    for parent in [path, *path.parents]:
        if (parent / ".jj").is_dir():
            return parent, "jj"
        if (parent / ".git").exists():
            return parent, "git"
    raise ReviewError(f"Not a repository: {path}")


def choose(rows, prompt, multi=False):
    if not rows:
        return []
    options = ["fzf", "--read0", "--print0", "--delimiter=\t", "--with-nth=2..", "--prompt", prompt]
    options += ["--multi", "--header", "Tab: select; Enter: accept; Esc: cancel"] if multi else ["--no-multi"]
    result = subprocess.run(options, input=b"".join(f"{key}\t{label}\0".encode() for key, label in rows), stdout=subprocess.PIPE)
    if result.returncode in (1, 130):
        return []
    result.check_returncode()
    return [item.split("\t", 1)[0] for item in result.stdout.decode().rstrip("\0").split("\0")]


def pick_repo(path):
    candidates = repositories(project_root(Path(path)))
    if len(candidates) == 1:
        return candidates[0][1]
    selected = choose([(str(i), label) for i, (label, _) in enumerate(candidates)], "Review repo> ")
    return candidates[int(selected[0])][1] if selected else None


def scope(root, vcs, mode, revset=None):
    if vcs == "jj":
        revset = revset or ("trunk()..@" if mode == "branch" else None)
        return {"vcs": vcs, "mode": mode, "revset": revset,
                "args": ["-r", revset, "-w"] if revset else ["-w"]}
    if revset:
        raise ReviewError("--revset is for jj; Git branch reviews resolve their merge base")
    base = None
    if mode == "branch":
        refs = ["origin/HEAD", "origin/main", "origin/master", "main", "master"]
        branch = run(["git", "branch", "--show-current"], root).decode().strip()
        stored = subprocess.run(["git", "config", "--get", f"branch.{branch}.ccmux-base"], cwd=root, capture_output=True)
        if stored.returncode == 0:
            refs.insert(0, stored.stdout.decode().strip())
        for ref in refs:
            result = subprocess.run(["git", "merge-base", ref, "HEAD"], cwd=root, capture_output=True)
            if result.returncode == 0:
                base = result.stdout.decode().strip()
                break
        if not base:
            raise ReviewError("Cannot resolve branch base; use a working-tree review")
    return {"vcs": vcs, "mode": mode, "base": base,
            "args": ["-r", f"{base}..HEAD", "-w"] if base else ["-w"]}


def snapshot(root, selection):
    if selection["vcs"] == "jj":
        head = run(["jj", "log", "--no-graph", "-r", "@", "-T", "commit_id"], root)
        cmd = ["jj", "diff", "--git", "--color=never"]
        if selection.get("revset"):
            commits = selected_commits(root, selection)
            if not commits:
                raise ReviewError("No commits in the selected revset")
            # Match tuicr -r REVSET -w: parent of the oldest selected commit
            # through @, including the working change even if REVSET omits it.
            cmd += ["--from", commits[-1] + "-", "--to", "@"]
        diff = run(cmd, root)
    else:
        result = subprocess.run(["git", "rev-parse", "--verify", "HEAD"], cwd=root, capture_output=True)
        head = result.stdout.strip() if result.returncode == 0 else b"unborn"
        base = selection.get("base") or (head.decode() if head != b"unborn" else run(["git", "hash-object", "-t", "tree", "--stdin"], root, input=b"").decode().strip())
        diff = run(["git", "-c", "core.quotePath=true", "diff", "--no-ext-diff", "--no-textconv", "--binary", base, "--"], root)
        for raw_path in run(["git", "ls-files", "--others", "--exclude-standard", "-z"], root).split(b"\0"):
            if not raw_path:
                continue
            path = os.fsdecode(raw_path)
            extra = subprocess.run(["git", "diff", "--no-index", "--no-ext-diff", "--binary", "--", "/dev/null", path], cwd=root, capture_output=True)
            if extra.returncode not in (0, 1):
                raise ReviewError(extra.stderr.decode(errors="replace"))
            diff += extra.stdout
    fingerprint = hashlib.sha256(head + b"\0" + diff).hexdigest()
    return fingerprint, diff


def selected_commits(root, selection):
    if selection["vcs"] == "jj" and selection.get("revset"):
        return run(["jj", "log", "--no-graph", "--color=never", "-r", selection["revset"],
                    "-T", 'commit_id ++ "\\n"'], root).decode().splitlines()
    if selection.get("base"):
        return run(["git", "rev-list", f"{selection['base']}..HEAD"], root).decode().splitlines()
    return []


def prepare(path, mode="working", revset=None, agent=None):
    root, vcs = repo_root(path)
    selection = scope(root, vcs, mode, revset)
    fingerprint, diff = snapshot(root, selection)
    commits = selected_commits(root, selection)
    if not diff.strip():
        raise ReviewError("No changes to review")
    identity = json.dumps([str(root), selection, fingerprint, commits], sort_keys=True).encode()
    ticket = hashlib.sha256(identity).hexdigest()[:20]
    directory = ticket_dir(ticket)
    directory.mkdir(mode=0o700, exist_ok=True)
    with locked(directory / "metadata.lock"):
        if not (directory / "review.json").exists():
            data = {"id": ticket, "repo": str(root), "project": str(project_root(root)),
                    "selection": selection, "fingerprint": fingerprint,
                    "commits": commits,
                    "created": datetime.now(timezone.utc).isoformat(), "agent": agent}
            save(directory / "review.json", data)
            (directory / "diff.patch").write_bytes(diff)
    return ticket


def review_env(ticket):
    # One data directory per repo + diff. Unrelated native tuicr reviews never
    # enter the handoff; config, theme and editor still use the user's config.
    return {**os.environ, "XDG_DATA_HOME": str(ticket_dir(ticket) / "data")}


def sessions(ticket):
    data = load(ticket)
    return json.loads(run(["tuicr", "review", "list", "--repo", data["repo"]], env=review_env(ticket)))


def session_path(ticket):
    entries = sessions(ticket)
    if len(entries) != 1:
        raise ReviewError("Open this review in tuicr first; keep its selected diff unchanged (expected one session)")
    path = Path(entries[0]["path"]).resolve()
    if not path.is_relative_to(ticket_dir(ticket) / "data"):
        raise ReviewError("tuicr returned a session outside this review")
    persisted = json.loads(path.read_text())
    data = load(ticket)
    if Path(persisted["repo_path"]).resolve() != Path(data["repo"]):
        raise ReviewError("tuicr session belongs to another repository")
    wants_commits = "-r" in data["selection"]["args"]
    source = persisted.get("diff_source", "working_tree")
    allowed = {"working_tree_and_commits", "staged_unstaged_and_commits"} if wants_commits else {"working_tree", "staged_and_unstaged"}
    if source not in allowed:
        raise ReviewError("The diff selection changed inside tuicr; reopen with the intended reviewctl scope")
    if sorted(persisted.get("commit_range") or []) != sorted(data["commits"]):
        raise ReviewError("The commit selection changed inside tuicr; reopen with the intended reviewctl scope")
    return path


def assert_current(ticket):
    data = load(ticket)
    if (snapshot(Path(data["repo"]), data["selection"])[0] != data["fingerprint"]
            or selected_commits(Path(data["repo"]), data["selection"]) != data["commits"]):
        raise ReviewError(f"Review {ticket} is stale: the diff changed; open a new review")


def comments(ticket):
    path = session_path(ticket)
    return json.loads(run(["tuicr", "review", "comments", "--session", str(path)], env=review_env(ticket)))


def comment_key(comment):
    return hashlib.sha256(json.dumps(comment, sort_keys=True).encode()).hexdigest()


def pending(ticket, agent=None, include_ai=False, ids=None):
    ledger_path = ticket_dir(ticket) / "deliveries.json"
    ledger = json.loads(ledger_path.read_text()) if ledger_path.exists() else {}
    delivered = ledger.get(agent or "", [])
    selected = []
    for comment in comments(ticket):
        if not comment.get("content", "").strip() or comment.get("lifecycle_state") != "local_draft":
            continue
        if ids is not None and comment["id"] not in ids:
            continue
        if ids is None and not include_ai and comment.get("author", "").endswith(" AI Reviewer"):
            continue
        if comment_key(comment) not in delivered:
            selected.append(comment)
    if ids and set(ids) - {c["id"] for c in selected}:
        raise ReviewError("A selected comment changed, was removed, or was already delivered")
    return selected


def context(ticket):
    data = load(ticket)
    return {**data, "diff_file": str(ticket_dir(ticket) / "diff.patch"),
            "sessions": sessions(ticket)}


def result(ticket, agent=None):
    assert_current(ticket)
    notes = pending(ticket, agent) if sessions(ticket) else []
    return {"ticket": ticket, "notes": [{**c, "ticket": ticket, "key": comment_key(c)} for c in notes]}


def acknowledge(ticket, agent, keys):
    """Record an external composer fill (Pi), after it succeeds."""
    with locked(state_dir() / "send.lock"):
        known = {comment_key(c) for c in comments(ticket)}
        if set(keys) - known:
            raise ReviewError("Comments changed since export; delivery was not recorded")
        path = ticket_dir(ticket) / "deliveries.json"
        ledger = json.loads(path.read_text()) if path.exists() else {}
        ledger[agent] = sorted(set(ledger.get(agent, [])) | set(keys))
        save(path, ledger)


def view(ticket):
    directory = ticket_dir(ticket)
    assert_current(ticket)
    with locked(directory / "view.lock", nonblocking=True):
        data = load(ticket)
        # --stdout keeps :wq from asking about clipboard export. tuicr renders
        # and edits through /dev/tty; structured comments come from its CLI.
        code = subprocess.run(["tuicr", "--no-update-check", "--stdout", *data["selection"]["args"]],
                              cwd=data["repo"], env=review_env(ticket), stdout=subprocess.DEVNULL).returncode
        save(directory / "last-exit.json", {"code": code})
        if code:
            raise ReviewError(f"tuicr exited {code}")


def open_review(args):
    path = pick_repo(args.repo) if args.pick_repo and not args.ticket else args.repo
    if path is None:
        return {"notes": []}
    ticket = args.ticket or prepare(path, args.mode, args.revset, args.agent)
    if args.pane:
        caller = os.environ.get("TMUX_PANE")
        if not caller:
            raise ReviewError("--pane requires tmux; use reviewctl open in a terminal")
        exit_file = ticket_dir(ticket) / "last-exit.json"
        exit_file.unlink(missing_ok=True)
        pane = run(["tmux", "split-window", "-h", "-l", "50%", "-t", caller, "-P", "-F", "#{pane_id}",
                    "-e", f"REVIEWCTL_HOME={state_dir()}",
                    os.environ.get("REVIEWCTL_BIN", sys.argv[0]), "view", ticket]).decode().strip()
        if not args.wait:
            ready = False
            for _ in range(50):
                ready = bool(sessions(ticket))
                if ready or exit_file.exists():
                    break
                time.sleep(0.1)
            return {"ticket": ticket, "pane": pane, "repo": load(ticket)["repo"], "ready": ready}
        while True:
            live = run(["tmux", "list-panes", "-a", "-F", "#{pane_id}"]).decode().splitlines()
            if pane not in live:
                break
            time.sleep(0.2)
        if not exit_file.exists() or json.loads(exit_file.read_text())["code"]:
            raise ReviewError(f"Review pane closed unexpectedly; comments remain in review {ticket}")
    else:
        view(ticket)
    if args.handoff:
        handoff([ticket])
    return result(ticket, args.agent)


def daemon(path, payload=None):
    port = int(os.environ.get("CCMUX_PORT", "2269"))
    request = urllib.request.Request(f"http://127.0.0.1:{port}{path}",
        data=json.dumps(payload).encode() if payload is not None else None,
        headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(request, timeout=15) as response:
        return json.load(response)


def recipient(agent, reviews):
    session = daemon("/sessions/" + urllib.parse.quote(agent, safe=""))["session"]
    if session.get("id") != agent or not session.get("tmuxPane"):
        raise ReviewError("The selected agent no longer has a live tmux pane")
    if session.get("status") != "idle" or session.get("attentionType"):
        raise ReviewError("The selected agent is busy or awaiting a tool decision; try handoff when it is idle")
    cwd = Path(session.get("paneCwd") or session["cwd"]).resolve()
    if any(project_root(cwd) != Path(review["project"]) for review in reviews):
        raise ReviewError("The selected agent belongs to another project")
    return session


def prompt(reviews):
    blocks = ["Please address these tuicr review comments. Check each finding against the current code before editing."]
    for ticket, selected in reviews:
        data = load(ticket)
        blocks += [f"\nRepository: {data['repo']}\nReview: {ticket}\nDiff SHA-256: {data['fingerprint']}"]
        for c in selected:
            blocks += [f"\n[{c['id']}] {c.get('location', 'review')} [{c.get('comment_type', 'none')}] ({c.get('author', 'user')})\n{c['content']}"]
    text = "\n".join(blocks)
    # ccmux's multiline paste cap is measured in JavaScript UTF-16 units.
    if len(text.encode("utf-16-le")) // 2 > 65_536:
        raise ReviewError("Review exceeds the agent message limit; send fewer comments")
    return text


def send(tickets, agent, ids=None, include_ai=False, enter=True, selections=None):
    with locked(state_dir() / "send.lock"):
        data = [load(t) for t in tickets]
        for ticket in tickets:
            assert_current(ticket)
        selected = [(t, pending(t, agent, include_ai, selections[t] if selections else ids)) for t in tickets]
        if not any(items for _, items in selected):
            raise ReviewError("No undelivered comments selected")
        recipient(agent, data)
        daemon("/sessions/" + urllib.parse.quote(agent, safe="") + "/send", {"text": prompt(selected), "enter": enter})
        for ticket, items in selected:
            path = ticket_dir(ticket) / "deliveries.json"
            ledger = json.loads(path.read_text()) if path.exists() else {}
            ledger.setdefault(agent, []).extend(comment_key(c) for c in items)
            save(path, ledger)
    return {"agent": agent, "comments": sum(len(c) for _, c in selected), "action": "sent" if enter else "filled"}


def handoff(tickets):
    # Selection is deliberate: AI findings are visible here, never silently
    # included in ccmux's default return-to-author flow.
    available = [(t, c) for t in tickets if sessions(t) for c in comments(t)]
    chosen = choose([(str(i), f"{Path(load(t)['repo']).name} | {c.get('author', 'user')} | {c['location']} | {c['content'].splitlines()[0]}")
                     for i, (t, c) in enumerate(available)], "Comments> ", multi=True)
    if not chosen:
        return
    agents = daemon("/sessions")["sessions"]
    agents = [s for s in agents if s.get("tmuxPane") and s.get("status") == "idle" and not s.get("attentionType")]
    selected_agent = choose([(s["id"], f"{s.get('agentType')} | {s.get('project')} | {s.get('paneCwd') or s.get('cwd')} | {s.get('tmuxPane')}") for s in agents], "Agent> ")
    if not selected_agent:
        return
    action = choose([("fill", "Fill composer"), ("send", "Send and run")], "Handoff> ")
    if not action:
        return
    groups = {}
    for index in chosen:
        ticket, comment = available[int(index)]
        groups.setdefault(ticket, []).append(comment["id"])
    # Keep one prompt when reviewing several modules for the same task.
    send(list(groups), selected_agent[0], enter=action[0] == "send", selections=groups)


def main():
    os.umask(0o077)
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)
    opening = sub.add_parser("open", help="Open a diff; --pane opens beside the caller")
    opening.add_argument("--repo", default=os.getcwd())
    opening.add_argument("--pick-repo", action="store_true")
    opening.add_argument("--mode", choices=["working", "branch"], default="working")
    opening.add_argument("--revset")
    opening.add_argument("--ticket")
    opening.add_argument("--agent")
    opening.add_argument("--pane", action="store_true")
    opening.add_argument("--wait", action="store_true")
    opening.add_argument("--handoff", action="store_true")
    opening.add_argument("--result", help="Write JSON here, leaving the terminal for the TUI")
    for name in ["view", "context", "comments"]:
        sub.add_parser(name).add_argument("ticket")
    sub.add_parser("list")
    adding = sub.add_parser("add", help="Add an AI finding to an open review; pass tuicr JSON on stdin")
    adding.add_argument("ticket")
    adding.add_argument("--author", required=True, help="E.g. Codex AI Reviewer")
    sending = sub.add_parser("send")
    sending.add_argument("tickets", nargs="+")
    sending.add_argument("--agent", required=True)
    sending.add_argument("--comment", action="append")
    sending.add_argument("--include-ai", action="store_true")
    sending.add_argument("--no-enter", action="store_true")
    hand = sub.add_parser("handoff", help="Select comments and the recipient interactively")
    hand.add_argument("tickets", nargs="+")
    ack = sub.add_parser("ack", help="Record comment keys successfully filled into an external composer")
    ack.add_argument("ticket")
    ack.add_argument("--agent", required=True)
    ack.add_argument("--key", action="append", required=True)
    args = parser.parse_args()
    if args.command == "open":
        output = open_review(args)
        if args.result:
            save(Path(args.result), output)
            return
    elif args.command == "view":
        view(args.ticket)
        return
    elif args.command == "list":
        output = [json.loads(p.read_text()) for p in sorted(state_dir().glob("*/review.json"))]
    elif args.command == "context":
        output = context(args.ticket)
    elif args.command == "comments":
        output = comments(args.ticket)
    elif args.command == "add":
        assert_current(args.ticket)
        payload = json.load(sys.stdin)
        if not args.author.endswith(" AI Reviewer"):
            raise ReviewError("Agent author must end with ' AI Reviewer'")
        payload.pop("author", None)
        payload["username"] = args.author
        output = json.loads(run(["tuicr", "review", "add", "--session", str(session_path(args.ticket)), "--input", "-"],
                               env=review_env(args.ticket), input=json.dumps(payload).encode()))
    elif args.command == "send":
        if args.comment and len(args.tickets) != 1:
            raise ReviewError("--comment requires one review; use handoff to select across reviews")
        output = send(args.tickets, args.agent, args.comment, args.include_ai, not args.no_enter)
    elif args.command == "ack":
        acknowledge(args.ticket, args.agent, args.key)
        output = {"acknowledged": len(args.key)}
    else:
        handoff(args.tickets)
        return
    print(json.dumps(output, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    try:
        main()
    except (ReviewError, OSError, ValueError, subprocess.SubprocessError) as error:
        print(f"reviewctl: {error}", file=sys.stderr)
        sys.exit(1)
