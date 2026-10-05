import copy
from pathlib import Path
import sys
import unittest
ROOT=Path(__file__).resolve().parents[1];sys.path.insert(0,str(ROOT))
from core.config import DEFAULTS, validate, palette
sys.path.insert(0,str(ROOT/'tests'))
import test_ddc_queue as ddc
LUAU=ddc.LUAU

FIRE = r'''
local function fire(ms)
    for i, t in ipairs(timers) do
        if t.ms == ms then table.remove(timers, i); t.callback(); return end
    end
    error("no timer of " .. ms .. " ms")
end
local function pending(ms)
    for _, t in ipairs(timers) do if t.ms == ms then return true end end
    return false
end
'''


class GrooveConfigTests(unittest.TestCase):
    def test_groove_is_validated_and_reaches_the_theme(self):
        c=copy.deepcopy(DEFAULTS);validate(c)
        self.assertIn('let grooveamt = 0.5',palette(c))
        for bad in (-0.1,1.5,'x',float('nan')):
            b=copy.deepcopy(c);b['motion']['groove']=bad;self.assertRaises(ValueError,validate,b)

    def test_reduced_motion_or_cava_off_stops_the_dance(self):
        for change in (('motion','reduced',True),('modules','cava',False)):
            c=copy.deepcopy(DEFAULTS);c[change[0]][change[1]]=change[2]
            self.assertIn('let grooveamt = 0\n',palette(c))

    def test_cava_rate_is_fast_enough_for_a_beat(self):
        self.assertGreaterEqual(DEFAULTS['cava']['rate'],24)


@unittest.skipUnless(LUAU, "set HONEY_LUAU to run isolated Luau regressions")
class NotchLuauTests(unittest.TestCase):
    check_luau = ddc.DdcQueueTests.check_luau

    def test_external_volume_change_shows_the_drop_then_hides(self):
        self.check_luau(FIRE + r'''
fact.muted = false; fact.volosd = 0
audio_changed(0.5, false)
assert(fact.volosd == 0, "the first report at startup is not a change")
audio_changed(0.6, false)
assert(fact.volosd == 1 and fact.volume == 0.6)
audio_changed(0.65, false)
fire(1500)
assert(fact.volosd == 1, "a newer change must restart the timer")
fire(1500)
assert(fact.volosd == 0)
audio_changed(0.65, true)
assert(fact.volosd == 1 and fact.muted and text.mutelabel == "Silenciado", "external mute also shows")
''')

    def test_own_slider_and_mute_do_not_show_the_drop(self):
        self.check_luau(FIRE + r'''
fact.muted = false; fact.volosd = 0
audio_changed(0.5, false)
handlers.volume_set(0.3)
audio_changed(0.31, false)
assert(fact.volosd == 0, "echo of our own slider")
handlers.mute()
audio_changed(0.31, true)
assert(fact.volosd == 0, "echo of our own mute")
fire(500); fire(500)
audio_changed(0.4, true)
assert(fact.volosd == 1, "after the window, changes count as external again")
''')

    def test_no_drop_while_the_controls_panel_is_open(self):
        self.check_luau(FIRE + r'''
fact.muted = false; fact.volosd = 0
audio_changed(0.5, false)
fact.panel = 2
audio_changed(0.9, false)
assert(fact.volosd == 0 and fact.volume == 0.9 and not pending(1500))
''')

    def test_beat_follows_the_bass_and_decays(self):
        self.check_luau(r'''
stream({type="cava", bars={1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0}})
assert(fact.beat == 1)
stream({type="cava", bars={0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1}})
assert(math.abs(fact.beat - 0.8) < 1e-6, "treble alone does not keep the beat")
for _ = 1, 40 do stream({type="cava", bars={0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}}) end
assert(fact.beat == 0, "silence settles to exactly 0 so the body stops repainting")
''')

    def test_cava_panel_no_longer_opens(self):
        self.check_luau(r'''
fact.target = 0; fact.cavaon = true
handlers.request(5)
assert(fact.panel == 0 and fact.target == 0)
''')


if __name__=='__main__':unittest.main()
