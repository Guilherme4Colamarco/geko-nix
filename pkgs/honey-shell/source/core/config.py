"""Versioned configuration; workspace-only persistence and last-good reload."""
import copy
import json
import math
import os
import re
import shutil
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEFAULTS = {
    'version': 1, 'preset': 'Honey', 'mode': 'demo',
    'modules': {'cava': True, 'controls': True, 'clock': True, 'tray': True, 'power': True, 'wallpaper': True, 'notifications': True},
    'layout': {'spacing': 14, 'central_width': 620, 'panel_height': 550, 'reserve': 0},
    'appearance': {'base': '#b97912', 'highlight': '#ffdb85', 'ink': '#fff0ca', 'input': '#ffad28',
                   'opacity': .66, 'glass': .72, 'refraction': .75, 'blur': .6, 'glow': .08,
                   'shadow': .22, 'thickness': 1.0, 'rounding': 40, 'drops': 3},
    'motion': {'viscosity': 1.0, 'speed': 1.0, 'elasticity': 1.0, 'bounce': .6,
               'deformation': 1.0, 'life': 1.0, 'groove': .5, 'reduced': False},
    'files': {'roots': ['fixtures'], 'limit': 1000},
    'clipboard': {'history': 'fixtures/clipboard.json'},
    'cava': {'bars': 12, 'rate': 30},
    'wallpaper': {'folder': '~/Imagens/Wallpapers', 'fit': 'fill'},
    'notifications': {'timeout': 6, 'low_timeout': 3, 'max_visible': 3, 'dnd': False, 'sound': False, 'sound_file': ''},
    'compositor': 'auto', 'power': {'lock_command': []},
}

def managed():
    return os.environ.get('HONEY_MANAGED') == '1'


def state_dir():
    return Path(os.environ.get('XDG_STATE_HOME') or Path.home()/'.local/state')/'honey'


def cache_dir():
    return Path(os.environ.get('XDG_CACHE_HOME') or Path.home()/'.cache')/'honey'


def user_path(value):
    return Path(os.path.expandvars(os.path.expanduser(value)))


def history_path(c):
    return (state_dir()/c['clipboard']['history']).resolve() if managed() else (ROOT/c['clipboard']['history']).resolve()


def image_path(value):
    return (state_dir()/value).resolve() if managed() else (ROOT/value).resolve()


def wallpaper_dir(c):
    # Demo only browses the project's fixtures; live uses the configured folder.
    if c['mode']=='demo': return (ROOT/'fixtures').resolve()
    folder=user_path(c['wallpaper']['folder'])
    return (folder if folder.is_absolute() else ROOT/folder).resolve()


def sound_path(c):
    # Only a file the user names, never a directory or an arbitrary relative path.
    f=c['notifications']['sound_file']
    if not f: return None
    p=user_path(f)
    return p.resolve() if p.is_absolute() and p.suffix.lower() in ('.oga','.ogg','.wav','.flac','.mp3') else None


def wallpaper_state():
    return state_dir()/'wallpaper.json'


def merge(base, overlay):
    result = copy.deepcopy(base)
    for key, value in overlay.items():
        if isinstance(value, dict) and isinstance(result.get(key), dict):
            result[key] = merge(result[key], value)
        else:
            result[key] = copy.deepcopy(value)
    return result


