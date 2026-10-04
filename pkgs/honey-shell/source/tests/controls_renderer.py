#!/usr/bin/env python3
"""Exercise ControlsPanel with real pointer events in an isolated renderer.

Run explicitly with the pinned pleamar and pleamar-wm binaries. This does not
connect to the desktop, audio, brightness, or session/system buses. It produces
numeric records, never previews or screenshots.
"""
import argparse
import json
import os
from pathlib import Path
import re
import shlex
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def fixture(component, available):
    enabled = "true" if available else "false"
    figures = "\n".join(
        f'figure {name} = file "{ROOT / "src/icons" / (name + ".svg")}"'
        for name in ("sun", "volume", "muted")
    )
    return f'''language 0.2
import "{component}"
scene ControlsProbe {{
 surface main {{
 size: full, full; anchor: top; level: top; reserve: -1; rate: 60
 let compact = main.width < 1400
 let sidex = max(main.width * 0.24 - 14, 150)
 let ink = #332000
 let orange = #ff9900
 let deform = 0
 fact controlson = true
 fact controls = 1
 fact control_drop = 1
 fact panel = 2
 fact volume = 0.54
 fact brightness = 0.68
 fact volume_calls = 0
 fact brightness_calls = 0
 fact audioavailable = {enabled}
 fact backlight = {enabled}
 fact muted = false
 text mutelabel = "Som ativo"
 event request
 event volume_set
 event brightness_set
 event mute
 on volume_set {{ volume_calls = volume_calls + 1 }}
 on brightness_set {{ brightness_calls = brightness_calls + 1 }}
 {figures}
 component Honey(x: number, w: number, h: number, motion: number) {{
   box {{ from: x, 0; size: w, h; color: #e7a900 }}
 }}
 ControlsPanel()
 }}
}}
'''


def scenario(scale, available):
    left = max(1920 / scale * 0.24 - 14, 150) - 100
    stages = []
    inputs = []
    time_ms = 5500
    current = {"volume": 0.54, "brightness": 0.68}

    def point(name, kind, relative, pressed=False, release=False, same_calls=False):
        nonlocal time_ms
        level = max(0, min(1, relative / 200))
        if available and (pressed or name.startswith("drag")):
            current[kind] = level
        inputs.append(f"{left + relative:.4f},{138 if kind == 'volume' else 204}@{time_ms}")
        if pressed:
            inputs.append(f"down@{time_ms + 80}")
        if release:
            inputs.append(f"up@{time_ms + 240}")
        stages.append({"name": name, "kind": kind, "expected": current[kind], "same_calls": same_calls})
        time_ms += 450

    for kind in ("volume", "brightness"):
        for relative in (50, 100, 150, 0.1, 199.9):
            point(f"click-{kind}-{relative}", kind, relative, pressed=True, release=True)
        point(f"hold-start-{kind}", kind, 100, pressed=True)
        point(f"hold-still-{kind}", kind, 100, same_calls=True)
        point(f"drag-quarter-{kind}", kind, 50)
        point(f"drag-left-outside-{kind}", kind, -20)
        point(f"drag-right-outside-{kind}", kind, 240)
        point(f"drag-return-{kind}", kind, 150, release=True)
        point(f"outside-click-{kind}", kind, -20, pressed=True, release=True)
        # The click is outside the active track and must preserve the last value.
        stages[-1]["expected"] = 0.75 if available else current[kind]
        current[kind] = stages[-1]["expected"]
        point(f"drag-half-start-{kind}", kind, 50, pressed=True)
        point(f"drag-half-release-{kind}", kind, 100, release=True)
        point(f"drag-quarter-start-{kind}", kind, 150, pressed=True)
        point(f"drag-quarter-release-{kind}", kind, 50, release=True)
    return " ".join(inputs), stages, (time_ms + 700) / 1000


def inspect(log, stages):
    groups = []
    samples = []
    for line in log.splitlines():
        if line.startswith("headless · pointer "):
            if groups:
                groups[-1]["samples"] = samples
            groups.append({"samples": []})
            samples = []
        elif re.match(r"^\d+\.\d+\t", line):
            values = [float(value) for value in line.split("\t")]
            if len(values) == 6:
                samples.append(values)
    if groups:
        groups[-1]["samples"] = samples
    findings = []
    previous = None
    for index, stage in enumerate(stages):
        rows = groups[index]["samples"] if index < len(groups) else []
        row = rows[-1] if rows else None
        column = 2 if stage["kind"] == "volume" else 3
        counter = 4 if stage["kind"] == "volume" else 5
        passed = row is not None and abs(row[column] - stage["expected"]) < 0.002
        if stage["same_calls"]:
            passed = passed and previous is not None and row[counter] == previous[counter]
        findings.append({**stage, "passed": passed, "observed": row[column] if row else None,
                         "calls": row[counter] if row else None})
        previous = row
    return findings


