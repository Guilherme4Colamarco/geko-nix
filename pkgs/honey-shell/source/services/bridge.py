#!/usr/bin/env python3
"""JSON boundary for helpers outside Pleamar's built-in platform services."""
import argparse
import contextlib
import copy
import fcntl
import re
import hashlib
import json
import math
import os
from pathlib import Path
import queue
import select
import shlex
import shutil
import subprocess
import sys
import threading
import time

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT))
from core.config import sound_path, Store, write_palette, managed, state_dir, cache_dir, history_path, image_path, user_path, atomic_text, wallpaper_dir, wallpaper_state
from adapters.compositor import capabilities, power_command
from services.app_scope import service_argv

EMOJI=[('🍯','mel honey'),('🐝','abelha bee'),('✨','brilho sparkle'),('🧡','coração heart'),('🌙','lua moon'),('☀️','sol sun'),('🎵','música music'),('✅','confirmar check'),('🔥','fogo fire'),('🌿','folha leaf')]
SETTINGS=[('motion.reduced','Movimento reduzido','Alternar animações'),('modules.cava','Cava','Ativar/desativar visualizador'),('modules.tray','Tray','Ativar/desativar tray'),('appearance.glass','Transparência do mel','Alternar material sólido/translúcido'),('motion.bounce','Elasticidade','Alternar balanço suave/expressivo')]

def output(value):print(json.dumps(value,ensure_ascii=False),flush=True)
def row(id,label,detail='',kind='text',value='',preview=''):
    return dict(id=id,name=label,detail=detail,kind=kind,value=value,preview=preview)

def history(config):
    p=history_path(config)
    try:
        data=json.loads(p.read_text())
        if not isinstance(data,list):return []
        clean=[]
        for item in data[:100]:
            if not isinstance(item,dict) or item.get('kind') not in ('text','image'):continue
            if not all(isinstance(item.get(k),str) for k in ['id','label','value']):continue
            if item['kind']=='image' and not image_path(item['value']).is_relative_to(state_dir().resolve() if managed() else ROOT):continue
            clean.append(item)
        return clean
    except (OSError,ValueError):return []

def search(mode,query,config,cap=7):
    q=query.casefold();result=[];cap=max(1,cap)
    if mode=='files':
        count=0
        for root in config['files']['roots']:
            base=(user_path(root) if managed() else ROOT/root).resolve()
            if not base.is_dir():continue
            for parent, dirs, files in os.walk(base,followlinks=False):
                dirs[:]=sorted(d for d in dirs if not d.startswith('.') and not (Path(parent)/d).is_symlink())
                for name in sorted(files):
                    count+=1
                    if count>config['files']['limit']:return result[:cap]
                    path=Path(parent)/name
                    if path.is_symlink():continue
                    if q in name.casefold():result.append(row(str(path),name,str(path.parent),'file',str(path)))
                    if len(result)==cap:return result
    elif mode=='emoji':
        result=[row(icon,icon+'  '+label,'Copiar emoji','emoji',icon) for icon,label in EMOJI if q in label.casefold() or q in icon][:cap]
    elif mode=='settings':
        result=[row(key,name,('Gerenciado pelo Home Manager · '+str(config[key.split('.')[0]][key.split('.')[1]])) if managed() else detail,'setting',key) for key,name,detail in SETTINGS if q in (key+' '+name).casefold()][:cap]
    elif mode=='clipboard':
        clear=not q or q in 'limpar histórico clipboard'
        result=[row(x['id'],x['label'],'Imagem' if x['kind']=='image' else 'Texto','clipboard',x['id'],str(image_path(x['value'])) if x['kind']=='image' else '') for x in history(config) if q in (x['label']+' '+(x['value'] if x['kind']=='text' else '')).casefold()][:cap-1 if clear else cap]
    if mode=='clipboard' and clear:
        result=result[:cap-1]+[row('clear','Limpar histórico','Remover textos e imagens armazenados','clear','')]
    return result