def validate(c):
    if not isinstance(c, dict): raise ValueError('configuração deve ser um objeto')
    if c.get('version') != 1: raise ValueError('versão de configuração não suportada')
    if c.get('mode') not in ('demo', 'live'): raise ValueError('mode deve ser demo ou live')
    if c.get('preset') != 'Honey': raise ValueError('preset desconhecido')
    if c.get('compositor') not in ('auto', 'pleamar-wm', 'hyprland', 'niri', 'generic'):
        raise ValueError('compositor desconhecido')
    for section in ['modules', 'layout', 'appearance', 'motion', 'files', 'clipboard', 'cava', 'power', 'wallpaper', 'notifications']:
        if not isinstance(c.get(section), dict): raise ValueError(f'{section} deve ser objeto')
    for k, v in c['modules'].items():
        if k not in DEFAULTS['modules'] or type(v) is not bool: raise ValueError('módulo inválido')
    for k in ['base', 'highlight', 'ink', 'input']:
        if not re.fullmatch(r'#[0-9a-fA-F]{6}', str(c['appearance'][k])): raise ValueError('cor inválida: '+k)
    limits = {'layout': {'spacing':(0,50),'central_width':(380,1000),'panel_height':(400,800),'reserve':(0,100)},
              'appearance': {'opacity':(.2,1),'glass':(0,1),'refraction':(0,2),'blur':(0,1),'glow':(0,.5),'shadow':(0,.8),'thickness':(.5,2),'rounding':(10,100),'drops':(0,5)},
              'motion': {'viscosity':(.4,3),'speed':(.4,3),'elasticity':(.4,2),'bounce':(0,1),'deformation':(0,2),'life':(0,2),'groove':(0,1)},
              'files': {'limit':(1,10000)}, 'cava': {'bars':(12,12),'rate':(1,30)}}
    for sec, fields in limits.items():
        for key, (low,high) in fields.items():
            v=c[sec][key]
            if type(v) not in (int,float) or not math.isfinite(v) or not low <= v <= high:
                raise ValueError(f'{sec}.{key} fora dos limites')
    if type(c['motion']['reduced']) is not bool: raise ValueError('reduced deve ser booleano')
    if not isinstance(c['wallpaper'].get('folder'),str) or not c['wallpaper']['folder']: raise ValueError('wallpaper.folder inválido')
    n=c['notifications']
    for k,(lo,hi) in {'timeout':(1,60),'low_timeout':(1,30),'max_visible':(1,3)}.items():
        v=n.get(k)
        if type(v) not in (int,float) or not math.isfinite(v) or not lo<=v<=hi: raise ValueError(f'notifications.{k} fora dos limites')
    if type(n.get('dnd')) is not bool or type(n.get('sound')) is not bool: raise ValueError('notifications.dnd e sound devem ser booleanos')
    if not isinstance(n.get('sound_file'),str): raise ValueError('notifications.sound_file inválido')
    if c['wallpaper'].get('fit') not in ('fill','fit','center','tile','stretch'): raise ValueError('wallpaper.fit inválido')
    roots=c['files']['roots']
    if not isinstance(roots,list) or not all(isinstance(x,str) and x for x in roots): raise ValueError('roots inválido')
    history=c['clipboard']['history']
    if not isinstance(history,str) or not history or not history_path(c).is_relative_to(state_dir().resolve() if managed() else ROOT):
        raise ValueError('histórico de clipboard fora da pasta permitida')
    if not isinstance(c['power']['lock_command'],list) or not all(isinstance(x,str) for x in c['power']['lock_command']):
        raise ValueError('lock_command deve ser lista de argumentos')
    if c['mode']=='demo' and any(not (ROOT/x).resolve().is_relative_to(ROOT) for x in roots):
        raise ValueError('demo só pesquisa arquivos do projeto')
    return c


class Store:
    def __init__(self, path=None):
        self.path=Path(path or os.environ.get('HONEY_CONFIG') or ROOT/'config/user.json')
        self.current=copy.deepcopy(DEFAULTS)
        self.error=''
    def reload(self):
        try:
            user=json.loads(self.path.read_text()) if self.path.exists() else {}
            preset=json.loads((ROOT/'presets/Honey.json').read_text())
            c=validate(merge(merge(DEFAULTS,preset),user))
            self.current=c;self.error=''
        except (OSError,ValueError,KeyError,TypeError) as e:
            self.error=str(e)
        return copy.deepcopy(self.current)
    def write(self, patch):
        if managed(): raise ValueError("Gerenciado pelo Home Manager")
        old=json.loads(self.path.read_text()) if self.path.exists() else {}
        user=merge(old,patch)
        preset=json.loads((ROOT/'presets/Honey.json').read_text())
        validate(merge(merge(DEFAULTS,preset),user))
        self.path.parent.mkdir(parents=True,exist_ok=True)
        tmp=self.path.with_suffix('.tmp');tmp.write_text(json.dumps(user,ensure_ascii=False,indent=2)+'\n');tmp.replace(self.path)
        return self.reload()


