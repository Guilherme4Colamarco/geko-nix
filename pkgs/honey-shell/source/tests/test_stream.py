import copy
import fcntl
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch, Mock
ROOT=Path(__file__).resolve().parents[1];sys.path.insert(0,str(ROOT))
from core.config import DEFAULTS, Store
from services import bridge

class EndLoop(Exception):pass

def run_stream(cfg,ticks=3,which=lambda x:'/store/'+x,popen=None,history=None,sig=lambda c:(1,2),store=None):
    out=[];n=[0]
    store=store or Mock(current=cfg,path=Path('/nonexistent-honey-test-path'));store.reload.return_value=cfg
    def sleep(_):
        n[0]+=1
        if n[0]>=ticks:raise EndLoop()
    with patch('services.bridge.snapshot',return_value={'type':'config'}),patch('services.bridge.output',side_effect=out.append),\
         patch('services.bridge.history',history or Mock(return_value=[])),patch('services.bridge.history_sig',side_effect=sig),\
         patch('services.bridge.managed',return_value=False),patch('services.bridge.shutil.which',side_effect=which),\
         patch('services.bridge.subprocess.Popen',popen or Mock(return_value=Mock(poll=Mock(return_value=None)))),\
         patch('services.bridge.time.sleep',side_effect=sleep):
        try:bridge.stream(store)
        except EndLoop:pass
    return out

def live():
    c=copy.deepcopy(DEFAULTS);c['mode']='live';c['modules']['cava']=True;return c

class StreamTests(unittest.TestCase):
    def test_missing_cava_reports_once_and_stream_survives(self):
        cfg=live();popen=Mock(side_effect=AssertionError('no spawn'))
        out=run_stream(cfg,which=lambda x:None,popen=popen)
        self.assertEqual([p for p in out if p.get('type')=='cava'],[{'type':'cava','bars':[0]*12,'error':'Cava indisponível'}])

    def test_stop_escalates_to_kill_after_timeout(self):
        proc=Mock();proc.poll.return_value=None;proc.wait.side_effect=[subprocess.TimeoutExpired('cava',2),0]
        bridge.stop(proc)
        proc.terminate.assert_called_once();proc.kill.assert_called_once();self.assertEqual(proc.wait.call_count,2)
        done=Mock();done.poll.return_value=0;bridge.stop(done);done.terminate.assert_not_called();bridge.stop(None)

    def test_stream_stops_children_with_terminate(self):
        cava=Mock();cava.poll.return_value=None
        r,w=os.pipe();cava.stdout.fileno.return_value=r
        self.addCleanup(os.close,r);self.addCleanup(os.close,w)
        with patch('services.bridge.cache_dir',return_value=Path(tempfile.mkdtemp())),patch('services.bridge.ROOT',Path(tempfile.mkdtemp())):
            run_stream(live(),popen=Mock(return_value=cava))
        cava.terminate.assert_called()

    def test_cava_partial_lines_are_buffered(self):
        r,w=os.pipe();self.addCleanup(os.close,r);self.addCleanup(os.close,w)
        cava=Mock();cava.poll.return_value=None;cava.stdout.fileno.return_value=r
        os.write(w,b'100;200;3');out=[];cfg=live();n=[0]
        store=Mock(current=cfg,path=Path('/nonexistent-honey-test-path'));store.reload.return_value=cfg
        def sleep(_):
            n[0]+=1
            if n[0]==1:os.write(w,b'00\n500;')
            if n[0]>=2:raise EndLoop()
        with patch('services.bridge.snapshot',return_value={}),patch('services.bridge.output',side_effect=out.append),patch('services.bridge.history',return_value=[]),\
             patch('services.bridge.history_sig',return_value=None),patch('services.bridge.managed',return_value=False),patch('services.bridge.shutil.which',side_effect=lambda x:'/s/'+x),\
             patch('services.bridge.subprocess.Popen',return_value=cava),patch('services.bridge.time.sleep',side_effect=sleep),\
             patch('services.bridge.cache_dir',return_value=Path(tempfile.mkdtemp())),patch('services.bridge.ROOT',Path(tempfile.mkdtemp())):
            try:bridge.stream(store)
            except EndLoop:pass
        bars=[p['bars'] for p in out if p.get('type')=='cava']
        self.assertEqual(len(bars),1);self.assertEqual(bars[0],[.1,.2,.3])

    def test_snapshot_survives_palette_error_and_keeps_last_good(self):
        with tempfile.TemporaryDirectory() as d,patch.dict(os.environ,{'HONEY_CONFIG':str(Path(d)/'user.json')}):
            store=Store();good=store.reload();Path(d,'user.json').write_text(json.dumps({'motion':{'reduced':True}}))
            with patch('services.bridge.write_palette',side_effect=ValueError('palette recusada')):
                packet=bridge.snapshot(store)
            self.assertEqual(packet['error'],'palette recusada');self.assertEqual(packet['config'],good);self.assertEqual(store.current,good)

    def test_clipboard_packet_is_small_and_history_parsed_only_on_change(self):
        items=[{'id':str(i),'kind':'text','label':'x'*80,'value':'y'*500} for i in range(100)]
        history=Mock(return_value=items);sigs=iter([(5,9),(5,9),(6,9)])
        out=run_stream(live(),ticks=4,which=lambda x:None,history=history,sig=lambda c:next(sigs,(6,9)))
        packets=[p for p in out if p.get('type')=='clipboard']
        self.assertEqual(packets,[{'type':'clipboard','n':100,'stamp':'5:9'},{'type':'clipboard','n':100,'stamp':'6:9'}])
        self.assertEqual(history.call_count,2);self.assertLess(len(json.dumps(packets[0])),80)

