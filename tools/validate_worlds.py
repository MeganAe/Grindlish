#!/usr/bin/env python3
"""Godot 4.3 regression run. Real renderer captures, no invented hardware numbers.
GODOT=/path/to/Godot python3 tools/validate_worlds.py
All cases are rerun; no cached test result is silently reused.
"""
from pathlib import Path
import subprocess,os,json,time,hashlib,sys
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
G=os.environ['GODOT'];OUT=ROOT/'docs/rendu';TEST=OUT/'tests';AFTER=OUT/'apres'
TEST.mkdir(exist_ok=True);AFTER.mkdir(exist_ok=True)
ENV=dict(os.environ,LP_NUM_THREADS='2')
def execute(name,cmd,target,timeout=1800,environment=None):
    start=time.monotonic();r=subprocess.run(cmd,capture_output=True,text=True,env=environment or ENV,timeout=timeout)
    text=r.stdout+r.stderr;target.write_text(text)
    assert r.returncode==0 and not any(x in text for x in ['ERROR:','FAIL ']),(name,text[-5000:])
    print(name,'OK',round(time.monotonic()-start,1),'s',flush=True)
    return text
execute('import',[G,'--headless','--editor','--path',str(ROOT),'--import','--quit'],TEST/'final_import.log')
for suite in ([] if '--captures-only' in sys.argv else ['life','systems','learning','modes','safety','flow']):
    execute(suite,[G,'--headless','--path',str(ROOT),'--fixed-fps','60','--','--test='+suite,'--nosave'],TEST/(suite+'.log'))
if '--captures-only' not in sys.argv:
    save_env=dict(ENV,XDG_DATA_HOME=str(ROOT/'.cache/density_save_test'))
    execute('save_density',[G,'--headless','--path',str(ROOT),'--script','tools/test_density_save.gd'],TEST/'save_density.log',environment=save_env)
    print('ALL LOGIC TESTS COMPLETE',flush=True)
else:
    print('CAPTURES ONLY: logic suites not rerun in this invocation',flush=True)
cases=json.loads((OUT/'reference/recipes.json').read_text())
cases += [{'name':f'parc_{id}','flags':['--screen=play',f'--level={id}','--auto','--word=board'],'frame':180} for id in [8,9,10]]
cases += [{'name':f'monde_{id}','flags':['--screen=play',f'--level={id}','--overview',*(['--overview-camera=0,50,82'] if id in [2,6] else [])],'frame':35} for id in range(1,11)]
cases += [{'name':f'qualite_{q}','flags':['--screen=play','--level=9',f'--quality={q}'],'frame':35} for q in [0,1,2]]
cases += [{'name':'tactile_1920x1080','flags':['--screen=play','--level=10','--touch'],'frame':25,'resolution':'1920x1080'}]
records=[]
for case in cases:
    name=case['name'];res=case.get('resolution','1280x720');res='x'.join(map(str,res)) if isinstance(res,list) else res;image=AFTER/(name+'.png')
    cmd=['xvfb-run','-a','-s','-screen 0 1920x1080x24',G,'--path',str(ROOT),'--audio-driver','Dummy','--resolution',res,'--fixed-fps','60','--','--nosave',*case['flags'],'--frame='+str(case['frame']),'--shot='+str(image)]
    execute(name,cmd,AFTER/(name+'.log'),180)
    assert Image.open(image).size==tuple(map(int,res.split('x')))
    records.append(dict(case,sha256=hashlib.sha256(image.read_bytes()).hexdigest()))
(AFTER/'recipes.json').write_text(json.dumps(records,indent=2))
for id,quality,density,res in [(1,1,1,'1280x720'),(5,1,1,'1280x720'),(9,1,1,'1280x720'),(10,1,1,'1280x720'),(10,0,0,'1280x720'),(10,2,2,'1280x720')]:
    name=f'fps_parc_{id}_q{quality}_d{density}'
    execute(name,['xvfb-run','-a',G,'--path',str(ROOT),'--audio-driver','Dummy','--resolution',res,'--print-fps','--','--nosave','--screen=play',f'--level={id}','--auto','--word=board',f'--quality={quality}',f'--density={density}','--run=480'],AFTER/(name+'.log'),180)
print('WORLD VALIDATION COMPLETE',flush=True)
