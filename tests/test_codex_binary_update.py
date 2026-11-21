"""Exercise nix-update in an isolated repository with mocked external commands.

Run with: python3 -m unittest discover -s tests -p 'test_codex_binary_update.py'
Requires Nushell on PATH; never activates the real Home Manager configuration.
"""

import json
import os
from pathlib import Path
import shlex
import shutil
import subprocess
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
HASH = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
MOCK_NIX = r'''
import json
import os
from pathlib import Path
import sys

args = sys.argv[1:]
with Path("calls.jsonl").open("a") as stream:
    stream.write(json.dumps(args) + "\n")
mode = os.environ.get("TEST_MODE", "success")
if args[:2] == ["flake", "update"]:
    if mode == "update_failure":
        print("update failed", file=sys.stderr)
        sys.exit(1)
elif "eval" in args:
    if mode == "eval_failure":
        print("evaluation failed", file=sys.stderr)
        sys.exit(1)
    print(os.environ.get("TEST_VERSION", "0.165.0"))
elif "prefetch-file" in args:
    if mode == "download_failure":
        print("download failed", file=sys.stderr)
        sys.exit(1)
    print(json.dumps({"hash": "bad" if mode == "invalid_hash" else os.environ["TEST_HASH"]}))
else:
    sys.exit("Unexpected nix command: " + repr(args))
'''


class CodexBinaryUpdateTest(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        self.manifest = self.root / "packages/codex-binary/source.json"
        self.manifest.parent.mkdir(parents=True)
        self.before = (ROOT / "packages/codex-binary/source.json").read_text()
        self.manifest.write_text(self.before)
        commands = self.root / "bin"
        commands.mkdir()
        for name, contents in {
            "nix": "#!" + sys.executable + "\n" + MOCK_NIX,
            "gh": "#!/bin/sh\nexit 1\n",
            "git": "#!/bin/sh\nexit 0\n",
        }.items():
            path = commands / name
            path.write_text(contents)
            path.chmod(0o755)
        bootstrap = self.root / "bootstrap"
        bootstrap.mkdir()
        for name in ("darwin.sh", "linux.sh"):
            path = bootstrap / name
            path.write_text("#!/bin/sh\ntouch " + shlex.quote(str(self.root / "applied")) + "\n")
            path.chmod(0o755)
        functions = (ROOT / "config/nushell/scripts/functions.nu").read_text()
        functions = functions.replace("cd ~/.local/share/dotfiles", "cd '" + str(self.root) + "'")
        self.functions = self.root / "functions.nu"
        self.functions.write_text(functions)
        self.env = dict(os.environ, PATH=str(commands) + os.pathsep + os.environ["PATH"], TEST_HASH=HASH)
        self.nu = shutil.which("nu")
        if self.nu is None:
            self.skipTest("Nushell is required")

    def run_update(self, mode="success", version="0.165.0"):
        return subprocess.run(
            [self.nu, "--no-config-file", "-c", "source '" + str(self.functions) + "'; nix-update linux-gui"],
            cwd=self.root,
            env=dict(self.env, TEST_MODE=mode, TEST_VERSION=version),
            text=True,
            capture_output=True,
        )

    def calls(self):
        return [json.loads(line) for line in (self.root / "calls.jsonl").read_text().splitlines()]

    def test_success_updates_pin_and_applies(self):
        result = self.run_update()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(self.manifest.read_text()), {"version": "0.165.0", "hash": HASH})
        self.assertTrue((self.root / "applied").exists())
        self.assertTrue(any(args[-1].endswith("rust-v0.165.0/codex-package-x86_64-unknown-linux-musl.tar.gz") for args in self.calls()))
        self.assertEqual(list(self.manifest.parent.glob("*.tmp")), [])

    def test_unchanged_version_reuses_pin_without_download(self):
        result = self.run_update(version=json.loads(self.before)["version"])
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.manifest.read_text(), self.before)
        self.assertFalse(any("prefetch-file" in args for args in self.calls()))
        self.assertTrue((self.root / "applied").exists())

    def test_failures_preserve_pin_and_skip_activation(self):
        for mode in ("update_failure", "eval_failure", "download_failure", "invalid_hash"):
            with self.subTest(mode=mode):
                result = self.run_update(mode=mode)
                self.assertNotEqual(result.returncode, 0, result.stdout)
                self.assertEqual(self.manifest.read_text(), self.before)
                self.assertFalse((self.root / "applied").exists())

    def test_invalid_version_stops_before_download(self):
        result = self.run_update(version="not-a-version")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.manifest.read_text(), self.before)
        self.assertFalse(any("prefetch-file" in args for args in self.calls()))
        self.assertFalse((self.root / "applied").exists())


if __name__ == "__main__":
    unittest.main()
