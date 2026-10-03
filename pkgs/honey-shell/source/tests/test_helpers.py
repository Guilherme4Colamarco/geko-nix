import copy
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
import sys
ROOT=Path(__file__).resolve().parents[1];sys.path.insert(0,str(ROOT))
from core.config import DEFAULTS, Store, merge, validate, palette
from services.bridge import action, execute, search, history
from adapters.compositor import power_command

class ConfigurationTests(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory(dir=ROOT/'work');self.addCleanup(self.temp.cleanup)
        self.path=Path(self.temp.name)/'user.json';self.store=Store(self.path)
    def test_last_good_survives_partial_write_and_wrong_version(self):
        self.path.write_text('{"version":1,"appearance":{"opacity":0.7}}')
        good=self.store.reload();self.assertEqual(good['appearance']['opacity'],.7)
        for bad in ['{', '{"version":2}', '{"appearance":{"opacity":99}}']:
            self.path.write_text(bad);self.assertEqual(self.store.reload(),good);self.assertTrue(self.store.error)
    def test_layers_and_atomic_settings(self):
        self.store.write({'motion':{'reduced':True},'modules':{'cava':False}})
        value=self.store.reload();self.assertTrue(value['motion']['reduced']);self.assertFalse(value['modules']['cava'])
        self.assertEqual(value['appearance']['base'],'#b97912')
        self.assertIn('spring viscous = 10000',palette(value))
        self.assertFalse(self.path.with_suffix('.tmp').exists())
    def test_demo_cannot_search_outside_workspace(self):
        c=copy.deepcopy(DEFAULTS);c['files']['roots']=['/etc'];self.assertRaises(ValueError,validate,c)
    def test_bad_shader_color_and_nonfinite_rejected(self):
        for bad in ['red','#123; run evil']:
            c=copy.deepcopy(DEFAULTS);c['appearance']['base']=bad;self.assertRaises(ValueError,validate,c)
        c=copy.deepcopy(DEFAULTS);c['motion']['speed']=float('nan');self.assertRaises(ValueError,validate,c)

class LauncherTests(unittest.TestCase):
    def setUp(self):self.c=copy.deepcopy(DEFAULTS);self.store=Store()
    def test_files_names_only_and_no_results(self):
        self.assertEqual(search('files','NOTES',self.c)[0]['name'],'notes.txt')
        self.assertEqual(search('files','Arquivo de teste para',self.c),[])
        self.assertEqual(search('files','does-not-exist-9246',self.c),[])
    def test_emoji_settings_and_clipboard_image(self):
        self.assertEqual(search('emoji','honey',self.c)[0]['value'],'🍯')
        self.assertEqual(search('settings','reduzido',self.c)[0]['value'],'motion.reduced')
        image=search('clipboard','paleta',self.c)[0]
        self.assertTrue(Path(image['preview']).is_file())
    def test_empty_clipboard(self):
        self.c['clipboard']['history']='fixtures/nonexistent.json';self.assertEqual(history(self.c),[])
    def test_malformed_clipboard(self):
        with tempfile.TemporaryDirectory(dir=ROOT/'work') as t:
            p=Path(t)/'history.json';p.write_text('{"bad":1}');self.c['clipboard']['history']=str(p.relative_to(ROOT));self.assertEqual(history(self.c),[])
    def test_demo_actions_never_call_subprocess(self):
        with patch('services.bridge.subprocess.run',side_effect=AssertionError('real action')),patch('services.bridge.subprocess.Popen',side_effect=AssertionError('real command')):
            self.assertTrue(execute('touch /tmp/not-authorized',self.c)['ok'])
            self.assertFalse(execute('false',self.c)['ok'])
            self.assertTrue(action('emoji','🍯',self.c,self.store)['ok'])
            self.assertTrue(action('power','shutdown',self.c,self.store,True)['ok'])
    def test_destructive_power_requires_confirmation(self):
        self.assertFalse(action('power','reboot',self.c,self.store)['ok'])
        self.assertFalse(action('power','shutdown',self.c,self.store)['ok'])
    def test_unknown_actions_and_file_escape(self):
        self.assertFalse(action('file','/etc/passwd',self.c,self.store)['ok'])
        self.assertFalse(action('power','arbitrary',self.c,self.store,True)['ok'])
    def test_command_output_and_error_in_workspace(self):
        self.c['mode']='live'
        self.assertEqual(execute('printf honey',self.c)['message'],'honey')
        self.assertFalse(execute('exit 7',self.c)['ok'])
    def test_missing_compositor_action(self):
        self.c['compositor']='generic'
        self.assertIsNone(power_command('lock',self.c))

if __name__=='__main__':unittest.main()
