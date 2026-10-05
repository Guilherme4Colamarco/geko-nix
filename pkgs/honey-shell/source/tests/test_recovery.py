import copy
import os
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import Mock, patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from core.config import DEFAULTS
from services import bridge


class EndLoop(Exception):
    pass


class RecoveryTests(unittest.TestCase):
    def test_file_open_uses_independent_service_and_literal_path(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / '$literal with spaces.txt'
            path.write_text('test')
            cfg = copy.deepcopy(DEFAULTS)
            cfg['mode'] = 'live'
            cfg['files']['roots'] = [directory]
            with patch.dict(os.environ, {'HONEY_MANAGED': '1'}), \
                 patch('services.bridge.shutil.which', side_effect=lambda x: '/store/' + x), \
                 patch('services.bridge.call', return_value={'ok': True}) as call:
                self.assertTrue(bridge.action('file', str(path), cfg, Mock())['ok'])
            argv = call.call_args.args[0]
            self.assertEqual(argv[0], '/store/systemd-run')
            self.assertIn('--expand-environment=no', argv)
            self.assertIn('--property=PartOf=graphical-session.target', argv)
            self.assertEqual(argv[-3:], ['--', '/store/xdg-open', str(path)])

    def run_clipboard_loop(self, initial_failure=False):
        cfg = copy.deepcopy(DEFAULTS)
        cfg['mode'] = 'live'
        cfg['modules']['cava'] = False
        store = Mock(current=cfg, path=Path('/nonexistent-honey-test-path'))
        store.reload.return_value = cfg
        dead = Mock(); dead.poll.return_value = 1
        alive = Mock(); alive.poll.return_value = None
        outcomes = [OSError('compositor unavailable'), alive] if initial_failure else [dead, alive]
        now = [0]
        launches = []

        def launch(*args, **kwargs):
            launches.append(now[0])
            result = outcomes[len(launches) - 1]
            if isinstance(result, Exception):
                raise result
            return result

        def sleep(_):
            now[0] += 1
            if now[0] == 5:
                raise EndLoop()

        with patch('services.bridge.snapshot', return_value={}), \
             patch('services.bridge.output'), patch('services.bridge.history', return_value=[]), \
             patch('services.bridge.managed', return_value=False), \
             patch('services.bridge.shutil.which', return_value='/store/wl-paste'), \
             patch('services.bridge.subprocess.Popen', side_effect=launch), \
             patch('services.bridge.time.monotonic', side_effect=lambda: now[0]), \
             patch('services.bridge.time.sleep', side_effect=sleep):
            with self.assertRaises(EndLoop):
                bridge.stream(store)
        alive.terminate.assert_called_once()
        return launches

    def test_clipboard_recovers_after_exit_without_busy_loop(self):
        self.assertEqual(self.run_clipboard_loop(), [0, 3])

    def test_clipboard_recovers_after_spawn_failure(self):
        self.assertEqual(self.run_clipboard_loop(initial_failure=True), [0, 2])


if __name__ == '__main__':
    unittest.main()
