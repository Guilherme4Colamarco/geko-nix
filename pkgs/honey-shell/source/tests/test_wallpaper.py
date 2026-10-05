import copy
import json
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch, Mock
import sys
ROOT=Path(__file__).resolve().parents[1];sys.path.insert(0,str(ROOT))
from core.config import DEFAULTS, validate, wallpaper_dir, wallpaper_state
from services.bridge import wallpapers, action
import cli

class WallpaperTests(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory();self.addCleanup(self.temp.cleanup)
        self.env=patch.dict(os.environ,{'HONEY_MANAGED':'1','XDG_STATE_HOME':self.temp.name,'XDG_CACHE_HOME':self.temp.name,'HOME':self.temp.name})
        self.env.start();self.addCleanup(self.env.stop)
        self.folder=Path(self.temp.name)/'walls';self.folder.mkdir()
        for name in ['b.jpg','a.png','c.webp','d.JPEG','notes.txt','e.svg']:(self.folder/name).write_bytes(b'x')
        self.c=copy.deepcopy(DEFAULTS);self.c['mode']='live';self.c['clipboard']['history']='history.json'
        self.c['wallpaper']['folder']='~/walls'

    def test_folder_is_configurable_and_validated(self):
        self.assertEqual(wallpaper_dir(self.c),self.folder.resolve())
        bad=copy.deepcopy(self.c);bad['wallpaper']['folder']='';self.assertRaises(ValueError,validate,bad)
        bad=copy.deepcopy(self.c);bad['wallpaper']['fit']='zoom';self.assertRaises(ValueError,validate,bad)

    def test_lists_only_images_sorted_and_paginated(self):
        r=wallpapers(self.c,0,3)
        self.assertEqual([x['name'] for x in r['rows']],['a','b','c'])
        self.assertEqual((r['total'],r['pages']),(4,2))
        self.assertEqual([x['name'] for x in wallpapers(self.c,1,3)['rows']],['d'])
        self.assertEqual(wallpapers(self.c,99,3)['page'],1)

    def test_missing_folder_reports_error(self):
        self.c['wallpaper']['folder']='~/nowhere'
        r=wallpapers(self.c)
        self.assertEqual(r['rows'],[]);self.assertIn('indisponível',r['error'])

    def test_pick_is_confined_saved_and_restarts_service(self):
        outside=Path(self.temp.name)/'x.png';outside.write_bytes(b'x')
        self.assertFalse(action('wallpaper',str(outside),self.c,None)['ok'])
        self.assertFalse(action('wallpaper',str(self.folder/'notes.txt'),self.c,None)['ok'])
        with patch('services.bridge.shutil.which',return_value='/bin/systemctl'),patch('services.bridge.subprocess.run',return_value=Mock(returncode=0,stderr=b'')) as run:
            r=action('wallpaper',str(self.folder/'a.png'),self.c,None)
        self.assertTrue(r['ok'])
        self.assertEqual(run.call_args[0][0],['systemctl','--user','restart','honey-wallpaper.service'])
        self.assertEqual(json.loads(wallpaper_state().read_text())['path'],str((self.folder/'a.png').resolve()))
        self.assertTrue([x for x in wallpapers(self.c)['rows'] if x['name']=='a'][0]['current'])

    def test_demo_never_touches_the_system(self):
        self.c['mode']='demo'
        self.assertEqual(wallpaper_dir(self.c),(ROOT/'fixtures').resolve())
        svg=ROOT/'fixtures/wallpaper.svg'
        with patch('services.bridge.subprocess.run',side_effect=AssertionError('run')):
            r=action('wallpaper',str(svg),self.c,None)
        self.assertTrue(r['ok']);self.assertIn('[demo]',r['message']);self.assertFalse(wallpaper_state().exists())

    def test_wallpaper_run_uses_state_or_packaged_fallback(self):
        cfg=copy.deepcopy(self.c)
        with patch('cli.Store') as store,patch('cli.os.execvp') as ex:
            store.return_value.reload.return_value=cfg
            cli.wallpaper_run()
            self.assertEqual(ex.call_args[0][1],['swaybg','-i',str(ROOT/'fixtures/wallpaper.png'),'-m','fill'])
            wallpaper_state().parent.mkdir(parents=True,exist_ok=True)
            wallpaper_state().write_text(json.dumps({'path':str(self.folder/'b.jpg')}))
            cli.wallpaper_run()
            self.assertEqual(ex.call_args[0][1][2],str(self.folder/'b.jpg'))
            self.assertEqual(cli.PANELS['wallpapers'],6)

if __name__=='__main__':unittest.main()
