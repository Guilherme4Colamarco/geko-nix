"""Capability-oriented session actions; no hardcoded desktop configuration."""
import os
import shutil

def detect(preferred='auto'):
    if preferred!='auto': return preferred
    if os.environ.get('HYPRLAND_INSTANCE_SIGNATURE'):return 'hyprland'
    if os.environ.get('NIRI_SOCKET'):return 'niri'
    if os.environ.get('PLEAMAR_WM_SOCKET') or 'pleamar' in os.environ.get('XDG_CURRENT_DESKTOP','').lower():return 'pleamar-wm'
    return 'generic'

def power_command(action,config):
    compositor=detect(config['compositor'])
    if action=='lock':return config['power']['lock_command'] or None
    if action=='suspend':return ['honeyctl','suspend'] if os.environ.get('HONEY_MANAGED')=='1' else ['systemctl','suspend']
    if action=='reboot':return ['systemctl','reboot']
    if action=='shutdown':return ['systemctl','poweroff']
    if action=='logout':
        if compositor=='hyprland':return ['hyprctl','dispatch','hl.dsp.exit()']
        if compositor=='niri':return ['niri','msg','action','quit','--skip-confirmation']
        # No undocumented pleamar-wm exit command; require session manager capability.
        sid=os.environ.get('XDG_SESSION_ID')
        return ['loginctl','terminate-session',sid] if sid else None
    return None

def capabilities(config):
    return {'compositor':detect(config['compositor']), 'clipboard': bool(shutil.which('wl-copy')),
            'cava':bool(shutil.which('cava')),'file_open':bool(shutil.which('xdg-open')),
            'power':{a:bool(power_command(a,config)) for a in ['lock','suspend','logout','reboot','shutdown']}}
