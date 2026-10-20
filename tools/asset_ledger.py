#!/usr/bin/env python3
"""Regenerate the provenance inventory. No network; Python standard library."""
from pathlib import Path
import csv,hashlib
ROOT=Path(__file__).resolve().parents[1]
items=[]
for folder in ['models','assets','audio','data']:
    items += [p for p in (ROOT/folder).rglob('*') if p.is_file() and p.suffix not in ['.import'] and not p.name.startswith('.')]
items += [ROOT/'icon.svg']
rows=[]
for file in sorted(items):
    name=file.relative_to(ROOT).as_posix()
    author='Grindlish project (AI-assisted)';license='Project-original; no third-party asset licence asserted';source='Creation in this project';change='Original'
    if name.startswith('models/'):
        author='Kenney';license='CC0';source='models/LICENSE_Kenney.txt; https://kenney.nl/';change='Provided source asset; unchanged'
    elif name.startswith('assets/licenses/'):
        author='Respective authors listed in notice';license='Licence/copyright documentation';source='CREDITS.md';change='Copied notice; no asset relicensing'
    elif name.endswith('.ttf'):
        author='Bitstream / DejaVu contributors';license='Bitstream Vera / DejaVu';source='https://dejavu-fonts.github.io/License.html';change='Unmodified font'
    elif name.startswith('audio/sfx/'):
        author='Kenney';license='CC0';source='https://kenney.nl/assets/'+('impact-sounds' if file.stem.startswith(('impact','footstep')) else 'interface-sounds');change='Selected original Ogg file'
    elif name.startswith('audio/loops/'):
        author='rubberduck';license='CC0';source='https://opengameart.org/content/30-cc0-sfx-loops';change='Selected original Ogg file'
    elif name.startswith('audio/music/jingles'):
        author='Kenney';license='CC0';source='https://kenney.nl/assets/music-jingles';change='Selected original Ogg file'
    elif name.startswith('audio/music/'):
        license='CC0'
        author,source,change={
          'chill.ogg':('omfgdude; loop edit qubodup','https://opengameart.org/content/chill-lofi-inspired-loop-edit','Renamed chilllofir-loop.ogg'),
          'calm.mp3':('wipics','https://opengameart.org/content/calm-loop','Renamed Relaxing_0.mp3'),
          'downtempo.ogg':('Nostromo','https://opengameart.org/content/music-loop-strong-downtempo-seamless','WAV converted to Vorbis using FFmpeg')
        }[file.name]
    elif name.startswith('audio/words/'):
        author='Piper synthesis; Bryce Beattie model; Linda Johnson / Keith Ito dataset';license='Generated with declared public-domain LJSpeech model; see CREDITS.md';source='https://brycebeattie.com/files/tts/ ; https://keithito.com/LJ-Speech-Dataset/';change='Local synthetic US speech, en_US-ljspeech-medium'
    rows.append([name,author,license,source,change,hashlib.sha256(file.read_bytes()).hexdigest()])
with (ROOT/'docs/ASSETS_LEDGER.csv').open('w',newline='') as out:
    writer=csv.writer(out);writer.writerow(['file','author','license_or_status','source_evidence','transformation','sha256']);writer.writerows(rows)
print(len(rows),'assets inventoried')
