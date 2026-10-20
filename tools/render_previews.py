#!/usr/bin/env python3
import os,subprocess,json,struct
from pathlib import Path
p=Path(__file__).resolve().parents[1]
godot=os.environ['GODOT']
out=p/'docs/captures/lot2';out.mkdir(exist_ok=True,parents=True)
logs=p/'docs/tests/lot2'; results=[]
cases=[('park_'+str(i),['--screen=play','--level='+str(i)]+(['--auto'] if i==4 else []),480 if i==4 else 25) for i in range(1,8)]
for s in ['shop3d','controls','menu','modes','levels','briefing','help','options','pause','end','shop','notebook','quiz','teacher','credits']:
 flags=['--screen='+s]
 if s=='levels':flags+=['--cheat']
 if s=='notebook':flags+=['--seed-words']
 cases.append((s,flags,115 if s=='end' else (25 if s in ['pause','shop3d'] else 5)))
cases.append(('menu_en', ['--screen=menu','--locale=en'], 5))
cases.append(('options_en', ['--screen=options','--locale=en'], 5))
for res in ['2400x1080','1920x1080','2560x1600','1280x720']:
 cases.append(('touch_'+res,['--screen=play','--touch','--res='+res],5))
for name,flags,frames in cases:
 resolution = next((flag.split('=', 1)[1] for flag in flags if flag.startswith('--res=')), '1280x720')
 cmd=['xvfb-run','-a','-s','-screen 0 2800x1800x24',godot,'--path',str(p),'--audio-driver','Dummy','--resolution',resolution,'--','--nosave',*flags,'--frame='+str(frames),'--shot='+str(out/(name+'.png'))]
 r=subprocess.run(cmd,capture_output=True,text=True,timeout=90)
 text=r.stdout+r.stderr
 (logs/('render_'+name+'.log')).write_text(text)
 errors=[l for l in text.splitlines() if l.startswith(('ERROR:','SCRIPT ERROR:'))]
 image_path = out/(name+'.png')
 actual = struct.unpack('>II',image_path.read_bytes()[16:24]) if image_path.exists() else None
 expected = tuple(map(int, resolution.split('x')))
 if actual != expected: errors.append('Unexpected raster size: '+str(actual)+' expected '+str(expected))
 results.append({'case':name,'exit_code':r.returncode,'errors':errors,'pixels':actual})
 print(name,r.returncode,'errors',len(errors),flush=True)
(logs/'render_manifest.json').write_text(json.dumps(results,indent=2))
