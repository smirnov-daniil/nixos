import errno
import fcntl
import json
import os
from pathlib import Path
import pty
import select
import shutil
import signal
import subprocess
import tempfile
import termios
import time
import unittest


MODELS = """provider      model      context  max-out  thinking  images
ollama        local      128K     16K      no        no
openai-codex  fast       128K     128K     yes       no
openai-codex  smart      272K     128K     yes       yes
"""
RESPONSE = {"answer": "Use pwd.", "commands": [], "needs_clarification": False}


class SysqTests(unittest.TestCase):
    def setUp(self):
        directory = tempfile.TemporaryDirectory(prefix="sysq-test-")
        self.addCleanup(directory.cleanup)
        self.root = Path(directory.name)
        self.bin = self.root / "bin"
        self.bin.mkdir()
        self.log = self.root / "pi.jsonl"
        self.env = dict(os.environ, HOME=str(self.root),
                        XDG_RUNTIME_DIR=str(self.root / "runtime"),
                        XDG_CACHE_HOME=str(self.root / "cache"),
                        HISTDB_FILE=str(self.root / "missing-history"),
                        PATH=str(self.bin) + os.pathsep + os.environ["PATH"],
                        TEST_LOG=str(self.log), TEST_MODELS=MODELS,
                        TEST_RESPONSE=json.dumps(RESPONSE))
        for key in ("SYSQ_MODEL", "SYSQ_WEB_SEARCH_EXTENSION", "SYSQ_WEB_FETCH_EXTENSION",
                    "PI_CODING_AGENT_DIR", "BASH_ENV", "ENV"):
            self.env.pop(key, None)
        source = Path(__file__).parent
        script = (source / "sysq.sh").read_text()
        for name, path in (("responseSchema", source / "response-schema.json"),
                           ("skillPrompt", source / "skill" / "SKILL.md"),
                           ("zshIntegration", source / "sysq.zsh")):
            script = script.replace(f"@{name}@", str(path))
        self.script = self.root / "sysq"
        self.script.write_text(script)
        self.command = [shutil.which("bash"), "-euo", "pipefail", str(self.script)]
        self.model_file = self.root / "cache" / "sysq" / "model"
        self.session_file = self.root / "runtime" / "sysq" / "session"
        self.make_tool("pi", """
import json, os, sys
from pathlib import Path
args = sys.argv[1:]
if '--version' in args:
    print('0.99.0-test')
elif '--list-models' in args:
    if os.environ.get('TEST_LIST_FAIL'):
        sys.exit(8)
    print(os.environ['TEST_MODELS'], end='')
else:
    with Path(os.environ['TEST_LOG']).open('a') as log:
        log.write(json.dumps({'args': args, 'prompt': sys.stdin.read()}) + '\\n')
    if os.environ.get('TEST_PI_FAIL'):
        print('provider failed', file=sys.stderr)
        sys.exit(9)
    print(os.environ['TEST_RESPONSE'])
""")
        self.make_tool("gum", """
import os, sys
from pathlib import Path
args = sys.argv[1:]
if args[0] == '--version':
    print('test')
elif args[0] == 'spin':
    sys.exit('gum spin must not leave terminal queries unread')
elif args[0] == 'filter':
    choices = sys.stdin.read().splitlines()
    Path(os.environ['TEST_LOG'] + '.filter').write_text('\\n'.join(choices))
    if os.environ.get('TEST_CANCEL'):
        sys.exit(130)
    print(os.environ.get('TEST_SELECTION', choices[0]))
elif args[0] == 'write':
    if os.environ.get('TEST_CANCEL'):
        sys.exit(130)
    print(os.environ.get('TEST_QUESTION', 'where am I?'))
elif args[0] == 'choose':
    choices = sys.stdin.read().splitlines()
    Path(os.environ['TEST_LOG'] + '.choose').write_text('\\n'.join(choices))
    if os.environ.get('TEST_CANCEL'):
        sys.exit(130)
    print(choices[0])
elif args[0] == 'confirm':
    sys.exit(int(os.environ.get('TEST_CONFIRM_EXIT', '0')))
else:
    sys.exit(10)
""")

    def make_tool(self, name, body):
        path = self.bin / name
        path.write_text(f"#!{shutil.which('python3')}\n" + body)
        path.chmod(0o755)

    def run_sysq(self, *args, input=""):
        return subprocess.run([*self.command, *args], input=input, env=self.env,
                              cwd=self.root, capture_output=True, text=True, timeout=10)

    def run_terminal(self, *args, release_after=None, release=b'\n'):
        master, slave = pty.openpty()
        process = None
        output = bytearray()
        released = False
        deadline = time.monotonic() + 10
        try:
            process = subprocess.Popen([*self.command, *args], env=self.env,
                                       cwd=self.root, stdin=slave, stdout=slave,
                                       stderr=slave, start_new_session=True,
                                       preexec_fn=lambda: fcntl.ioctl(0, termios.TIOCSCTTY, 0))
            os.close(slave)
            slave = None
            while True:
                remaining = deadline - time.monotonic()
                self.assertGreater(remaining, 0, output.decode())
                ready, _, _ = select.select([master], [], [], remaining)
                self.assertTrue(ready, output.decode())
                try:
                    data = os.read(master, 4096)
                except OSError as error:
                    if error.errno == errno.EIO:
                        break
                    raise
                if not data:
                    break
                output.extend(data)
                if release_after and not released and release_after in output:
                    self.assertIsNone(process.poll(), output.decode())
                    os.write(master, release)
                    released = True
            process.wait(timeout=2)
            if release_after:
                self.assertTrue(released, output.decode())
            return subprocess.CompletedProcess(args, process.returncode,
                                               output.decode(), '')
        finally:
            if process is not None and process.poll() is None:
                os.killpg(process.pid, signal.SIGKILL)
                process.wait()
            os.close(master)
            if slave is not None:
                os.close(slave)

    def calls(self):
        if not self.log.exists():
            return []
        return [json.loads(line) for line in self.log.read_text().splitlines()]

    def assert_success(self, result):
        self.assertEqual(result.returncode, 0, result.stderr or result.stdout)

    def test_model_listing_and_doctor(self):
        result = self.run_sysq("models")
        self.assert_success(result)
        self.assertEqual(result.stdout.splitlines(),
                         ["ollama/local", "openai-codex/fast", "openai-codex/smart"])
        result = self.run_sysq("doctor")
        self.assert_success(result)
        self.assertIn("pi: 0.99.0-test", result.stdout)
        self.assertIn("not selected", result.stdout)
        self.assertFalse(self.calls())

    def test_noninteractive_requires_model(self):
        result = self.run_sysq("where am I?")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("choose a model", result.stderr)
        self.assertIn("openai-codex/fast", result.stderr)
        self.assertFalse(self.calls())

    def test_explicit_model_and_read_only_invocation(self):
        self.env["SYSQ_MODEL"] = "ollama/local"
        result = self.run_sysq("--model", "openai-codex/fast", "where am I?")
        self.assert_success(result)
        self.assertIn("Use pwd.", result.stdout)
        call = self.calls()[0]
        args = call["args"]
        for flag in ("--offline", "--no-extensions", "--no-skills",
                     "--no-context-files", "--no-session", "--print"):
            self.assertIn(flag, args)
        self.assertEqual(args[args.index("--provider") + 1], "openai-codex")
        self.assertEqual(args[args.index("--model") + 1], "fast")
        self.assertEqual(args[args.index("--tools") + 1], "read,grep,find,ls")
        self.assertEqual(args[args.index("--append-system-prompt") + 1], "")
        self.assertIn('"needs_clarification"', args[args.index("--system-prompt") + 1])
        self.assertIn("where am I?", call["prompt"])
        self.assertFalse(self.model_file.exists())

    def test_environment_model_and_bare_id(self):
        self.env["SYSQ_MODEL"] = "smart"
        self.assert_success(self.run_sysq("where am I?"))
        args = self.calls()[0]["args"]
        self.assertEqual(args[args.index("--model") + 1], "smart")
        self.assertEqual(args[args.index("--provider") + 1], "openai-codex")

    def test_save_model_and_reuse(self):
        self.assert_success(self.run_sysq("model", "openai-codex/smart"))
        self.assertEqual(self.model_file.read_text(), "openai-codex/smart\n")
        self.assert_success(self.run_sysq("where am I?"))
        self.assert_success(self.run_sysq("new"))
        self.assertFalse(self.session_file.exists())
        self.assertTrue(self.model_file.exists())
        result = self.run_sysq("context")
        self.assert_success(result)
        self.assertIn("Model: openai-codex/smart", result.stdout)

    def test_first_terminal_request_selects_and_saves_model(self):
        self.env["TEST_SELECTION"] = "openai-codex/smart"
        self.assert_success(self.run_terminal("where am I?"))
        self.assertEqual(self.model_file.read_text(), "openai-codex/smart\n")
        self.assertTrue(Path(str(self.log) + ".filter").exists())
        self.assertEqual(len(self.calls()), 1)

    def test_interactive_answer_waits_for_enter(self):
        result = self.run_terminal("--model", "fast",
                                   release_after=b'Press Enter to close')
        self.assert_success(result)
        self.assertIn("Use pwd.", result.stdout)
        self.assertLess(result.stdout.index("Use pwd."),
                        result.stdout.index("Press Enter to close"))

    def test_widget_answer_without_commands_waits_for_enter(self):
        result_file = self.root / "result"
        result_file.touch()
        result = self.run_terminal("--model", "fast", "explain", "--return-file",
                                   str(result_file), "--", "pwd",
                                   release_after=b'Press Enter to close')
        self.assert_success(result)
        self.assertIn("Use pwd.", result.stdout)
        self.assertEqual(result_file.read_text(), "")

    def test_widget_answer_can_be_dismissed_with_ctrl_c(self):
        result_file = self.root / "result"
        result_file.touch()
        result = self.run_terminal("--model", "fast", "--return-file", str(result_file),
                                   "where am I?", release_after=b'Press Enter to close',
                                   release=b'\x03')
        self.assertEqual(result.returncode, 130, result.stdout)
        self.assertIn("Use pwd.", result.stdout)
        self.assertEqual(result_file.read_text(), "")

    def test_explicit_and_noninteractive_requests_do_not_wait(self):
        result_file = self.root / "result"
        result_file.touch()
        for result in (self.run_terminal("--model", "fast", "where am I?"),
                       self.run_sysq("--model", "fast", "--return-file",
                                     str(result_file), "where am I?")):
            self.assert_success(result)
            self.assertIn("Use pwd.", result.stdout)
            self.assertNotIn("Press Enter to close", result.stdout)

    @unittest.skipUnless(shutil.which("gum"), "Gum is not available")
    def test_terminal_backend_does_not_emit_capability_queries(self):
        (self.bin / "gum").unlink()
        (self.bin / "gum").symlink_to(shutil.which("gum"))
        result = self.run_terminal("--model", "fast", "where am I?")
        self.assert_success(result)
        self.assertIn("Use pwd.", result.stdout)
        self.assertIn("Ctrl-C", result.stdout)
        self.assertNotIn("\x1b[?2026$p", result.stdout)
        self.assertNotIn("\x1b[?2027$p", result.stdout)

    def test_terminal_backend_failure_does_not_wait(self):
        self.env["TEST_PI_FAIL"] = "1"
        result = self.run_terminal("--model", "fast", "--return-file",
                                   str(self.root / "result"), "where am I?")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("provider failed", result.stdout)
        self.assertNotIn("Press Enter to close", result.stdout)
        self.assertFalse(self.session_file.exists())

    def test_interactive_context_waits_for_enter(self):
        self.env["TEST_QUESTION"] = "/context"
        result = self.run_terminal(release_after=b'Press Enter to close')
        self.assert_success(result)
        self.assertIn("Recent conversation: none", result.stdout)
        self.assertFalse(self.calls())

    def test_interactive_new_waits_for_enter(self):
        self.env["TEST_QUESTION"] = "/new"
        result = self.run_terminal(release_after=b'Press Enter to close')
        self.assert_success(result)
        self.assertIn("Started a new sysq session.", result.stdout)
        self.assertFalse(self.calls())

    def test_cancel_question_does_not_wait_or_invoke_pi(self):
        self.env["TEST_CANCEL"] = "1"
        result = self.run_terminal("--model", "fast")
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn("Press Enter to close", result.stdout)
        self.assertFalse(self.calls())

    def test_widget_command_selection_returns_without_running(self):
        command = f"touch {self.root / 'must-not-exist'}"
        self.env["TEST_RESPONSE"] = json.dumps(dict(RESPONSE, commands=[{
            "command": command, "description": "Create a file", "risk": "changes-files"}]))
        result_file = self.root / "result"
        result_file.touch()
        result = self.run_terminal("--model", "fast", "--return-file", str(result_file),
                                   "create a file")
        self.assert_success(result)
        self.assertEqual(result_file.read_text(), command)
        self.assertNotIn("Press Enter to close", result.stdout)
        self.assertFalse((self.root / "must-not-exist").exists())

    def test_destructive_command_declined_does_not_fill_buffer(self):
        self.env["TEST_RESPONSE"] = json.dumps(dict(RESPONSE, commands=[{
            "command": "rm -rf /", "description": "Delete files", "risk": "destructive"}]))
        self.env["TEST_CONFIRM_EXIT"] = "1"
        result_file = self.root / "result"
        result_file.touch()
        result = self.run_terminal("--model", "fast", "--return-file", str(result_file),
                                   "delete files")
        self.assert_success(result)
        self.assertEqual(result_file.read_text(), "")

    def test_model_command_reopens_selector(self):
        self.assert_success(self.run_sysq("model", "openai-codex/fast"))
        self.env["SYSQ_MODEL"] = "openai-codex/fast"
        self.env["TEST_SELECTION"] = "ollama/local"
        self.assert_success(self.run_terminal("model"))
        self.assertEqual(self.model_file.read_text(), "ollama/local\n")
        self.assertFalse(self.calls())

    def test_cancel_selection_does_not_invoke_pi(self):
        self.env["TEST_CANCEL"] = "1"
        self.assert_success(self.run_terminal("where am I?"))
        self.assertFalse(self.calls())
        self.assertFalse(self.model_file.exists())

    def test_missing_and_ambiguous_models_fail(self):
        for model in ("missing", "openai-codex/missing"):
            result = self.run_sysq("--model", model, "where am I?")
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("unavailable or ambiguous", result.stderr)
        self.env["TEST_MODELS"] += "other smart 128K 16K no no\n"
        result = self.run_sysq("--model", "smart", "where am I?")
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(self.calls())

    def test_canonical_model_takes_precedence_over_nested_id(self):
        self.env["TEST_MODELS"] += ("openai gpt-4o 128K 16K no yes\n"
                                    "openrouter openai/gpt-4o 128K 16K no yes\n")
        self.assert_success(self.run_sysq("model", "openai/gpt-4o"))
        self.assert_success(self.run_sysq("where am I?"))
        args = self.calls()[0]["args"]
        self.assertEqual(args[args.index("--provider") + 1], "openai")
        self.assertEqual(args[args.index("--model") + 1], "gpt-4o")
        self.assertEqual(self.model_file.read_text(), "openai/gpt-4o\n")

    def test_model_catalog_failures(self):
        self.env["TEST_MODELS"] = ("No models available. Use /login to log into a provider via OAuth "
                                   "or API key. See:\n  https://example.invalid/providers\n")
        result = self.run_sysq("--model", "fast", "where am I?")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("no available Pi models", result.stderr)
        self.assertNotIn("No/models", result.stderr)
        self.assertEqual(self.run_sysq("models").stdout, "")
        self.assertFalse(self.model_file.exists())
        self.env["TEST_LIST_FAIL"] = "1"
        result = self.run_sysq("models")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("could not list Pi models", result.stderr)
        self.assertFalse(self.calls())

    def test_explain_stdin_and_command_labels(self):
        self.env["TEST_RESPONSE"] = json.dumps(dict(RESPONSE, commands=[{
            "command": "pwd", "description": "Show the directory", "risk": "read-only"}]))
        result = self.run_sysq("--model", "fast", "explain", input="pwd")
        self.assert_success(result)
        self.assertIn("[read-only] pwd", result.stdout)
        self.assertIn("Explain this command. Do not execute it:\n\npwd", self.calls()[0]["prompt"])

    def test_invalid_responses_and_backend_failure(self):
        for response in ("not json", "{}", json.dumps(dict(RESPONSE, commands=[{
                "command": "rm", "description": "Delete", "risk": "unknown"}]))):
            self.env["TEST_RESPONSE"] = response
            result = self.run_sysq("--model", "fast", "where am I?")
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("Pi returned", result.stderr)
            self.assertFalse(self.session_file.exists())
        self.env["TEST_PI_FAIL"] = "1"
        result = self.run_sysq("--model", "fast", "where am I?")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("provider failed", result.stderr)

    def test_markdown_fenced_response(self):
        self.env["TEST_RESPONSE"] = "```json\n" + json.dumps(RESPONSE) + "\n```"
        self.assert_success(self.run_sysq("--model", "fast", "where am I?"))

    def test_cache_and_refresh(self):
        self.assert_success(self.run_sysq("--model", "fast", "where am I?"))
        self.assert_success(self.run_sysq("new"))
        result = self.run_sysq("--model", "fast", "where am I?")
        self.assert_success(result)
        self.assertIn("cached response", result.stdout)
        self.assertEqual(len(self.calls()), 1)
        self.assert_success(self.run_sysq("new"))
        self.assert_success(self.run_sysq("--refresh", "--model", "fast", "where am I?"))
        self.assertEqual(len(self.calls()), 2)

    def test_web_extensions_are_explicit_and_cache_is_separate(self):
        self.assert_success(self.run_sysq("--model", "fast", "where am I?"))
        self.assert_success(self.run_sysq("new"))
        result = self.run_sysq("--web", "--model", "fast", "where am I?")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("--web requires Pi packages", result.stderr)
        for name in ("SEARCH", "FETCH"):
            extension = self.root / f"{name}.js"
            extension.touch()
            self.env[f"SYSQ_WEB_{name}_EXTENSION"] = str(extension)
        result = self.run_sysq("--web", "--model", "fast", "where am I?")
        self.assert_success(result)
        self.assertEqual(len(self.calls()), 2)
        args = self.calls()[-1]["args"]
        self.assertEqual(args.count("-e"), 2)
        self.assertEqual(args[args.index("--tools") + 1],
                         "read,grep,find,ls,web_search,web_fetch,batch_web_fetch")


if __name__ == "__main__":
    unittest.main()
