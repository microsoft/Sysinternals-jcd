#!/usr/bin/env python3
"""Unix regression tests for path transport, terminal output and Bash Readline."""

import os
from pathlib import Path
import pty
import select
import subprocess
import tempfile
import textwrap
import time
import unittest


REPO = Path(__file__).resolve().parents[1]
BINARY = REPO / "target" / "release" / "jcd"
WRAPPER = REPO / "src" / "jcd_function.sh"


class PathSafetyTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="jcd-path-safety-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.env = dict(os.environ, JCD_BINARY=str(BINARY), JCD_WRAPPER=str(WRAPPER),
                        JCD_DEBUG="0", TERM="xterm", PS1="jcd-test> ",
                        HOME=str(self.root), XDG_CONFIG_HOME=str(self.root))
        suffixes = [
            "ordinary", "space name", "single'and\"double", "back\\slash",
            "$(touch JCD_UNEXPECTED)", "`touch JCD_UNEXPECTED`",
            ";touch JCD_UNEXPECTED;#", "*?[glob]", "tab\tname",
            "embedded\nnewline", "trailing\n", "escape\x1b[31m",
            os.fsdecode(b"non-utf8-\xff"), "caf\u00e9-\u76ee\u5f55",
        ]
        self.paths = []
        for index, suffix in enumerate(suffixes):
            path = self.root / f"case{index:02d}-{suffix}"
            path.mkdir()
            self.paths.append(path)

    def shell(self, script, *args):
        return subprocess.run(
            ["bash", "--noprofile", "--norc", "-c",
             'source "$JCD_WRAPPER"\ntrap - DEBUG\n' + script, "test", *args],
            cwd=self.root, env=self.env, capture_output=True, timeout=15,
        )

    def test_binary_and_navigation_preserve_bytes(self):
        for path in self.paths:
            with self.subTest(path=repr(path.name)):
                pattern = path.name.split("-", 1)[0]
                result = subprocess.run(
                    [str(BINARY), pattern, "--quiet", "--null"],
                    cwd=self.root, env=self.env, capture_output=True, timeout=5,
                )
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(result.stdout, os.fsencode(path) + b"\0")
                result = self.shell('jcd "$1" || exit; printf "%s\\0" "$PWD"', pattern)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(result.stdout, os.fsencode(path) + b"\0")

    def test_completion_helpers_preserve_records(self):
        for helper, pattern in [
            ("_jcd_get_relative_matches", "case"),
            ("_jcd_get_absolute_matches", str(self.root) + "/case"),
            ("_jcd_get_relative_matches", "./case"),
        ]:
            result = self.shell(f'{helper} "$1" false', pattern)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(set(result.stdout.split(b"\0")[:-1]),
                             {os.fsencode(path) for path in self.paths})
        child = self.root / "child"
        child.mkdir()
        result = self.shell(
            'cd child; _jcd_get_relative_matches "../case" false'
        )
        self.assertEqual(set(result.stdout.split(b"\0")[:-1]),
                         {os.fsencode(path) for path in self.paths})

    def test_no_match_does_not_change_directory(self):
        result = self.shell(
            'jcd nonexistent-pattern >&2; code=$?; '
            'printf "%s\\0" "$PWD"; test "$code" -ne 0'
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, os.fsencode(self.root) + b"\0")

    def test_terminal_output_escapes_controls(self):
        master, slave = pty.openpty()
        try:
            result = subprocess.run(
                [str(BINARY), "case11", "--quiet"], cwd=self.root,
                env=self.env, stdout=slave, stderr=subprocess.PIPE, timeout=5,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertTrue(select.select([master], [], [], 5)[0])
            output = os.read(master, 4096)
            self.assertNotIn(b"\x1b", output)
            self.assertIn(b"\\u{1b}[31m", output)
        finally:
            os.close(master)
            os.close(slave)

    def test_readline_tab_and_shift_tab_are_literal(self):
        for path in self.paths:
            for key in [b"\t", b"\x1b[Z", b"\t\x1b[Z"]:
                with self.subTest(path=repr(path.name), key=key):
                    result_file = self.root / "selected"
                    result_file.unlink(missing_ok=True)
                    master, slave = pty.openpty()
                    proc = subprocess.Popen(
                        ["bash", "--noprofile", "--norc", "-i"],
                        cwd=self.root, env=dict(self.env, RESULT=str(result_file)),
                        stdin=slave, stdout=slave, stderr=slave,
                    )
                    transcript = bytearray()
                    try:
                        pattern = path.name.split("-", 1)[0].encode()
                        os.write(master, b'source "$JCD_WRAPPER"\n'
                                 + b"jcd " + pattern + key + b"\n"
                                 + b'printf "%s" "$PWD" > "$RESULT"\nexit\n')
                        deadline = time.monotonic() + 15
                        while proc.poll() is None and time.monotonic() < deadline:
                            if select.select([master], [], [], 0.1)[0]:
                                transcript.extend(os.read(master, 65536))
                        self.assertIsNotNone(proc.poll(), bytes(transcript))
                        self.assertTrue(result_file.exists(), bytes(transcript))
                        self.assertEqual(result_file.read_bytes(), os.fsencode(path),
                                         bytes(transcript))
                        self.assertFalse(list(self.root.rglob("JCD_UNEXPECTED")))
                    finally:
                        if proc.poll() is None:
                            proc.kill()
                        proc.wait()
                        os.close(master)
                        os.close(slave)

    def test_pipeline_parameters_are_data(self):
        template = (REPO / "templates" / "build.yaml").read_text()
        script = textwrap.dedent(template.split("- script: |\n", 1)[1]
                                 .split("  displayName:", 1)[0])
        self.assertNotIn("${{", script)
        self.assertIn("JCD_LDPATH: ${{ parameters.ldpath }}", template)
        self.assertIn("JCD_SRC_PATH: ${{ parameters.srcPath }}", template)
        self.assertIn("persistCredentials: false",
                      (REPO / "azure-pipelines.yml").read_text())
        source = self.root / 'source $(touch JCD_UNEXPECTED) " quote'
        source.mkdir()
        for ldpath in ["", "/ordinary/lib", '$(touch JCD_UNEXPECTED)`touch JCD_UNEXPECTED`";\n#']:
            env = dict(self.env, JCD_SRC_PATH=str(source), JCD_LDPATH=ldpath,
                       LD_LIBRARY_PATH="/existing", EXPECTED_DIR=str(source),
                       EXPECTED_LD=f"{ldpath}:/existing" if ldpath else "/existing")
            # Stub only cargo; execute the actual checked-in pipeline script.
            result = subprocess.run(
                ["bash", "-c",
                 'cargo() { [[ "$*" == "build --release" && '
                 '"$PWD" == "$EXPECTED_DIR" && '
                 '"$LD_LIBRARY_PATH" == "$EXPECTED_LD" ]]; }\n' + script],
                cwd=self.root, env=env, capture_output=True, timeout=5,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertFalse(list(self.root.rglob("JCD_UNEXPECTED")))
        result = subprocess.run(
            ["bash", "-c", 'cargo() { touch JCD_UNEXPECTED; }\n' + script],
            cwd=self.root, env=dict(self.env, JCD_SRC_PATH=str(self.root / "missing"),
                                   JCD_LDPATH=""),
            capture_output=True, timeout=5,
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse((self.root / "JCD_UNEXPECTED").exists())


if __name__ == "__main__":
    unittest.main()