def execute(command,config):
    if config['mode']=='demo':
        if command.strip()=='false':return {'ok':False,'message':'[demo] comando terminou com código 1','code':1}
        return {'ok':True,'message':'[demo] comando recebido: '+command,'code':0}
    if not command.strip():return {'ok':False,'message':'Digite um comando.'}
    try:
        # Explicit command mode uses a shell, never the general search modes.
        p=subprocess.Popen([os.environ.get('HONEY_SHELL','/bin/sh'),'-c',command],cwd=Path.home() if managed() else ROOT,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,start_new_session=True)
        try:
            out,_=p.communicate(timeout=10)
        except subprocess.TimeoutExpired:
            import signal
            os.killpg(p.pid,signal.SIGKILL);out,_=p.communicate()
            return {'ok':False,'message':'Tempo limite de 10 s.\n'+out[:4096].decode(errors='replace'),'code':124}
        return {'ok':p.returncode==0,'message':out[:4096].decode(errors='replace') or f'Código de saída: {p.returncode}','code':p.returncode}
    except OSError as e:return {'ok':False,'message':str(e)}

def call(argv,config,stdin=None):
    if config['mode']=='demo':return {'ok':True,'message':'[demo] '+shlex.join(argv)}
    if not argv or not shutil.which(argv[0]):return {'ok':False,'message':'Recurso indisponível: '+(argv[0] if argv else 'ação')}
    try:
        p=subprocess.run(argv,input=stdin,capture_output=True,timeout=5,cwd=ROOT)
        return {'ok':p.returncode==0,'message':p.stderr[:2048].decode(errors='replace') or ('Concluído' if p.returncode==0 else f'Código {p.returncode}')}
    except (OSError,subprocess.TimeoutExpired) as e:return {'ok':False,'message':str(e)}

WALL_EXT={'.png','.jpg','.jpeg','.webp'}
def wallpaper_current():
    try:return json.loads(wallpaper_state().read_text()).get('path','')
    except (OSError,ValueError,AttributeError):return ''

