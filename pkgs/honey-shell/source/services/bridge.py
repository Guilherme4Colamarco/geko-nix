#!/usr/bin/env python3
"""JSON boundary for helpers outside Pleamar's built-in platform services."""
import argparse
import fcntl
import re
import hashlib
import json
import math
import os
from pathlib import Path
import select
import shlex
import shutil
import subprocess
import sys
import time

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT))
from core.config import Store, write_palette, managed, state_dir, cache_dir, history_path, image_path, user_path, atomic_text
from adapters.compositor import capabilities, power_command

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

def search(mode,query,config):
    q=query.casefold();result=[]
    if mode=='files':
        count=0
        for root in config['files']['roots']:
            base=(user_path(root) if managed() else ROOT/root).resolve()
            if not base.is_dir():continue
            for parent, dirs, files in os.walk(base,followlinks=False):
                dirs[:]=sorted(d for d in dirs if not d.startswith('.') and not (Path(parent)/d).is_symlink())
                for name in sorted(files):
                    count+=1
                    if count>config['files']['limit']:return result[:7]
                    path=Path(parent)/name
                    if path.is_symlink():continue
                    if q in name.casefold():result.append(row(str(path),name,str(path.parent),'file',str(path)))
                    if len(result)==7:return result
    elif mode=='emoji':
        result=[row(icon,icon+'  '+label,'Copiar emoji','emoji',icon) for icon,label in EMOJI if q in label.casefold() or q in icon][:7]
    elif mode=='settings':
        result=[row(key,name,('Gerenciado pelo Home Manager · '+str(config[key.split('.')[0]][key.split('.')[1]])) if managed() else detail,'setting',key) for key,name,detail in SETTINGS if q in (key+' '+name).casefold()][:7]
    elif mode=='clipboard':
        result=[row(x['id'],x['label'],'Imagem' if x['kind']=='image' else 'Texto','clipboard',x['id'],str(image_path(x['value'])) if x['kind']=='image' else '') for x in history(config) if q in (x['label']+' '+(x['value'] if x['kind']=='text' else '')).casefold()][:7]
    if mode=='clipboard' and (not q or q in 'limpar histórico clipboard'):
        result=result[:6]+[row('clear','Limpar histórico','Remover textos e imagens armazenados','clear','')]
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
        return call(['xdg-open',str(p)],config)
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
    if kind=='power':
        if value not in ['lock','suspend','logout','reboot','shutdown']:return {'ok':False,'message':'Ação desconhecida.'}
        if value in ['reboot','shutdown'] and not confirmed:return {'ok':False,'message':'Confirmação necessária.'}
        if config['mode']=='demo':return {'ok':True,'message':'[demo] '+value+' — nenhuma ação no sistema'}
        cmd=power_command(value,config)
        return call(cmd,config) if cmd else {'ok':False,'message':'Ação indisponível neste compositor.'}
    return {'ok':False,'message':'Ação desconhecida.'}

def snapshot(store):
    config=store.reload()
    if not store.error:write_palette(config)
    return {'type':'config','config':config,'error':store.error,'capabilities':capabilities(config),'fixture_icon':str(ROOT/'fixtures/honey.svg'),'managed':managed()}

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

# DDC bus discovery is cached only within the helper process. Never assume a bus number.
# On this NVIDIA, ddcutil holds the DRM i2c bus long enough to stall frames.
# A failed probe must not immediately scan again.
_ddc_bus=None
_ddc_retry_at=0
_DDC=['--disable-dynamic-sleep','--maxtries=1,1,1']

def ddc_read():
    global _ddc_bus,_ddc_retry_at
    if not shutil.which('ddcutil'):return {'available':False}
    now=time.monotonic()
    if _ddc_bus is None and now<_ddc_retry_at:return {'available':False}
    try:
        if _ddc_bus is None:
            p=subprocess.run(['ddcutil','detect','--brief',*_DDC],capture_output=True,text=True,timeout=4)
            buses=re.findall(r'I2C bus:\s*/dev/i2c-(\d+)',p.stdout) or re.findall(r'/dev/i2c-(\d+)',p.stdout)
            if not buses:
                _ddc_retry_at=now+120
                return {'available':False}
            _ddc_bus=buses[0]
        p=subprocess.run(['ddcutil','--bus',_ddc_bus,'getvcp','10','--terse',*_DDC],capture_output=True,text=True,timeout=2)
        fields=p.stdout.strip().split()
        if p.returncode or len(fields)<5:
            _ddc_bus=None;_ddc_retry_at=now+120;return {'available':False}
        current,maximum=float(fields[-2]),float(fields[-1])
        return {'available':maximum>0,'level':current/maximum if maximum else 0,'maximum':maximum}
    except (OSError,ValueError,subprocess.TimeoutExpired):
        _ddc_bus=None;_ddc_retry_at=time.monotonic()+120;return {'available':False}

