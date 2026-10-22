#!/usr/bin/env python3
"""Explicit network asset preparation; see docs/rendu/AUDIO.md. Requires FFmpeg."""
from pathlib import Path
import urllib.request as U, concurrent.futures as F, hashlib, json, subprocess, zipfile
P=Path(__file__).resolve().parents[1];C=P/'.cache/world_audio';C.mkdir(parents=True,exist_ok=True)
M=P/'audio/music';A=P/'audio/worlds';A.mkdir(exist_ok=True)
tracks={'Time Driving':'time_driving','Infinite Descent':'infinite_descent','Flowing Rocks':'flowing_rocks','Night at the Beach':'night_beach','Farm Frolics':'farm_frolics','Polka Train':'polka_train','Alpha Dance':'alpha_dance'}
base="https://www.gamesounds.xyz/Kenney%27s%20Sound%20Pack/Music%20Loops/"
manifest=[]
def fetch(url,dest,author,page):
    data=dest.read_bytes() if dest.exists() else U.urlopen(U.Request(url,headers={"User-Agent":"Mozilla/5.0"}),timeout=60).read();dest.write_bytes(data)
    manifest.append({'file':str(dest.relative_to(P)) if dest.is_relative_to(P) else dest.name,'download':url,'author':author,'license':'CC0-1.0','evidence':page,'source_sha256':hashlib.sha256(data).hexdigest()})
with F.ThreadPoolExecutor(max_workers=5) as pool:
    jobs=[pool.submit(fetch,base+'Loops/'+U.quote(k)+'.ogg',M/(v+'.ogg'),'Kenney',base+'readme.txt') for k,v in tracks.items()]
    jobs += [pool.submit(fetch,url,C/name,author,page) for name,url,author,page in [
      ('birds.ogg','https://opengameart.org/sites/default/files/birds-isaiah658_0.ogg','isaiah658','https://opengameart.org/content/ambient-bird-sounds'),
      ('city.ogg','https://opengameart.org/sites/default/files/busy_cyberworld.ogg','TinyWorlds','https://opengameart.org/content/scifi-city-ambient-loop'),
      ('forest.mp3','https://opengameart.org/sites/default/files/Forest_Ambience.mp3','TinyWorlds','https://opengameart.org/content/forest-ambience'),
      ('waves.flac','https://opengameart.org/sites/default/files/wave_01_cc0-18363__jasinski__alkaibeach.flac','jasinski; submitted by qubodup','https://opengameart.org/content/beach-ocean-waves'),
      ('wind.ogg','https://opengameart.org/sites/default/files/wind%20woosh%20loop.ogg','SketchMan3','https://opengameart.org/content/wind-whoosh-loop'),
      ('rain.zip','https://opengameart.org/sites/default/files/Rain%20OGG.zip','Ylmir','https://opengameart.org/content/rain-loopable')]]
    for job in jobs:job.result()
fetch(base+'readme.txt',P/'assets/licenses/Kenney_Music_Loops.txt','Kenney',base+'readme.txt')
for name in ['birds.ogg','city.ogg','forest.mp3','wind.ogg']:(A/name).write_bytes((C/name).read_bytes())
def ff(args):subprocess.run(['ffmpeg','-v','error','-y',*map(str,args)],check=True)
ff(['-i',C/'waves.flac','-af','afade=t=in:d=0.25,areverse,afade=t=in:d=0.25,areverse','-c:a','libvorbis','-q:a','3',A/'waves.ogg'])
with zipfile.ZipFile(C/'rain.zip') as z:
    name=next(n for n in z.namelist() if n.lower().endswith('.ogg'));(C/'rain.ogg').write_bytes(z.read(name))
def mix(out,one,two,weights,filters='anull'):
    ff(['-stream_loop','-1','-i',one,'-stream_loop','-1','-i',two,'-t','28','-filter_complex',f"[0:a][1:a]amix=inputs=2:weights='{weights}':normalize=1,{filters},afade=t=in:d=0.4,afade=t=out:st=27.6:d=0.4",'-c:a','libvorbis','-q:a','3',A/out])
mix('harbor.ogg',C/'waves.flac',P/'audio/loops/machine_04.ogg','1 0.16','lowpass=f=4500')
mix('meadow.ogg',C/'birds.ogg',C/'wind.ogg','1 0.2','highpass=f=120')
mix('alpine.ogg',C/'wind.ogg',C/'rain.ogg','1 0.08','lowpass=f=1800')
mix('stadium.ogg',C/'city.ogg',P/'audio/loops/ambient_01.ogg','1 0.22','highpass=f=200')
(P/'docs/rendu/audio_sources.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2))
print('AUDIO: seven distinct tracks, nine ambience files; factory uses existing machine_04.ogg')
