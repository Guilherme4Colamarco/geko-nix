#!/usr/bin/env python3
"""Native tray regression test: fake SNI/DBusMenu on a private D-Bus and WM.

Requires python dbus-python + pygobject, dbus-run-session, Pleamar and pleamar-wm.
This is an explicit integration test, outside unittest discovery. It does not
connect to the host's graphical or D-Bus session and produces no screenshots.
"""
import os, json, time, threading, subprocess, shutil, tempfile, shlex, signal
import argparse, sys
from pathlib import Path
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--runtime', default=shutil.which('pleamar'))
parser.add_argument('--wm', default=shutil.which('pleamar-wm'))
parser.add_argument('--source', type=Path, default=Path(__file__).resolve().parents[1])
parser.add_argument('--out', type=Path, required=True)
parser.add_argument('--private-bus', action='store_true', help=argparse.SUPPRESS)
args = parser.parse_args()
if not args.runtime or not args.wm:
    parser.error('Pleamar and pleamar-wm are required')
if not args.private_bus:
    child_env = dict(os.environ)
    child_env.pop('DBUS_SESSION_BUS_ADDRESS', None)
    child_env.pop('LD_LIBRARY_PATH', None)
    raise SystemExit(subprocess.call(['dbus-run-session', '--', sys.executable,
        str(Path(__file__).resolve()), *sys.argv[1:], '--private-bus'], env=child_env))
import dbus, dbus.service, dbus.mainloop.glib
from gi.repository import GLib
BASE=args.out.resolve(); BASE.mkdir(parents=True, exist_ok=True)
SRC=args.source.resolve()
if BASE.is_relative_to(SRC):
    parser.error('--out must be outside the source tree')
RUNTIME=args.runtime
WM=args.wm
passed=[]
dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
bus=dbus.SessionBus()
records=[]
def record(*v):
    records.append(list(v)); (BASE/'dbus-events.json').write_text(json.dumps(records))
class Props(dbus.service.Object):
    @dbus.service.method('org.freedesktop.DBus.Properties',in_signature='ss',out_signature='v')
    def Get(self, interface, name):return self.props[name]
    @dbus.service.method('org.freedesktop.DBus.Properties',in_signature='s',out_signature='a{sv}')
    def GetAll(self, interface):return self.props
class Watcher(Props):
    def __init__(self):
        self.name=dbus.service.BusName('org.kde.StatusNotifierWatcher',bus)
        super().__init__(bus,'/StatusNotifierWatcher')
        self.props={'RegisteredStatusNotifierItems':dbus.Array(['org.honey.TestMenu/StatusNotifierItem','org.honey.TestContext/ContextItem'],signature='s'),'IsStatusNotifierHostRegistered':True,'ProtocolVersion':dbus.Int32(0)}
    @dbus.service.method('org.kde.StatusNotifierWatcher',in_signature='s')
    def RegisterStatusNotifierHost(self, name):record('host',name)
class Item(Props):
    def __init__(self,name,menu):
        self.service=name
        self.name=dbus.service.BusName(name,bus)
        super().__init__(self.name,'/StatusNotifierItem' if menu else '/ContextItem')
        self.props={'Id':name,'Title':name,'Status':'Active','IconName':str(SRC/'src/icons/power.svg'),'Menu':dbus.ObjectPath('/Menu' if menu else '/'),'ItemIsMenu':False}
    @dbus.service.method('org.kde.StatusNotifierItem',in_signature='ii')
    def Activate(self,x,y):record('activate',self.service)
    @dbus.service.method('org.kde.StatusNotifierItem',in_signature='ii')
    def SecondaryActivate(self,x,y):record('secondary',self.service)
    @dbus.service.method('org.kde.StatusNotifierItem',in_signature='ii')
    def ContextMenu(self,x,y):record('context',self.service)
def node(i,label,**props):
    children=props.pop('children',[])
    return dbus.Struct([dbus.Int32(i),dbus.Dictionary(dict(label=label,**props),signature='sv'),dbus.Array(children,signature='v')],signature='ia{sv}av',variant_level=1)
class Menu(dbus.service.Object):
    def __init__(self,name):super().__init__(name,'/Menu')
    @dbus.service.method('com.canonical.dbusmenu',in_signature='i',out_signature='b')
    def AboutToShow(self,i):record('about',i);return False
    @dbus.service.method('com.canonical.dbusmenu',in_signature='iias',out_signature='u(ia{sv}av)')
    def GetLayout(self,i,depth,props):
        record('layout',i)
        rows=[node(1,'_Submenu',children=[node(20,'Disabled child',enabled=False),node(21,'Child action')]),node(2,'Disabled',enabled=False),node(3,'Checked',**{'toggle-type':'checkmark','toggle-state':dbus.Int32(1)})]
        rows += [node(x,f'Action {x}') for x in range(4,15)]
        rows += [node(30,'Hidden',visible=False),node(31,'',type='separator')]
        root=node(0,'',children=rows);return dbus.UInt32(1),dbus.Struct(root,signature='ia{sv}av')
    @dbus.service.method('com.canonical.dbusmenu',in_signature='isvu')
    def Event(self,i,event,data,stamp):record('event',i,event)
watcher=Watcher(); one=Item('org.honey.TestMenu',True); two=Item('org.honey.TestContext',False); menu=Menu(one.name)
loop=GLib.MainLoop(); threading.Thread(target=loop.run,daemon=True).start()
project=BASE/'project'; shutil.copytree(SRC,project,dirs_exist_ok=True)
config=project/'config/user.json'; config.write_text(json.dumps({'version':1,'mode':'live','modules':{'cava':False},'motion':{'reduced':True}}))
env=dict(os.environ)
for k in list(env):
    if k.startswith(('PLEAMAR','HONEY')) or k in ['LD_LIBRARY_PATH','WAYLAND_DISPLAY','DISPLAY','NIRI_SOCKET','HYPRLAND_INSTANCE_SIGNATURE'] :env.pop(k,None)