def palette(c):
    a=c['appearance'];m=c['motion'];l=c['layout']
    stiffness=160*m['speed']**2/m['viscosity'];damping=14*m['speed']*(1.5-m['bounce']*.65)/m['elasticity']
    if m['reduced']: stiffness,damping=10000,200
    values={'darkink':'#281a0c','honey':a['base'],'gold':a['highlight'],'ink':a['ink'],'orange':a['input'],
            'tint':a['opacity'],'glassiness':a['glass'],'refract':a['refraction'],'frost':a['blur'],
            'shade':a['shadow'],'thickness':a['thickness'],'roundness':a['rounding'],
            'dropcount':a['drops'],'deform':0 if m['reduced'] else m['deformation'],'life':0 if m['reduced'] else m['life'],
            'grooveamt':0 if m['reduced'] or not c['modules']['cava'] else m['groove'],
            'dispersion':round(.03+.05*a['refraction'],3),'dome':round(.1*a['thickness'],3),'ripple':.3,'warn':'#ffbc82',
            'panelwidth':l['central_width'],'panelheight':l['panel_height'],'spacing':l['spacing'],'reserve':l['reserve']}
    lines=['// Generated from validated workspace configuration.','library HoneyTheme {']
    lines += [f'    let {k} = {v}' for k,v in values.items()]
    lines += [f'    spring viscous = {stiffness:.3f}, {damping:.3f}', f'    spring droplet = {stiffness*.65:.3f}, {damping*.75:.3f}',
               f'    spring blob = {stiffness*.4:.3f}, {damping*.6:.3f}', f'    spring drip = {stiffness*.22:.3f}, {damping*.45:.3f}', '}']
    return '\n'.join(lines)+'\n'


def atomic_text(path, value):
    path=Path(path)
    with tempfile.NamedTemporaryFile(mode='w',dir=path.parent,prefix=path.name+'.',delete=False) as f:
        f.write(value);temp=Path(f.name)
    temp.replace(path)


def write_palette(c):
    if managed() and os.environ.get("HONEY_BUILD") != "1": return
    changes={ROOT/'src/themes/active.plm':palette(c)}
    material=ROOT/'src/components/material.plm'
    # `rim` only takes a literal percentage in Pleamar, so it cannot be a theme token.
    if material.exists():
        changes[material]=re.sub(r'rim: [0-9.]+%',f'rim: {c["appearance"]["glow"]*100:.3f}%',material.read_text())
    scene=ROOT/'src/honey.plm'
    reservation=ROOT/'src/reserve.plm'
    if reservation.exists():
        changes[reservation]=re.sub(r'reserve: [0-9.]+;',f'reserve: {c["layout"]["reserve"]};',reservation.read_text(),count=1)
    originals={}
    for path,value in changes.items():
        previous=path.read_text() if path.exists() else None
        if previous!=value:
            originals[path]=previous;atomic_text(path,value)
    runtime=shutil.which('pleamar')
    if originals and scene.exists() and runtime:
        check=subprocess.run([runtime,'--check',str(scene)],capture_output=True,text=True)
        if check.returncode:
            for path,previous in originals.items():
                if previous is None:path.unlink(missing_ok=True)
                else:atomic_text(path,previous)
            raise ValueError('Tokens rejeitados pelo Pleamar: '+check.stdout+check.stderr)
