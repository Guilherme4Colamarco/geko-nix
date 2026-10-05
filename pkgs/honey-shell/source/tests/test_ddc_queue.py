"""Exercise the actual Luau handlers with isolated services and controlled timers."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
LUAU = os.environ.get("HONEY_LUAU") or shutil.which("luau")
HARNESS = r'''
local handlers, timers, calls, nativeCalls = {}, {}, {}, {}
local stream
fact = {demo=false, backlight=true, audioavailable=true, brightness=0.5, volume=0.5, panel=0}
text = {}
model = {}
function on(name, callback) handlers[name] = callback end
function after(ms, callback) timers[#timers+1] = {ms=ms, callback=callback} end
function log(...) end
function focus(...) end
function emit(...) end
json = {encode=function(value) return value end, decode=function(value) return value end}
sys = {
    call=function(name, value) nativeCalls[#nativeCalls+1] = {name=name, value=value} end,
    watch=function(...) return false end,
}
function run(program, args, done)
    assert(program == "python3" and args[1] == "services/bridge.py")
    calls[#calls+1] = {payload=args[3], done=done}
end
function spawn(program, args, callback, done) stream=callback end
local function tick()
    local timer = table.remove(timers, 1)
    assert(timer and timer.ms == 80, "expected one DDC debounce")
    timer.callback()
end
'''


@unittest.skipUnless(LUAU, "set HONEY_LUAU to run isolated Luau regressions")
class DdcQueueTests(unittest.TestCase):
    def check_luau(self, scenario):
        source = HARNESS + "\n" + (ROOT / "src/honey.luau").read_text() + "\n" + scenario
        with tempfile.TemporaryDirectory() as directory:
            script = Path(directory) / "regression.luau"
            script.write_text(source)
            result = subprocess.run([LUAU, str(script)], capture_output=True, text=True, timeout=10)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_last_value_wins_without_concurrent_writes(self):
        self.check_luau(r'''
handlers.brightness_set(0.2)
handlers.brightness_set(0.4)
handlers.brightness_set(0.7)
assert(#timers == 1 and #calls == 0)
stream({type="brightness", available=true, level=0.1})
assert(fact.brightness == 0.7, "background read overwrote pending user input")
tick()
assert(#calls == 1 and calls[1].payload.value == 0.7)
handlers.brightness_set(0.1)
handlers.brightness_set(0.3)
handlers.brightness_set(0.9)
assert(#calls == 1 and #timers == 0, "parallel DDC operation")
stream({type="brightness", available=true, level=0.1})
assert(fact.brightness == 0.9)
calls[1].done({ok=true, message="first"}, 0)
assert(#calls == 2 and calls[2].payload.value == 0.9)
calls[2].done({ok=true, message="last"}, 0)
assert(#calls == 2 and text.status == "last")
stream({type="brightness", available=true, level=0.8})
assert(fact.brightness == 0.8, "reads did not resume after write completion")
''')

    def test_failure_still_flushes_latest_pending_value(self):
        self.check_luau(r'''
handlers.brightness_set(-1)
tick()
assert(calls[1].payload.value == 0)
handlers.brightness_set(5)
assert(fact.brightness == 1 and #calls == 1)
calls[1].done("helper failed", 1)
assert(#calls == 2 and calls[2].payload.value == 1)
calls[2].done({ok=false, message="monitor unavailable"}, 0)
assert(text.status == "monitor unavailable")
handlers.brightness_set(0.6)
tick()
assert(#calls == 3 and calls[3].payload.value == 0.6, "queue remained blocked")
''')

    def test_unavailable_or_demo_cancels_pending_write(self):
        self.check_luau(r'''
handlers.brightness_set(0.2)
fact.backlight = false
tick()
assert(#calls == 0)
handlers.brightness_set(0.8)
assert(#timers == 0 and fact.brightness == 0.2)
fact.backlight = true
handlers.brightness_set(0.4)
fact.demo = true
tick()
assert(#calls == 0)
handlers.brightness_set(0.6)
assert(fact.brightness == 0.6 and #calls == 0 and #timers == 0)
''')

    def test_volume_bounds_and_unavailable_audio(self):
        self.check_luau(r'''
handlers.volume_set(-1)
handlers.volume_set(5)
assert(#nativeCalls == 2)
assert(nativeCalls[1].name == "audio.volume" and nativeCalls[1].value == 0)
assert(nativeCalls[2].value == 1)
fact.audioavailable = false
handlers.volume_set(0.5)
assert(#nativeCalls == 2 and fact.volume == 1)
''')
