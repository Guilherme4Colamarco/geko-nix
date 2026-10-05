import fcntl
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch, Mock
ROOT=Path(__file__).resolve().parents[1];sys.path.insert(0,str(ROOT))
import cli

class CliTests(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory();self.addCleanup(self.temp.cleanup)
        env={'XDG_RUNTIME_DIR':self.temp.name,'XDG_STATE_HOME':self.temp.name,'HOME':self.temp.name,'HONEY_MANAGED':'1'}
        self.env=patch.dict(os.environ,env);self.env.start();self.addCleanup(self.env.stop)

    def test_lock_skips_when_already_locked(self):
        with patch('cli.lock_active',return_value=True),patch('cli.subprocess') as sp,patch('cli.run') as run:
            cli.lock();sp.run.assert_not_called();sp.Popen.assert_not_called();run.assert_not_called()
    def test_lock_runs_swaylock_and_monitor(self):
        with patch('cli.lock_active',return_value=False),patch('cli.subprocess.run') as sp,patch('cli.subprocess.Popen') as popen,patch('cli.run') as run:
            self.assertEqual(cli.main(['lock']),0)
        self.assertEqual(sp.call_args.args[0],['pleamar','--say','honey','emit lock_state 1'])
        self.assertEqual(run.call_args.args[0],['swaylock','--daemonize']);self.assertEqual(popen.call_args.args[0],['honeyctl','lock-monitor'])
    def test_lock_failure_clears_locked_fact_and_reraises(self):
        with patch('cli.lock_active',return_value=False),patch('cli.subprocess.run') as sp,patch('cli.subprocess.Popen') as popen,\
             patch('cli.run',side_effect=subprocess.CalledProcessError(1,'swaylock')):
            self.assertRaises(subprocess.CalledProcessError,cli.lock)
        self.assertEqual(sp.call_args.args[0],['pleamar','--say','honey','emit lock_state 0']);popen.assert_not_called()

    def test_session_returns_when_another_instance_holds_lock(self):
        root=Path(self.temp.name)/'honey';root.mkdir()
        with (root/'session.lock').open('w') as f:
            fcntl.flock(f,fcntl.LOCK_EX)
            with patch('cli.run') as run:cli.session();run.assert_not_called()
    def test_session_stops_target_when_compositor_is_gone(self):
        with patch('cli.run') as run,patch('cli.subprocess.run') as sp,patch('cli.socket.socket') as sock,patch('cli.signal.signal'):
            sock.return_value.connect.side_effect=OSError('gone')
            cli.session()
        starts=[c.args[0] for c in run.call_args_list]
        self.assertIn(['systemctl','--user','start','honey-session.target'],starts)
        self.assertEqual(sp.call_args.args[0],['systemctl','--user','stop','honey-session.target'])

    def test_screenshot_niri_delegates_to_compositor(self):
        with patch.dict(os.environ,{'NIRI_SOCKET':'/s'}),patch('cli.run') as run:
            cli.main(['screenshot','screen']);self.assertEqual(run.call_args.args[0],['niri','msg','action','screenshot-screen'])
            cli.main(['screenshot']);self.assertEqual(run.call_args.args[0],['niri','msg','action','screenshot'])
    def test_screenshot_region_cancelled_does_nothing(self):
        env=dict(os.environ);env.pop('NIRI_SOCKET',None);env['XDG_CURRENT_DESKTOP']='Hyprland'
        with patch.dict(os.environ,env,clear=True),patch('cli.subprocess.run',return_value=Mock(returncode=1,stdout='')) as sp,patch('cli.run') as run:
            cli.screenshot(True);run.assert_not_called();self.assertEqual(sp.call_args.args[0],['slurp'])
    def test_screenshot_screen_captures_and_copies(self):
        env=dict(os.environ);env.pop('NIRI_SOCKET',None);env['XDG_CURRENT_DESKTOP']='Hyprland'
        def fake(argv,**kw):
            if argv[0]=='grim':Path(argv[-1]).write_bytes(b'PNG')
        with patch.dict(os.environ,env,clear=True),patch('cli.run',side_effect=fake) as run:
            cli.screenshot(False)
        self.assertEqual(run.call_args_list[0].args[0][0],'grim');self.assertTrue(run.call_args_list[0].args[0][-1].startswith(self.temp.name))
        self.assertEqual(run.call_args_list[1].args[0],['wl-copy','--type','image/png']);self.assertEqual(run.call_args_list[1].kwargs['input'],b'PNG')

    def test_media_commands_use_fixed_argv(self):
        with patch('cli.run') as run:
            self.assertEqual(cli.main(['media','mute']),0);self.assertEqual(run.call_args.args[0],['wpctl','set-mute','@DEFAULT_AUDIO_SINK@','toggle'])
            cli.main(['media','play-pause']);self.assertEqual(run.call_args.args[0],['playerctl','play-pause'])
            self.assertRaises(ValueError,cli.main,['media','rm -rf'])
    def test_media_brightness_prefers_backlight_then_ddc(self):
        with patch('cli.Path.exists',return_value=True),patch('cli.Path.iterdir',return_value=iter([Path('x')])),patch('cli.run') as run:
            cli.main(['media','brightness-up']);self.assertEqual(run.call_args.args[0],['brightnessctl','set','5%+'])
        with patch('cli.Path.exists',return_value=False),patch('services.bridge.ddc_read',return_value={'available':True,'level':.5}),\
             patch('services.bridge.ddc_set',return_value={'ok':True,'message':'ok'}) as ddc_set,patch('cli.run') as run:
            self.assertEqual(cli.main(['media','brightness-down']),0);self.assertAlmostEqual(ddc_set.call_args.args[0],.45);run.assert_not_called()
        with patch('cli.Path.exists',return_value=False),patch('services.bridge.ddc_read',return_value={'available':False}):
            self.assertEqual(cli.main(['media','brightness-up']),1)

if __name__=='__main__':unittest.main()
