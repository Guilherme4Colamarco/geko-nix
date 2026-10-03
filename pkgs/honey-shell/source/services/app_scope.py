"""Keep the official apps.launch catalog/validation, isolate its child process.

Pleamar 0.2.8 launches validated desktop commands through setsid -f sh -c.
A POSIX session does not escape a systemd control group. This package-local
adapter redirects that exact invocation into a transient user service.
"""
import os
from pathlib import Path
import sys

ENVIRONMENT = ("DISPLAY", "WAYLAND_DISPLAY", "XDG_RUNTIME_DIR",
               "DBUS_SESSION_BUS_ADDRESS", "XDG_CURRENT_DESKTOP",
               "XDG_DATA_DIRS", "PATH")


def launch_argv(args):
    if len(args) != 4 or args[:3] != ["-f", "sh", "-c"]:
        return [os.environ["HONEY_REAL_SETSID"], *args]
    argv = [os.environ["HONEY_SYSTEMD_RUN"], "--user", "--collect", "--quiet",
            "--expand-environment=no",
            "--service-type=exec", "--property=PartOf=graphical-session.target",
            "--working-directory=" + str(Path.home())]
    for key in ENVIRONMENT:
        if key in os.environ:
            argv.append("--setenv=" + key + "=" + os.environ[key])
    return [*argv, "--", os.environ["HONEY_SHELL"], "-c", args[3]]


if __name__ == "__main__":
    argv = launch_argv(sys.argv[1:])
    os.execv(argv[0], argv)