rt=Path(tempfile.mkdtemp(prefix='tray-',dir='/tmp'));rt.chmod(0o700)
for folder in ['home','config','cache','state','ipc']:(rt/folder).mkdir()
env.update(HOME=str(rt/'home'),XDG_RUNTIME_DIR=str(rt),XDG_CONFIG_HOME=str(rt/'config'),XDG_CACHE_HOME=str(rt/'cache'),XDG_STATE_HOME=str(rt/'state'),PLEAMAR_SOCKETS=str(rt/'ipc'),HONEY_CONFIG=str(config),PLEAMAR_NO_LENS='1',DBUS_SYSTEM_BUS_ADDRESS='unix:path='+str(rt/'no-system-bus'),PULSE_SERVER='unix:'+str(rt/'no-audio'))
cmd=shlex.join(['env','PLEAMAR_SOCKETS='+str(rt/'ipc'),RUNTIME,'--scene',str(project/'src/honey.plm'),'--no-hud','--seconds','75','--stall','0'])
auto=BASE/'autostart';auto.write_text('cd '+shlex.quote(str(project))+' && '+cmd+'\n')
env.update(PLEAMAR_WM_AUTOSTART=str(auto),PLEAMAR_HEADLESS_AT='1000',PLEAMAR_HEADLESS_PNG=str(rt/'unused.png'),PLEAMAR_HEADLESS_INPUT='1514,22@14000 rdown@14100 rup@14200 1514,117@15000 down@15100 up@15200 1514,145@16000 down@16100 up@16200 1514,117@17000 rdown@17100 rup@17200')
log=(BASE/'native.log').open('w'); started=time.monotonic(); proc=subprocess.Popen([WM,'headless','--seconds','75','--stall','0'],env=env,cwd=project,stdout=log,stderr=log,start_new_session=True)
def say(cmd):
    p=subprocess.run([RUNTIME,'--say','honey',cmd],env=env,capture_output=True,text=True,timeout=5)
    if p.returncode:raise AssertionError((cmd,p.stdout,p.stderr))
    return p.stdout.strip()
def check(cond,label):
    if not cond:raise AssertionError(label)
    passed.append(label)
    (BASE/'report.json').write_text(json.dumps({'passed':passed,'screenshots':False,'host_session_touched':False},indent=2))
    print('PASS',label,flush=True)
try:
    for _ in range(50):
        if any(r[0]=='host' for r in records):break
        if proc.poll() is not None:raise AssertionError('WM died '+(BASE/'native.log').read_text()[-3000:])
        time.sleep(.25)
    check(any(r[0]=='host' for r in records),'native tray watcher connected to private bus')
    time.sleep(1)
    say('emit tray_action 0');time.sleep(.2)
    check(any(r[0]=='activate' for r in records),'left click uses Activate despite DBusMenu presence')
    say('emit tray_secondary 0');time.sleep(.2)
    check(any(r[0]=='secondary' for r in records),'middle click uses SecondaryActivate')
    for _ in range(70):
        if any(r[0]=='layout' for r in records):break
        time.sleep(.2)
    check(say('get panel')=='3','native pointer right click on compact app opens tray panel from idle')
    check(any(r[0]=='about' for r in records) and any(r[0]=='layout' for r in records),'native menu AboutToShow and GetLayout')
    for _ in range(20):
        if 'Submenu' in say('get traytitle'):break
        time.sleep(.1)
    check('Submenu' in say('get traytitle'),'native pointer left click opens submenu')
    say('emit tray_click 0');time.sleep(.2)
    check(not any(r[0]=='event' for r in records),'disabled submenu action blocked')
    for _ in range(25):
        if ['event',21,'clicked'] in records:break
        time.sleep(.1)
    check(['event',21,'clicked'] in records,'native pointer left click forwards exact DBusMenu submenu id')
    layouts=sum(r[0]=='layout' for r in records)
    for _ in range(50):
        if sum(r[0]=='layout' for r in records)>layouts:break
        time.sleep(.2)
    check(sum(r[0]=='layout' for r in records)>layouts,'native pointer right click on expanded app opens its menu')
    say('emit tray_click 6');time.sleep(.2)
    say('emit tray_click 6');time.sleep(.2)
    check(['event',12,'clicked'] in records,'pagination preserves actions beyond eighth item')
    say('emit tray_context 1')
    for _ in range(30):
        if any(r[0]=='context' for r in records):break
        time.sleep(.1)
    check(say('get panel')=='0','Honey overlay closed before native ContextMenu delegation')
    check(any(r[0]=='context' for r in records),'SNI without DBusMenu invokes ContextMenu')
    say('emit tray_context 0');time.sleep(.2)
    say('emit tray_click 0');time.sleep(.2)
    say('emit tray_back');time.sleep(.2)
    check('org.honey.TestMenu' in say('get traytitle'),'back returns to parent menu')
    say('emit tray_back');time.sleep(.2)
    check(say('get traytitle')=='Tray','back returns to app list')
    check(not any('error' in x.lower() and 'luau' in x.lower() for x in (BASE/'native.log').read_text().splitlines()),'Luau runtime has no errors')
finally:
    os.killpg(proc.pid,signal.SIGTERM)
    try:proc.wait(timeout=5)
    except subprocess.TimeoutExpired:os.killpg(proc.pid,signal.SIGKILL)
    loop.quit();log.close();shutil.rmtree(rt,ignore_errors=True)