def wallpapers(config,page=0,cap=12):
    d=wallpaper_dir(config)
    ext=WALL_EXT|({'.svg'} if config['mode']=='demo' else set())
    try:files=sorted((p for p in d.iterdir() if p.is_file() and p.suffix.lower() in ext),key=lambda p:p.name.lower())
    except OSError:return {'rows':[],'page':0,'pages':0,'total':0,'folder':str(d),'error':'Pasta indisponível: '+str(d)}
    pages=max(1,-(-len(files)//cap));page=max(0,min(int(page),pages-1));cur=wallpaper_current()
    rows=[{'path':str(p),'name':p.stem,'current':str(p)==cur} for p in files[page*cap:(page+1)*cap]]
    return {'rows':rows,'page':page,'pages':pages,'total':len(files),'folder':str(d)}

def notify_sound(config):
    n=config['notifications']
    if config['mode']!='live' or not n['sound'] or n['dnd']:return {'ok':True,'message':'sem som'}
    p=sound_path(config)
    if not p or not p.is_file():return {'ok':False,'message':'Arquivo de som indisponível.'}
    player=shutil.which('pw-play') or shutil.which('paplay')
    if not player:return {'ok':False,'message':'Recurso indisponível: pw-play'}
    try:subprocess.Popen([player,str(p)],stdin=subprocess.DEVNULL,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL,start_new_session=True)
    except OSError as e:return {'ok':False,'message':str(e)}
    return {'ok':True,'message':'som'}

def action(kind,value,config,store,confirmed=False):
    if kind=='clear':
        if config['mode']=='demo':return {'ok':True,'message':'[demo] limpar histórico'}
        h=history_path(config);h.parent.mkdir(parents=True,exist_ok=True)
        with (h.parent/'clipboard.lock').open('w') as lock:
            fcntl.flock(lock,fcntl.LOCK_EX)
            for item in history(config):
                if item['kind']=='image':image_path(item['value']).unlink(missing_ok=True)
            atomic_text(h,'[]')
        return {'ok':True,'message':'Histórico limpo'}
    if kind=='brightness':
        return ddc_set(value) if config['mode']=='live' else {'ok':True,'message':'[demo] brilho'}
    if kind=='command':return execute(value,config)
    if kind=='file':
        p=Path(value).resolve()
        if not p.is_file() or not any(p.is_relative_to((user_path(r) if managed() else ROOT/r).resolve()) for r in config['files']['roots']):return {'ok':False,'message':'Arquivo fora das pastas de busca.'}
        if config['mode']=='demo':return call(['xdg-open',str(p)],config)
        opener=shutil.which('xdg-open')
        if not opener:return {'ok':False,'message':'Recurso indisponível: xdg-open'}
        return call(service_argv([opener,str(p)]),config)
    if kind=='emoji':return call(['wl-copy','--type','text/plain'],config,value.encode())
    if kind=='clipboard':
        item=next((x for x in history(config) if x['id']==value),None)
        if not item:return {'ok':False,'message':'Item de clipboard não está mais disponível.'}
        if item['kind']=='image':
            p=image_path(item['value'])
            if not p.is_file():return {'ok':False,'message':'Imagem indisponível.'}
            return call(['wl-copy','--type','image/png' if p.suffix=='.png' else 'image/svg+xml'],config,p.read_bytes())
        return call(['wl-copy','--type','text/plain'],config,item['value'].encode())
    if kind=='setting':
        if managed():return {'ok':False,'message':'Gerenciado pelo Home Manager: edite programs.honeyShell.settings no flake.'}
        if value not in [x[0] for x in SETTINGS]:return {'ok':False,'message':'Ajuste desconhecido.'}
        sec,key=value.split('.');old=config[sec][key]
        new=(not old) if isinstance(old,bool) else (0.0 if old>0 else (.72 if key=='glass' else .6))
        c=store.write({sec:{key:new}});write_palette(c)
        return {'ok':True,'message':'Ajuste atualizado: '+value,'config':c}
    if kind=='sound':return notify_sound(config)
    if kind=='wallpaper':
        p=Path(value).resolve();d=wallpaper_dir(config)
        if not p.is_file() or not p.is_relative_to(d) or p.suffix.lower() not in WALL_EXT|({'.svg'} if config['mode']=='demo' else set()):return {'ok':False,'message':'Imagem fora da pasta de wallpapers.'}
        if config['mode']=='demo':return {'ok':True,'message':'[demo] wallpaper '+p.stem,'path':str(p)}
        state=wallpaper_state();state.parent.mkdir(parents=True,exist_ok=True);atomic_text(state,json.dumps({'path':str(p)},ensure_ascii=False))
        r=call(['systemctl','--user','restart','honey-wallpaper.service'],config);r['path']=str(p)
        if r['ok']:r['message']='Wallpaper: '+p.stem
        return r
    if kind=='power':
        if value not in ['lock','suspend','logout','reboot','shutdown']:return {'ok':False,'message':'Ação desconhecida.'}
        if value in ['reboot','shutdown'] and not confirmed:return {'ok':False,'message':'Confirmação necessária.'}
        if config['mode']=='demo':return {'ok':True,'message':'[demo] '+value+' — nenhuma ação no sistema'}
        cmd=power_command(value,config)
        return call(cmd,config) if cmd else {'ok':False,'message':'Ação indisponível neste compositor.'}
    return {'ok':False,'message':'Ação desconhecida.'}

def snapshot(store):
    previous=copy.deepcopy(store.current);config=store.reload();error=store.error
    if not error:
        try:write_palette(config)
        except (ValueError,OSError) as e:
            # Keep the last good config; the stream must outlive a palette that cannot be applied.
            store.current=previous;config=copy.deepcopy(previous);error=str(e)
    return {'type':'config','config':config,'error':error,'capabilities':capabilities(config),'fixture_icon':str(ROOT/'fixtures/honey.svg'),'managed':managed()}

def capture(config):
    """Called only by wl-paste --watch in explicitly enabled live mode."""
    if config['mode']!='live':return
    types=subprocess.run(['wl-paste','--list-types'],capture_output=True,text=True,timeout=2).stdout
    offered=types.splitlines()
    mime='image/png' if 'image/png' in offered else next((t for t in offered if t.lower() in ('text/plain;charset=utf-8','text/plain','utf8_string')),None)
    if mime is None:return
    p=subprocess.run(['wl-paste','--no-newline','--type',mime],capture_output=True,timeout=2)
    data=p.stdout
    if p.returncode or not data or len(data)>8*1024*1024:return
    digest=hashlib.sha256(data).hexdigest()
    if mime=='image/png':
        dest=(state_dir()/'clipboard' if managed() else ROOT/'work/clipboard')/f'{digest}.png';dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(data)
        item={'id':digest,'kind':'image','label':'Imagem do clipboard','value':str(dest.relative_to(state_dir() if managed() else ROOT))}
    else:
        value=data.decode(errors='replace');item={'id':digest,'kind':'text','label':value[:80].replace('\n',' '),'value':value}
    h=history_path(config);h.parent.mkdir(parents=True,exist_ok=True)
    with (h.parent/'clipboard.lock').open('w') as lock:
        fcntl.flock(lock,fcntl.LOCK_EX)
        entries=[item]+[x for x in history(config) if x['id']!=digest]
        expired=entries[100:]
        atomic_text(h,json.dumps(entries[:100],ensure_ascii=False))
        for old in expired:
            if old['kind']=='image':image_path(old['value']).unlink(missing_ok=True)

# DDC bus discovery is cached in the process and in cache_dir() (every `bridge.py action` is a new process).
# Never assume a bus number; a cached bus expires after _DDC_TTL and is dropped on any read failure.
# On this NVIDIA, ddcutil holds the DRM i2c bus long enough to stall frames.
# A failed probe must not immediately scan again (_DDC_RETRY, also persisted).
_ddc_bus=None
_ddc_retry_at=0
_DDC=['--disable-dynamic-sleep','--maxtries=1,1,1']
_DDC_TTL=900
_DDC_RETRY=120

def _ddc_cache():return cache_dir()/'ddc-bus.json'
def _ddc_cache_read():
    try:
        data=json.loads(_ddc_cache().read_text())
        return data if isinstance(data,dict) else {}
    except (OSError,ValueError):return {}
def _ddc_cache_write(**data):
    try:
        _ddc_cache().parent.mkdir(parents=True,exist_ok=True);atomic_text(_ddc_cache(),json.dumps(data))
    except OSError:pass
def _ddc_fail():
    global _ddc_bus,_ddc_retry_at
    _ddc_bus=None;_ddc_retry_at=time.monotonic()+_DDC_RETRY;_ddc_cache_write(fail_until=time.time()+_DDC_RETRY)

@contextlib.contextmanager
def _ddc_lock(timeout=6):
    """One ddcutil per i2c bus: shared by ddc_read, ddc_set and concurrent helper processes."""
    try:
        d=cache_dir();d.mkdir(parents=True,exist_ok=True);f=(d/'ddc.lock').open('w')
    except OSError:
        yield True;return
    with f:
        end=time.monotonic()+timeout;got=False
        while True:
            try:fcntl.flock(f,fcntl.LOCK_EX|fcntl.LOCK_NB);got=True;break
            except OSError:
                if time.monotonic()>=end:break
                time.sleep(.05)
        try:yield got
        finally:
            if got:fcntl.flock(f,fcntl.LOCK_UN)

def _ddc_find():
    global _ddc_bus,_ddc_retry_at
    if _ddc_bus is not None:return _ddc_bus
    if time.monotonic()<_ddc_retry_at:return None
    c=_ddc_cache_read();wall=time.time()
    try:
        if isinstance(c.get('bus'),str) and re.fullmatch(r'\d+',c['bus']) and 0<=wall-float(c.get('at',0))<_DDC_TTL:
            _ddc_bus=c['bus'];return _ddc_bus
        remaining=float(c.get('fail_until',0))-wall
    except (TypeError,ValueError):remaining=0
    if 0<remaining<=_DDC_RETRY:
        _ddc_retry_at=time.monotonic()+remaining;return None
    p=subprocess.run(['ddcutil','detect','--brief',*_DDC],capture_output=True,text=True,timeout=4)
    buses=re.findall(r'I2C bus:\s*/dev/i2c-(\d+)',p.stdout) or re.findall(r'/dev/i2c-(\d+)',p.stdout)
    if not buses:_ddc_fail();return None
    _ddc_bus=buses[0];_ddc_cache_write(bus=_ddc_bus,at=wall)
    return _ddc_bus

def _ddc_read_locked():
    if not shutil.which('ddcutil'):return {'available':False}
    try:
        bus=_ddc_find()
        if bus is None:return {'available':False}
        p=subprocess.run(['ddcutil','--bus',bus,'getvcp','10','--terse',*_DDC],capture_output=True,text=True,timeout=2)
        fields=p.stdout.strip().split()
        if p.returncode or len(fields)<5:_ddc_fail();return {'available':False}
        current,maximum=float(fields[-2]),float(fields[-1])
        return {'available':maximum>0,'level':current/maximum if maximum else 0,'maximum':maximum}
    except (OSError,ValueError,subprocess.TimeoutExpired):
        _ddc_fail();return {'available':False}

def ddc_read():
    if not shutil.which('ddcutil'):return {'available':False}
    with _ddc_lock() as got:
        return _ddc_read_locked() if got else {'available':False,'busy':True}

def ddc_set(value):
    with _ddc_lock() as got:
        if not got:return {'ok':False,'message':'Brilho DDC/CI ocupado'}
        reading=_ddc_read_locked()
        if not reading['available']:return {'ok':False,'message':'Brilho DDC/CI indisponível'}
        level=max(0,min(round(reading.get('maximum',100)),round(float(value)*reading.get('maximum',100))))
        try:
            p=subprocess.run(['ddcutil','--bus',_ddc_bus,'setvcp','10',str(level)],capture_output=True,text=True,timeout=4)
            return {'ok':p.returncode==0,'message':p.stderr[:200] or 'Brilho atualizado'}
        except (OSError,subprocess.TimeoutExpired) as e:return {'ok':False,'message':str(e)}

def stop(proc,timeout=2):
    """terminate, wait, kill as a last resort; safe on None and on an already-reaped child."""
    if proc is None or proc.poll() is not None:return
    try:proc.terminate()
    except OSError:return
    try:proc.wait(timeout=timeout)
    except subprocess.TimeoutExpired:
        try:proc.kill();proc.wait(timeout=timeout)
        except (OSError,subprocess.TimeoutExpired):pass

def history_sig(config):
    try:st=history_path(config).stat();return (st.st_mtime_ns,st.st_size)
    except OSError:return None

def stream(store):
    cfg=store.reload();output(snapshot(store));start=time.monotonic();cava=None;clip=None;last_cfg=None;last_brightness=-60;cava_missing=False;clip_retry_at=0;cbuf=b''
    sig=last_sig=object();items=[];probe=None;probed=queue.SimpleQueue()
    try:
        while True:
            fingerprint=(store.path.read_bytes() if store.path.exists() else b'')
            if fingerprint!=last_cfg:
                output(snapshot(store));last_cfg=fingerprint;cfg=store.current
            if cfg['mode']=='live' and cfg['modules']['cava'] and cava is None and shutil.which('cava'):
                settings=(cache_dir() if managed() else ROOT/'work')/'cava.conf';settings.parent.mkdir(parents=True,exist_ok=True)
                settings.write_text(f'[general]\nbars = 12\nframerate = {cfg["cava"]["rate"]}\n[input]\nmethod = pipewire\nsource = auto\n[output]\nmethod = raw\nraw_target = /dev/stdout\ndata_format = ascii\nascii_max_range = 1000\nbar_delimiter = 59\nframe_delimiter = 10\n')
                # stderr stays inherited so a real device/config failure shows in the honey-shell journal.
                cava=subprocess.Popen(['cava','-p',str(settings)],stdout=subprocess.PIPE);cava_missing=False;cbuf=b''
            elif cfg['mode']=='live' and cfg['modules']['cava'] and cava is None and not cava_missing and not shutil.which('cava'):
                output({'type':'cava','bars':[0]*12,'error':'Cava indisponível'});cava_missing=True
            if clip is not None and clip.poll() is not None:
                clip.wait();clip=None;clip_retry_at=time.monotonic()+2
            if cfg['mode']=='live' and clip is None and time.monotonic()>=clip_retry_at and shutil.which('wl-paste'):
                try:
                    clip=subprocess.Popen(['wl-paste','--watch',sys.executable,str(Path(__file__).resolve()),'capture'],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
                except OSError:
                    clip_retry_at=time.monotonic()+2
            if cfg['mode']=='demo' or not cfg['modules']['cava']:
                if cava:stop(cava);cava=None;cbuf=b''
            if cfg['mode']=='demo' and clip:stop(clip);clip=None;clip_retry_at=0
            if cfg['mode']=='demo':
                t=time.monotonic()-start
                bars=[.1+.65*abs(math.sin(t*1.9+i*.6))*abs(math.sin(t*.7+i*.2)) for i in range(12)] if cfg['modules']['cava'] and not cfg['motion']['reduced'] else [0]*12
                output({'type':'cava','bars':bars,'demo':True})
            elif cava:
                # Publish only a finished frame. A tick with nothing ready must not zero the bars.
                fd=cava.stdout.fileno()
                while select.select([fd],[],[],0)[0]:
                    chunk=os.read(fd,65536)
                    if not chunk:break
                    cbuf+=chunk
                lines=cbuf.split(b'\n');cbuf=lines.pop()[-65536:]
                latest=next((l.decode(errors='replace').strip() for l in reversed(lines) if l.strip()),None)
                if latest:
                    try:output({'type':'cava','bars':[min(1,max(0,float(x)/1000)) for x in latest.split(';') if x][:12]})
                    except ValueError:pass
                if cava.poll() is not None:
                    output({'type':'cava','bars':[0]*12,'error':'Cava indisponível'});cava=None;cbuf=b''
            # Every 5s this stalled DP-1 (slow frames of ~50–115 ms). Once a minute is enough for the slider.
            # ddcutil can take seconds: it runs in a worker thread so the stream keeps serving cava and config.
            if managed() and cfg['mode']=='live' and (probe is None or not probe.is_alive()) and time.monotonic()-last_brightness>60:
                last_brightness=time.monotonic();probe=threading.Thread(target=lambda:probed.put(ddc_read()),daemon=True);probe.start()
            while not probed.empty():output({'type':'brightness',**probed.get()})
            # The Luau side only uses this packet as a trigger to search again: send a small stamp, parse only when the file changed.
            sig=history_sig(cfg)
            if sig!=last_sig:
                items=history(cfg);output({'type':'clipboard','n':len(items),'stamp':'%s:%s'%(sig or (0,0))});last_sig=sig
            time.sleep(1/cfg['cava']['rate'] if cfg['modules']['cava'] and not cfg['motion']['reduced'] else .5)
    finally:
        for child in [cava,clip]:stop(child)

def _capacity(request):
    try:return max(1,min(50,int(request.get('capacity',7))))
    except (TypeError,ValueError):return 7

def main():
    parser=argparse.ArgumentParser();parser.add_argument('operation',choices=['snapshot','search','action','stream','capture','prepare','wallpapers']);parser.add_argument('payload',nargs='?',default='{}');args=parser.parse_args()
    store=Store();cfg=store.reload()
    try:
        request=json.loads(args.payload)
        if args.operation in ['snapshot','prepare']:output(snapshot(store))
        elif args.operation=='search':output({'rows':search(request['mode'],request.get('query',''),cfg,_capacity(request)),'generation':request.get('generation',0)})
        elif args.operation=='action':output(action(request['kind'],request['value'],cfg,store,request.get('confirmed',False)))
        elif args.operation=='wallpapers':
            try:cap=max(1,min(24,int(request.get('capacity',12))))
            except (TypeError,ValueError):cap=12
            output(wallpapers(cfg,request.get('page',0),cap))
        elif args.operation=='stream':stream(store)
        elif args.operation=='capture':capture(cfg)
    except (OSError,ValueError,KeyError,TypeError,subprocess.SubprocessError) as e:output({'ok':False,'message':str(e)})

if __name__=='__main__':main()
