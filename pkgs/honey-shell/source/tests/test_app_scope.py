import os
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from services.app_scope import launch_argv


class AppScopeTests(unittest.TestCase):
    def setUp(self):
        env = {"HOME": "/home/test", "HONEY_SYSTEMD_RUN": "/store/systemd-run",
               "HONEY_REAL_SETSID": "/store/setsid", "HONEY_SHELL": "/store/sh",
               "WAYLAND_DISPLAY": "wayland-1", "DISPLAY": ":1"}
        self.env = patch.dict(os.environ, env, clear=True)
        self.env.start()
        self.addCleanup(self.env.stop)

    def test_native_app_command_is_preserved_and_escapes_shell_group(self):
        command = 'app "argument with spaces"'
        argv = launch_argv(["-f", "sh", "-c", command])
        self.assertEqual(argv[0], "/store/systemd-run")
        self.assertIn("--collect", argv)
        self.assertIn("--expand-environment=no", argv)
        self.assertIn("--property=PartOf=graphical-session.target", argv)
        self.assertNotIn("--property=PartOf=honey-session.target", argv)
        self.assertIn("--setenv=WAYLAND_DISPLAY=wayland-1", argv)
        self.assertIn("--setenv=DISPLAY=:1", argv)
        self.assertEqual(argv[-4:], ["--", "/store/sh", "-c", command])

    def test_other_setsid_calls_keep_the_original_behavior(self):
        self.assertEqual(launch_argv(["--wait", "other-app"]),
                         ["/store/setsid", "--wait", "other-app"])


if __name__ == "__main__":
    unittest.main()
