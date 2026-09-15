import http.client
import socket
import subprocess
import threading
import unittest
from unittest.mock import patch

import health


class SnapshotTests(unittest.TestCase):
    def test_startup_is_unavailable(self):
        healthy, status = health.Snapshot().response()
        self.assertFalse(healthy)
        self.assertTrue(status["stale"])

    def test_all_checks_required(self):
        for checks in ({}, {"db": False}, {"db": True, "web": False}):
            with self.subTest(checks=checks):
                snapshot = health.Snapshot()
                snapshot.update(checks)
                self.assertFalse(snapshot.response()[0])

    def test_healthy_snapshot_and_expiry(self):
        snapshot = health.Snapshot()
        with patch("health.time.monotonic", return_value=10):
            snapshot.update({"db": True, "web": True})
            healthy, status = snapshot.response()
        self.assertTrue(healthy)
        self.assertEqual(status["passed"], 2)
        with patch("health.time.monotonic", return_value=71):
            self.assertFalse(snapshot.response()[0])

    def test_update_copies_input(self):
        checks = {"db": True}
        snapshot = health.Snapshot()
        snapshot.update(checks)
        checks["db"] = False
        self.assertTrue(snapshot.response()[0])


class ProbeTests(unittest.TestCase):
    def test_commands_fail_closed(self):
        for failure in (OSError(), subprocess.TimeoutExpired("probe", 6)):
            with self.subTest(failure=failure), patch("health.subprocess.run", side_effect=failure):
                self.assertFalse(health.command_ok(["probe"]))

    def test_command_exit_status(self):
        for code in (0, 1, 3):
            with self.subTest(code=code), patch("health.subprocess.run") as run:
                run.return_value.returncode = code
                self.assertEqual(health.command_ok(["probe"]), code == 0)

    def test_socket_failure(self):
        with patch("health.socket.socket", side_effect=OSError()):
            self.assertFalse(health.socket_ok(("127.0.0.1", 1)))

    def test_collection_has_no_secret_or_mutating_commands(self):
        config = {
            "units": ["skinem-server.service"], "systemctl": "systemctl",
            "curl": "curl", "domain": "split.example.org",
            "tcp": {"backend": 50051}, "databaseSocket": "/run/postgresql/socket",
        }
        with patch("health.command_ok", return_value=True) as command, patch("health.socket_ok", return_value=True) as connect:
            checks = health.collect(config)
        self.assertEqual(len(checks), 4)
        self.assertTrue(all(checks.values()))
        self.assertEqual(command.call_args_list[0].args[0], ["systemctl", "is-active", "--quiet", "skinem-server.service"])
        self.assertIn("split.example.org:443:127.0.0.1", command.call_args.args[0])
        self.assertNotIn("--insecure", command.call_args.args[0])
        connect.assert_any_call("/run/postgresql/socket", socket.AF_UNIX)


class HttpTests(unittest.TestCase):
    def setUp(self):
        self.snapshot = health.Snapshot()
        self.server = health.ProbeServer(("127.0.0.1", 0), health.handler_for(self.snapshot))
        self.thread = threading.Thread(target=self.server.serve_forever)
        self.thread.start()

    def tearDown(self):
        self.server.shutdown()
        self.server.server_close()
        self.thread.join()

    def request(self, path, method="GET"):
        connection = http.client.HTTPConnection(*self.server.server_address, timeout=2)
        try:
            connection.request(method, path)
            response = connection.getresponse()
            return response.status, response.read(), response.getheader("Cache-Control")
        finally:
            connection.close()

    def test_health_and_dashboard_have_distinct_failure_status(self):
        self.assertEqual(self.request("/healthz")[0], 503)
        self.assertEqual(self.request("/status.json")[0], 200)
        self.snapshot.update({"backend": True})
        status, body, cache = self.request("/healthz")
        self.assertEqual(status, 200)
        self.assertIn(b'"healthy"', body)
        self.assertEqual(cache, "no-store")

    def test_head_and_unknown_routes(self):
        self.assertEqual(self.request("/healthz", "HEAD")[:2], (503, b""))
        self.assertEqual(self.request("/secret")[0], 404)
        self.assertEqual(self.request("/healthz", "POST")[0], 501)


if __name__ == "__main__":
    unittest.main()
