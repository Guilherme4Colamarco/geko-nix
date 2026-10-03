"""Small allow-listed session and IPC interface, shared by the three compositors."""
import fcntl
import json
import os
from pathlib import Path
import socket
import signal
import subprocess
import sys
import time
from core.config import Store, state_dir
from services.bridge import action

PANELS={'launcher':10,'apps':10,'files':11,'commands':12,'settings':13,'emoji':14,'clipboard':15,'controls':2,'tray':3,'power':4,'close':0}

def run(argv, **kwargs):
    return subprocess.run(argv,check=True,**kwargs)

def lock_active():
    # Nix may wrap swaylock in an ELF launcher. /proc/exe identifies the actual
    # locker; its truncated process name is not necessarily "swaylock".
    for proc in Path('/proc').iterdir():
        if not proc.name.isdigit(): continue
        try:
            if proc.stat().st_uid == os.getuid() and (proc/'exe').resolve().name in ('swaylock','.swaylock-wrapped'):
                return True
        except OSError: pass
    return False

def lock():
    # swaylock returns from --daemonize only after the compositor has locked.
    # Serialize attempts and accept an already-running lock only if owned by us.
    root=Path(os.environ['XDG_RUNTIME_DIR'])/'honey';root.mkdir(mode=0o700,exist_ok=True)
    with (root/'lock.lock').open('w') as f:
        fcntl.flock(f,fcntl.LOCK_EX)
        if lock_active():return
        subprocess.run(['makoctl','mode','-a','locked'],check=False)
        try:
            log=state_dir()/'lock.log';log.parent.mkdir(parents=True,exist_ok=True)
            with log.open('a') as output:
                run(['swaylock','--daemonize'],stdin=subprocess.DEVNULL,stdout=output,stderr=subprocess.STDOUT)
        except Exception:
            subprocess.run(['makoctl','mode','-r','locked'],check=False);raise
        subprocess.Popen(['honeyctl','lock-monitor'],start_new_session=True,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)

def screenshot(region):
    desktop=os.environ.get('XDG_CURRENT_DESKTOP','').lower()
    if os.environ.get('NIRI_SOCKET') or 'niri' in desktop:
        run(['niri','msg','action','screenshot' if region else 'screenshot-screen']);return
    root=Path.home()/'Imagens/Capturas';root.mkdir(parents=True,exist_ok=True)
    path=root/(time.strftime('%Y-%m-%d_%H-%M-%S')+'-'+str(time.time_ns()%1000000)+'.png')
    args=['grim']
    if region:
        selection=subprocess.run(['slurp'],capture_output=True,text=True)
        if selection.returncode:return
        args+=['-g',selection.stdout.strip()]
    run(args+[str(path)],timeout=15)
    run(['wl-copy','--type','image/png'],input=path.read_bytes(),stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL,timeout=5)

def session():
    root=Path(os.environ['XDG_RUNTIME_DIR'])/'honey';root.mkdir(mode=0o700,exist_ok=True)
    with (root/'session.lock').open('w') as f:
        try:fcntl.flock(f,fcntl.LOCK_EX|fcntl.LOCK_NB)
        except BlockingIOError:return
        (Path.home()/'Imagens/Capturas').mkdir(parents=True,exist_ok=True)
        variables=['PATH','DISPLAY','WAYLAND_DISPLAY','XDG_CURRENT_DESKTOP','XDG_SESSION_TYPE','XDG_SESSION_DESKTOP','XDG_SESSION_ID','HYPRLAND_INSTANCE_SIGNATURE','NIRI_SOCKET','PLEAMAR_WM_SOCKET']
        values=[k+'='+os.environ[k] for k in variables if os.environ.get(k)]
        # A persistent user manager may retain variables from another compositor.
        run(['systemctl','--user','unset-environment']+variables[1:])
        run(['dbus-update-activation-environment','--systemd']+values)
        wayland=os.environ.get('WAYLAND_DISPLAY','wayland-0')
        address=wayland if wayland.startswith('/') else str(Path(os.environ['XDG_RUNTIME_DIR'])/wayland)
        signal.signal(signal.SIGTERM,lambda *_: sys.exit(0))
        try:
            run(['systemctl','--user','start','honey-session.target'])
            while True:
                # A connect failure proves the compositor has gone; do not drive input.
                probe=socket.socket(socket.AF_UNIX);probe.settimeout(2)
                try:probe.connect(address)
                except OSError:break
                finally:probe.close()
                time.sleep(1)
        finally:subprocess.run(['systemctl','--user','stop','honey-session.target'])

def main(args=None):
    args=list(sys.argv[1:] if args is None else args)
    cmd=args[0] if args else 'help'
    if cmd in ('toggle','open') and len(args)==2 and args[1] in PANELS:
        code=PANELS[args[1]]
        if cmd=='open':code+=100
        run(['pleamar','--say','honey','emit control '+str(code)])
    elif cmd=='lock-monitor':
        while lock_active():time.sleep(.5)
        subprocess.run(['makoctl','mode','-r','locked'],check=False)
    elif cmd=='lock':lock()
    elif cmd=='suspend':lock();run(['systemctl','suspend'])
    elif cmd=='session':session()
    elif cmd=='screenshot':screenshot(len(args)<2 or args[1]!='screen')
    elif cmd=='clear-clipboard':
        result=action('clear','',Store().reload(),Store());print(json.dumps(result));return 0 if result['ok'] else 1
    elif cmd=='media' and len(args)==2:
        media={'volume-up':['wpctl','set-volume','-l','1.0','@DEFAULT_AUDIO_SINK@','5%+'],'volume-down':['wpctl','set-volume','@DEFAULT_AUDIO_SINK@','5%-'],'mute':['wpctl','set-mute','@DEFAULT_AUDIO_SINK@','toggle'],'mic-mute':['wpctl','set-mute','@DEFAULT_AUDIO_SOURCE@','toggle'],'play-pause':['playerctl','play-pause'],'next':['playerctl','next'],'previous':['playerctl','previous']}
        if args[1] in media:run(media[args[1]])
        elif args[1] in ('brightness-up','brightness-down'):
            from services.bridge import ddc_read,ddc_set
            if Path('/sys/class/backlight').exists() and any(Path('/sys/class/backlight').iterdir()):run(['brightnessctl','set','5%+' if args[1]=='brightness-up' else '5%-'])
            else:
                reading=ddc_read()
                result=ddc_set(reading.get('level',0)+(.05 if args[1]=='brightness-up' else -.05)) if reading['available'] else {'ok':False,'message':'Brilho indisponível'}
                print(result['message']);return 0 if result['ok'] else 1
        else:raise ValueError('Ação de mídia desconhecida')
    else:
        print('honeyctl toggle|open '+ '|'.join(PANELS)+'; lock; suspend; screenshot region|screen; clear-clipboard; media ACTION')
        return 0 if cmd=='help' else 2
    return 0

if __name__=='__main__':
    try:sys.exit(main())
    except (OSError,ValueError,subprocess.SubprocessError) as e:print('Honey: '+str(e),file=sys.stderr);sys.exit(1)