def ddc_set(value):
    reading=ddc_read()
    if not reading['available']:return {'ok':False,'message':'Brilho DDC/CI indisponível'}
    level=max(0,min(round(reading.get('maximum',100)),round(float(value)*reading.get('maximum',100))))
    try:
        p=subprocess.run(['ddcutil','--bus',_ddc_bus,'setvcp','10',str(level)],capture_output=True,text=True,timeout=4)
        return {'ok':p.returncode==0,'message':p.stderr[:200] or 'Brilho atualizado'}
    except (OSError,subprocess.TimeoutExpired) as e:return {'ok':False,'message':str(e)}

def stream(store):
    cfg=store.reload();output(snapshot(store));last=None;start=time.monotonic();cava=None;clip=None;last_cfg=None;last_brightness=0;cava_missing=False
    try:
        while True:
            fingerprint=(store.path.read_bytes() if store.path.exists() else b'')
            if fingerprint!=last_cfg:
                output(snapshot(store));last_cfg=fingerprint;cfg=store.current
            if cfg['mode']=='live' and cfg['modules']['cava'] and cava is None and shutil.which('cava'):
                settings=(cache_dir() if managed() else ROOT/'work')/'cava.conf';settings.parent.mkdir(parents=True,exist_ok=True)
                settings.write_text(f'[general]\nbars = 12\nframerate = {cfg["cava"]["rate"]}\n[input]\nmethod = pipewire\nsource = auto\n[output]\nmethod = raw\nraw_target = /dev/stdout\ndata_format = ascii\nascii_max_range = 1000\nbar_delimiter = 59\nframe_delimiter = 10\n')
                # stderr stays inherited so a real device/config failure shows in the honey-shell journal.
                cava=subprocess.Popen(['cava','-p',str(settings)],stdout=subprocess.PIPE);cava_missing=False
            elif cfg['mode']=='live' and cfg['modules']['cava'] and cava is None and not cava_missing and not shutil.which('cava'):
                output({'type':'cava','bars':[0]*12,'error':'Cava indisponível'});cava_missing=True
            if cfg['mode']=='live' and clip is None and shutil.which('wl-paste'):
                clip=subprocess.Popen(['wl-paste','--watch',sys.executable,str(Path(__file__).resolve()),'capture'],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
            if cfg['mode']=='demo' or not cfg['modules']['cava']:
                if cava:cava.terminate();cava.wait(timeout=2);cava=None
            if cfg['mode']=='demo' and clip:clip.terminate();clip.wait(timeout=2);clip=None
            if cfg['mode']=='demo':
                t=time.monotonic()-start
                bars=[.1+.65*abs(math.sin(t*1.9+i*.6))*abs(math.sin(t*.7+i*.2)) for i in range(12)] if cfg['modules']['cava'] and not cfg['motion']['reduced'] else [0]*12
                output({'type':'cava','bars':bars,'demo':True})
            elif cava:
                # Publish only a finished frame. A tick with nothing ready must not zero the bars.
                latest=None
                while select.select([cava.stdout],[],[],0)[0]:
                    raw=cava.stdout.readline()
                    if not raw:break
                    latest=raw.decode(errors='replace').strip()
                if latest:
                    try:output({'type':'cava','bars':[min(1,max(0,float(x)/1000)) for x in latest.split(';') if x][:12]})
                    except ValueError:pass
                if cava.poll() is not None:
                    output({'type':'cava','bars':[0]*12,'error':'Cava indisponível'});cava=None
            # Every 5s this stalled DP-1 (slow frames of ~50–115 ms). Once a minute is enough for the slider.
            if managed() and cfg['mode']=='live' and time.monotonic()-last_brightness>60:
                output({'type':'brightness',**ddc_read()});last_brightness=time.monotonic()
            h=history(cfg);stamp=json.dumps(h,sort_keys=True)
            if stamp!=last:output({'type':'clipboard','items':h});last=stamp
            time.sleep(1/cfg['cava']['rate'] if cfg['modules']['cava'] and not cfg['motion']['reduced'] else .5)
    finally:
        for child in [cava,clip]:
            if child and child.poll() is None:child.terminate();child.wait(timeout=2)

def main():
    parser=argparse.ArgumentParser();parser.add_argument('operation',choices=['snapshot','search','action','stream','capture','prepare']);parser.add_argument('payload',nargs='?',default='{}');args=parser.parse_args()
    store=Store();cfg=store.reload()
    try:
        request=json.loads(args.payload)
        if args.operation in ['snapshot','prepare']:output(snapshot(store))
        elif args.operation=='search':output({'rows':search(request['mode'],request.get('query',''),cfg),'generation':request.get('generation',0)})
        elif args.operation=='action':output(action(request['kind'],request['value'],cfg,store,request.get('confirmed',False)))
        elif args.operation=='stream':stream(store)
        elif args.operation=='capture':capture(cfg)
    except (OSError,ValueError,KeyError,TypeError,subprocess.SubprocessError) as e:output({'ok':False,'message':str(e)})

if __name__=='__main__':main()