class SearchCapacityTests(unittest.TestCase):
    def test_clipboard_keeps_clear_slot_with_small_capacity(self):
        cfg=live();items=[{'id':str(i),'kind':'text','label':'item','value':'item'} for i in range(10)]
        with patch('services.bridge.history',return_value=items):
            for cap in (1,2,3,7):
                rows=bridge.search('clipboard','',cfg,cap)
                self.assertEqual(len(rows),cap);self.assertEqual(rows[-1]['id'],'clear')
            rows=bridge.search('clipboard','item',cfg,3);self.assertEqual([r['id'] for r in rows],['0','1','2'])
    def test_capacity_payload_is_clamped(self):
        self.assertEqual(bridge._capacity({}),7);self.assertEqual(bridge._capacity({'capacity':'x'}),7)
        self.assertEqual(bridge._capacity({'capacity':0}),1);self.assertEqual(bridge._capacity({'capacity':999}),50)

class DdcCacheTests(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory();self.addCleanup(self.temp.cleanup)
        patcher=patch('services.bridge.cache_dir',return_value=Path(self.temp.name));patcher.start();self.addCleanup(patcher.stop)
        self.reset();self.addCleanup(self.reset)
    def reset(self):bridge._ddc_bus=None;bridge._ddc_retry_at=0
    def test_bus_persists_across_processes_until_ttl(self):
        detect=Mock(returncode=0,stdout='I2C bus:  /dev/i2c-7\n',stderr='');vcp=Mock(returncode=0,stdout='VCP 10 C 30 100',stderr='')
        run=Mock(side_effect=lambda argv,**kw:detect if argv[1]=='detect' else vcp)
        with patch('services.bridge.shutil.which',return_value='ddcutil'),patch('services.bridge.subprocess.run',run):
            self.assertTrue(bridge.ddc_read()['available']);self.reset();self.assertTrue(bridge.ddc_read()['available'])
            self.assertEqual(sum(c.args[0][1]=='detect' for c in run.call_args_list),1)
            self.reset();data=json.loads((Path(self.temp.name)/'ddc-bus.json').read_text());data['at']-=bridge._DDC_TTL+1
            (Path(self.temp.name)/'ddc-bus.json').write_text(json.dumps(data));bridge.ddc_read()
            self.assertEqual(sum(c.args[0][1]=='detect' for c in run.call_args_list),2)
    def test_failure_retry_is_persisted_for_new_processes(self):
        fail=Mock(returncode=1,stdout='',stderr='')
        with patch('services.bridge.shutil.which',return_value='ddcutil'),patch('services.bridge.subprocess.run',return_value=fail) as run:
            bridge.ddc_read();self.reset();self.assertFalse(bridge.ddc_read()['available'])
        self.assertEqual(run.call_count,1)
    def test_ddc_set_and_read_share_one_lock(self):
        with (Path(self.temp.name)/'ddc.lock').open('w') as f:
            fcntl.flock(f,fcntl.LOCK_EX)
            clock=iter(range(0,1000))
            with patch('services.bridge.shutil.which',return_value='ddcutil'),patch('services.bridge.subprocess.run',side_effect=AssertionError('second ddcutil')),\
                 patch('services.bridge.time.monotonic',side_effect=lambda:next(clock)),patch('services.bridge.time.sleep'):
                self.assertTrue(bridge.ddc_read()['busy']);self.assertFalse(bridge.ddc_set(.5)['ok'])

if __name__=='__main__':unittest.main()
