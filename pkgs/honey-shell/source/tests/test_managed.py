import copy
import json
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch, Mock
import sys
ROOT=Path(__file__).resolve().parents[1];sys.path.insert(0,str(ROOT))
from core.config import DEFAULTS, Store, validate, history_path, image_path, write_palette
from services.bridge import history, action, search, execute, ddc_read, capture
import cli

class ManagedTests(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory();self.addCleanup(self.temp.cleanup)
        self.env=patch.dict(os.environ,{'HONEY_MANAGED':'1','XDG_STATE_HOME':self.temp.name,'XDG_CACHE_HOME':self.temp.name,'HOME':self.temp.name})
        self.env.start();self.addCleanup(self.env.stop)
        self.c=copy.deepcopy(DEFAULTS);self.c['mode']='live';self.c['clipboard']['history']='history.json'
    def test_paths_and_empty_history(self):
        self.assertEqual(history_path(self.c),Path(self.temp.name)/'honey/history.json')
        self.assertEqual(history(self.c),[])
        self.c['clipboard']['history']='../escape';self.assertRaises(ValueError,validate,self.c)
    def test_preferences_immutable_and_palette_never_written(self):
        with patch('core.config.atomic_text',side_effect=AssertionError('write')):write_palette(self.c)
        self.assertRaises(ValueError,Store().write,{'mode':'demo'})
        result=action('setting','motion.reduced',self.c,Store())
        self.assertFalse(result['ok']);self.assertIn('Home Manager',result['message'])
        self.assertIn('Home Manager',search('settings','cava',self.c)[0]['detail'])
    def test_clear_text_and_images_without_touching_source(self):
        h=history_path(self.c);h.parent.mkdir(parents=True)
        pic=image_path('clipboard/a.png');pic.parent.mkdir();pic.write_bytes(b'PNG')
        h.write_text(json.dumps([{'id':'a','label':'img','kind':'image','value':'clipboard/a.png'},{'id':'b','label':'bad','kind':'image','value':'../../etc/passwd'}]))
        self.assertEqual(len(history(self.c)),1)
        self.assertTrue(action('clear','',self.c,Store())['ok'])
        self.assertFalse(pic.exists());self.assertEqual(history(self.c),[])
    def test_plain_text_only_clipboard_offer(self):
        responses=[Mock(stdout='text/plain\n',returncode=0),Mock(stdout='mel 🍯'.encode(),returncode=0)]
        with patch('services.bridge.subprocess.run',side_effect=responses) as run:
            capture(self.c)
        self.assertEqual(run.call_args_list[1].args[0][-1],'text/plain')
        self.assertEqual(history(self.c)[0]['value'],'mel 🍯')
    def test_command_uses_home(self):
        self.assertEqual(execute('pwd',self.c)['message'].strip(),self.temp.name)
    def test_control_allowlist_and_open(self):
        with patch('cli.run') as run:
            self.assertEqual(cli.main(['open','clipboard']),0)
            self.assertEqual(run.call_args.args[0],['pleamar','--say','honey','emit control 115'])
            self.assertEqual(cli.main(['toggle','controls']),0)
            self.assertEqual(run.call_args.args[0][-1],'emit control 2')
            run.reset_mock();self.assertEqual(cli.main(['toggle','arbitrary;command']),2);run.assert_not_called()
    def test_missing_ddc_and_demo_safety(self):
        with patch('services.bridge.shutil.which',return_value=None):self.assertFalse(ddc_read()['available'])
        c=copy.deepcopy(self.c);c['mode']='demo'
        with patch('services.bridge.subprocess.run',side_effect=AssertionError('hardware')):
            self.assertTrue(action('brightness',.8,c,Store())['ok'])
    def test_suspend_locks_before_power(self):
        with patch('cli.lock') as lock,patch('cli.run') as run:
            calls=Mock();calls.attach_mock(lock,'lock');calls.attach_mock(run,'run')
            cli.main(['suspend']);self.assertEqual(str(calls.mock_calls),'[call.lock(), call.run([\'systemctl\', \'suspend\'])]')
        with patch('cli.lock',side_effect=RuntimeError('lock failed')),patch('cli.run') as run:
            self.assertRaises(RuntimeError,cli.main,['suspend']);run.assert_not_called()

if __name__=='__main__':unittest.main()
