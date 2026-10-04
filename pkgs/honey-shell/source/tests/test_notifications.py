import copy
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch, Mock
import sys
ROOT=Path(__file__).resolve().parents[1];sys.path.insert(0,str(ROOT))
from core.config import DEFAULTS, validate, sound_path
from services.bridge import action
import cli

class NotificationTests(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory();self.addCleanup(self.temp.cleanup)
        self.env=patch.dict(os.environ,{'HONEY_MANAGED':'1','XDG_STATE_HOME':self.temp.name,'XDG_CACHE_HOME':self.temp.name,'HOME':self.temp.name})
        self.env.start();self.addCleanup(self.env.stop)
        self.c=copy.deepcopy(DEFAULTS);self.c['mode']='live';self.c['clipboard']['history']='history.json'
        self.sound=Path(self.temp.name)/'ding.oga';self.sound.write_bytes(b'x')

    def test_defaults_are_valid_and_the_panel_is_enabled(self):
        validate(self.c);self.assertTrue(self.c['modules']['notifications']);self.assertFalse(self.c['notifications']['sound'])

    def test_limits_and_types_are_enforced(self):
        for key,value in (('timeout',0),('timeout',61),('low_timeout',0),('max_visible',4),('max_visible',float('nan')),('dnd','yes'),('sound',1),('sound_file',5)):
            bad=copy.deepcopy(self.c);bad['notifications'][key]=value
            self.assertRaises(ValueError,validate,bad)

    def test_sound_file_must_be_an_absolute_audio_file(self):
        self.c['notifications']['sound_file']=str(self.sound);self.assertEqual(sound_path(self.c),self.sound.resolve())
        for bad in ('','ding.oga','/etc/passwd',str(Path(self.temp.name))):
            self.c['notifications']['sound_file']=bad;self.assertIsNone(sound_path(self.c))

    def test_sound_plays_only_when_asked_live_and_not_in_dnd(self):
        self.c['notifications'].update(sound=True,sound_file=str(self.sound))
        with patch('services.bridge.shutil.which',return_value='/bin/pw-play'),patch('services.bridge.subprocess.Popen') as popen:
            self.assertTrue(action('sound','',self.c,None)['ok']);self.assertEqual(popen.call_args.args[0],['/bin/pw-play',str(self.sound.resolve())])
        for change in ({'sound':False},{'dnd':True}):
            quiet=copy.deepcopy(self.c);quiet['notifications'].update(change)
            with patch('services.bridge.subprocess.Popen') as popen:
                self.assertEqual(action('sound','',quiet,None)['message'],'sem som');popen.assert_not_called()
        demo=copy.deepcopy(self.c);demo['mode']='demo'
        with patch('services.bridge.subprocess.Popen') as popen:
            action('sound','',demo,None);popen.assert_not_called()

    def test_missing_player_or_file_reports_instead_of_raising(self):
        self.c['notifications'].update(sound=True,sound_file=str(self.sound))
        with patch('services.bridge.shutil.which',return_value=None):self.assertFalse(action('sound','',self.c,None)['ok'])
        self.c['notifications']['sound_file']=str(Path(self.temp.name)/'gone.oga')
        self.assertFalse(action('sound','',self.c,None)['ok'])

    def test_cli_panel_and_dnd_commands(self):
        self.assertEqual(cli.PANELS['notifications'],7)
        with patch('cli.subprocess.run') as run:
            for arg,code in (('on','1'),('off','0'),('toggle','2')):
                run.reset_mock();self.assertEqual(cli.main(['dnd',arg]),0)
                self.assertEqual(run.call_args.args[0],['pleamar','--say','honey','emit dnd '+code])
        with patch('cli.subprocess.run') as run:
            self.assertEqual(cli.main(['dnd','maybe']),2);run.assert_not_called()

if __name__=='__main__':unittest.main()
