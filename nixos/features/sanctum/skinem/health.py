"""Loopback-only availability checks; no credentials or application mutations."""

import json
import socket
import subprocess
import sys
import threading
import time
from http.server import BaseHTTPRequestHandler, HTTPServer


def command_ok(arguments):
    try:
        return subprocess.run(
            arguments, stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL, timeout=6, check=False,
        ).returncode == 0
    except (OSError, subprocess.TimeoutExpired):
        return False


def socket_ok(address, family=socket.AF_INET):
    try:
        with socket.socket(family, socket.SOCK_STREAM) as connection:
            connection.settimeout(1)
            connection.connect(address)
        return True
    except OSError:
        return False


def collect(config):
    checks = {
        unit: command_ok([config["systemctl"], "is-active", "--quiet", unit])
        for unit in config["units"]
    }
    checks.update({
        name: socket_ok(("127.0.0.1", port))
        for name, port in config["tcp"].items()
    })
    if config["databaseSocket"]:
        checks["database_socket"] = socket_ok(config["databaseSocket"], socket.AF_UNIX)
    domain = config["domain"]
    checks["frontend_https"] = command_ok([
        config["curl"], "--silent", "--fail", "--max-time", "5",
        "--noproxy", "*", "--resolve", f"{domain}:443:127.0.0.1",
        f"https://{domain}/",
    ])
    return checks


class Snapshot:
    def __init__(self):
        self.lock = threading.Lock()
        self.checks = {}
        self.updated = None

    def update(self, checks):
        with self.lock:
            self.checks = dict(checks)
            self.updated = time.monotonic()

    def response(self):
        with self.lock:
            checks = dict(self.checks)
            stale = self.updated is None or time.monotonic() - self.updated > 60
        healthy = bool(checks) and all(checks.values()) and not stale
        return healthy, {
            "status": "healthy" if healthy else "unavailable",
            "passed": sum(checks.values()), "total": len(checks),
            "stale": stale, "checks": checks,
        }


def handler_for(snapshot):
    class Handler(BaseHTTPRequestHandler):
        def do_GET(self):
            if self.path not in ("/healthz", "/status.json"):
                self.send_error(404)
                return
            healthy, status = snapshot.response()
            body = json.dumps(status).encode()
            self.send_response(503 if self.path == "/healthz" and not healthy else 200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(body)))
            self.send_header("Cache-Control", "no-store")
            self.end_headers()
            if self.command != "HEAD":
                self.wfile.write(body)

        do_HEAD = do_GET

        def log_message(self, *_):
            pass

    return Handler


class ProbeServer(HTTPServer):
    def get_request(self):
        connection, address = super().get_request()
        connection.settimeout(3)
        return connection, address


def poll(config, snapshot):
    while True:
        snapshot.update(collect(config))
        time.sleep(15)


def main():
    with open(sys.argv[1], encoding="utf-8") as source:
        config = json.load(source)
    snapshot = Snapshot()
    with ProbeServer(("127.0.0.1", config["port"]), handler_for(snapshot)) as server:
        threading.Thread(target=poll, args=(config, snapshot), daemon=True).start()
        server.serve_forever()


if __name__ == "__main__":
    main()