def run(args, scale, available, output):
    label = f"scale-{scale}" if available else "unavailable"
    with tempfile.TemporaryDirectory(prefix="hvol-", dir="/tmp") as directory:
        directory = Path(directory)
        for name in ("home", "config", "cache", "data", "state", "runtime"):
            (directory / name).mkdir()
        (directory / "runtime").chmod(0o700)
        scene = directory / "controls-probe.plm"
        scene.write_text(fixture(args.component, available))
        env = {k: v for k, v in os.environ.items() if not k.startswith(("HONEY_", "PLEAMAR_")) and k not in
               ("LD_LIBRARY_PATH", "WAYLAND_DISPLAY", "DISPLAY", "NIRI_SOCKET", "HYPRLAND_INSTANCE_SIGNATURE")}
        env.update(HOME=str(directory / "home"), XDG_CONFIG_HOME=str(directory / "config"),
                   XDG_CACHE_HOME=str(directory / "cache"), XDG_DATA_HOME=str(directory / "data"),
                   XDG_STATE_HOME=str(directory / "state"), XDG_RUNTIME_DIR=str(directory / "runtime"),
                   PLEAMAR_SOCKETS=str(directory / "ipc"), PLEAMAR_NO_LENS="1",
                   DBUS_SESSION_BUS_ADDRESS="unix:path=" + str(directory / "no-bus"),
                   DBUS_SYSTEM_BUS_ADDRESS="unix:path=" + str(directory / "no-system"),
                   PULSE_SERVER="unix:" + str(directory / "no-audio"),
                   PLEAMAR_HEADLESS_SCALE=str(scale), PLEAMAR_HEADLESS_AT="999",
                   PLEAMAR_HEADLESS_PNG="/dev/null")
        subprocess.run([args.runtime, "--check", str(scene)], env=env, check=True, capture_output=True, text=True)
        inputs, stages, duration = scenario(scale, available)
        autostart = directory / "autostart"
        autostart.write_text(shlex.join([args.runtime, "--scene", str(scene), "--no-hud", "--record",
                                        "pointer.x,volume,brightness,volume_calls,brightness_calls",
                                        "--seconds", str(duration + 8), "--stall", "0"]) + "\n")
        env.update(PLEAMAR_WM_AUTOSTART=str(autostart), PLEAMAR_HEADLESS_INPUT=inputs)
        result = subprocess.run([args.wm, "headless", "--seconds", str(duration), "--stall", "0"],
                                env=env, text=True, capture_output=True, timeout=duration + 30)
        log = result.stdout + result.stderr
        (output / f"{label}.log").write_text(log)
        findings = inspect(log, stages)
        errors = [line for line in log.splitlines() if re.search("panicked|unknown.*property|no free socket", line)]
        passed = result.returncode == 0 and not errors and all(x["passed"] for x in findings)
        report = {"name": label, "passed": passed, "exit_code": result.returncode, "errors": errors, "checks": findings}
        print(label, "PASS" if passed else "FAIL", f"({sum(x['passed'] for x in findings)}/{len(findings)})", flush=True)
        return report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--runtime", required=True)
    parser.add_argument("--wm", required=True)
    parser.add_argument("--component", type=Path, default=ROOT / "src/components/controls.plm")
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--scales", type=float, nargs="+", default=[1, 1.25, 2])
    parser.add_argument("--skip-unavailable", action="store_true")
    args = parser.parse_args()
    args.component = args.component.resolve()
    args.output.mkdir(parents=True, exist_ok=True)
    report = [run(args, scale, True, args.output) for scale in args.scales]
    if not args.skip_unavailable:
        report.append(run(args, 1, False, args.output))
    (args.output / "report.json").write_text(json.dumps(report, indent=2))
    return 0 if all(row["passed"] for row in report) else 1


if __name__ == "__main__":
    raise SystemExit(main())
