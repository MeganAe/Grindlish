#!/usr/bin/env python3
"""Build the French render report from real screenshots and measured logs only."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont,ImageChops,ImageStat
import json,re,hashlib,base64,io,html,statistics
P=Path(__file__).resolve().parents[1];R=P/'docs/rendu';A=R/'apres';B=R/'reference';C=R/'comparaisons';C.mkdir(exist_ok=True)
font='/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'
def f(size):return ImageFont.truetype(font,size)
worlds=json.loads((R/'worlds.json').read_text())
recipes=json.loads((B/'recipes.json').read_text());after=json.loads((A/'recipes.json').read_text())
def thumb(path,w=640):
 im=Image.open(path).convert('RGB');return im.resize((w,round(im.height*w/im.width)),Image.Resampling.LANCZOS)
def uri(im,quality=78):
 out=io.BytesIO();im.save(out,'JPEG',quality=quality,optimize=True);return 'data:image/jpeg;base64,'+base64.b64encode(out.getvalue()).decode()
# Atlas: a real OpenGL overview of each world, not generated art.
atlas=Image.new('RGB',(2560,1640),'#102a38');d=ImageDraw.Draw(atlas)
d.text((35,20),'GRINDLISH / DIX MONDES',font=f(46),fill='#edf4ed')
d.text((35,82),'Godot 4.3 · OpenGL Compatibility · captures réelles · 8 mondes principaux + 2 bonus',font=f(24),fill='#b4d4cf')
for i,world in enumerate(worlds):
 x=(i%4)*640;y=135+(i//4)*495
 atlas.paste(thumb(A/f'monde_{i+1}.png'),(x,y))
 d.text((x+15,y+370),f'{i+1:02d}  '+world['name'],font=f(25),fill='#eaf3e8')
 d.text((x+15,y+410),('BONUS · ' if world['bonus'] else '')+world['kind']+' / '+world['weather'],font=f(19),fill='#a8c6c6')
atlas.save(R/'MONDES.jpg',quality=89,optimize=True)
atlas.save(P/'APERCU_PARCS.jpg',quality=87,optimize=True)
# Before/after boards cover every baseline case, at identical CLI recipes.
boards=[]
for start in range(0,len(recipes),4):
 subset=recipes[start:start+4];sheet=Image.new('RGB',(1280,len(subset)*410+55),'#102a38');dr=ImageDraw.Draw(sheet)
 dr.text((15,10),'RÉFÉRENCE FIGÉE',font=f(24),fill='#edf4ed');dr.text((655,10),'APRÈS — MÊMES FLAGS / FRAME',font=f(24),fill='#b4e76a')
 for row,case in enumerate(subset):
  y=55+row*410;name=case['name']
  sheet.paste(thumb(B/(name+'.png')),(0,y));sheet.paste(thumb(A/(name+'.png')),(640,y))
  dr.text((15,y+370),name+' · frame '+str(case['frame'])+' · 1280 × 720',font=f(21),fill='#e8ece5')
 dest=C/f'avant_apres_{start//4+1:02d}.jpg';sheet.save(dest,quality=85,optimize=True);boards.append(dest)
# Verifiable protected code and representative gameplay pixels.
oldsettings=json.loads((B/'settings.json').read_text())
metrics={}
for filename in ['cam.gd','skater.gd','project.godot']:
 old=B/'code'/filename
 expected=hashlib.sha256(old.read_bytes()).hexdigest() if old.exists() else oldsettings['source_sha256'][filename]
 metrics[filename+'_unchanged']=hashlib.sha256((P/filename).read_bytes()).hexdigest()==expected
extract=lambda s:s[s.index('func _environment()'):s.index('func _draw_debug()')]
metrics['environment_function_identical']=extract((P/'game.gd').read_text())==extract((B/'code/game.gd').read_text())
for label,box in [('skater',(550,310,740,450)),('floor',(500,470,900,640))]:
 one=Image.open(B/'parc_1.png').convert('RGB').crop(box);two=Image.open(A/'parc_1.png').convert('RGB').crop(box)
 diff=ImageChops.difference(one,two);metrics[label+'_crop']={'rectangle':box,'identical':diff.getbbox() is None,'mae_rgb':ImageStat.Stat(diff).mean}
(R/'preservation.json').write_text(json.dumps(metrics,indent=2))
# Never substitute headless engine FPS or movie encoding FPS for graphics performance.
measurements=[]
for folder,label in [(B,'avant'),(A,'après')]:
 for path in sorted(folder.glob('fps_*.log')):
  text=path.read_text();samples=[float(n) for n in re.findall(r'Project FPS: ([0-9.]+)',text)]
  final=re.search(r'RENDER fps=(\d+) drawcalls=(\d+) primitives=(\d+)',text)
  measurements.append({'phase':label,'log':path.name,'median_fps':statistics.median(samples) if samples else None,'samples':samples,'last_render':list(map(int,final.groups())) if final else None})
(R/'fps.json').write_text(json.dumps(measurements,indent=2))
checks=[]
for suite in ['learning','systems','modes','safety','life','flow','save_density']:
 path=R/'tests'/f'{suite}.log';text=path.read_text()
 assert 'FAIL ' not in text and 'ERROR:' not in text,(suite,text[-2000:])
 m=re.search(r'checks=(\d+) failures=0',text)
 count=int(m[1]) if m else len(re.findall(r'^(?:PASS |OK   )',text,re.M))
 assert ('failures=0' in text or 'FLOW failures=0' in text),suite
 checks.append((suite,count))
life=json.loads((R/'tests/life_details.json').read_text())
assert all(not any(r['violations'].values()) for r in life)
# French Markdown is the canonical report requested by the user.
md='''# Rendu et dix mondes — 20 octobre 2026

## Livré / périmètre

Dix parcs accessibles par la progression numérique existante : huit mondes principaux et les deux bonus historiques 6–7. IDs 1–7, terrains, rampes, ciels, lumières et caméra historiques conservés. Trois parcours nouveaux, pas trois copies simplement recolorées. Architecture, trafic/nature, accessoires, météo périphérique et audio caractérisent chaque monde.

La référence a été capturée **avant toute modification du jeu actif** en OpenGL Compatibility. Commit de gel : `370900f`. `rendu/reference/recipes.json` contient les 23 recettes et SHA des PNG ; `rendu/reference/settings.json` les réglages réellement relevés. La copie de `levels.gd` a été restituée depuis ce commit et son SHA vérifié, sans inventer une capture antérieure.

## Ce qui reste identique

- Renderer `gl_compatibility`, ciel procédural, tonemapping **LINEAR**.
- Ambiant **#bbced1, 0,55** ; **0,40** sur les parcs 5–6. Soleil **0,85** ; **0,45** sur les parcs 5–6. Rotation **(-52, -35, 0)**, ombres 70 m.
- Ces valeurs réelles diffèrent du 0,5 / 0,8 indiqué dans la consigne : elles n'ont pas été corrigées arbitrairement.
- `cam.gd`, `skater.gd`, `project.godot` et la fonction `_environment()` sont inchangés. Caméra : distance 11, hauteur 5,4, FOV initial 68 puis 66–78 selon vitesse.
- Matériaux Kenney des rampes et dalles 1–7 inchangés ; données complètes des sept niveaux comparées à la référence par test.
- Polices, tailles et contrastes du HUD conservés. Sélecteur des parcs rendu défilant pour atteindre les dix cartes ; option de densité ajoutée dans la page d'options défilante ; crédits complétés.
- Qualité par défaut : niveau 1, résolution 3D 85 %, identique au lot 2. Basse conserve couleurs/lumière et coupe les ombres comme auparavant, la météo décorative et l'oscillation de feuillage ; Haute conserve la même palette à 100 % de résolution. Aucun post-traitement photographique, bloom, HDR, exposition ou brouillard global ajouté.

Les preuves chiffrées sont dans `rendu/preservation.json`. Sur le parc 1, deux zones représentatives, skateur et sol, sont comparées pixel par pixel ; ce n'est **pas** une affirmation que tous les pixels du jeu sont identiques, puisque les extérieurs ont volontairement changé.

## Vérifications intermédiaires

Un premier décor trop vide lorsque la caméra regardait vers l’ouest a été écarté : architecture sur plusieurs côtés et ombres statiques rétablies. La première maquette des sommets alpins présentait des plaques de neige mal raccordées ; elles ont été remplacées par des sommets à cinq faces et des calottes ajustées, avec sapins et balcons. Les essais sont conservés dans `rendu/etapes/` comme étapes de travail, pas comme rendu final.

## Mondes

| ID | Monde | Identité réelle |
|---|---|---|
| 1 | Quartier des érables | Maisons chaudes, collines, arbres au vent, piétons, vélo, chien, papillons, oiseaux en ambiance |
| 2 | Place des arcades | Façades à colonnades, monument/fontaine, vitrines, bus, chat, nuages hauts, ville stylisée |
| 3 | Plage et jetée | Mer, ponton, palmiers, cabanes côtières, bateaux en voies séparées, mouettes, rides d'eau |
| 4 | Fonderie orange | Dents de scie, silos, cheminée/vapeur, pont roulant et crochet animé, machines en ambiance |
| 5 | Jardin des lucioles | Pins, lune/étoiles, bassin, lucioles sans lumière dynamique coûteuse, spectateurs, forêt nocturne |
| 6 | Toits à l'aube — bonus | Parapets, panneaux solaires, ventilation, château d'eau, skyline propre aux toits, drapeaux et vent |
| 7 | Port des cargos — bonus | Cargaison empilée, grand navire, grues/crochet, bateaux, mouettes, composition mer + machines |
| 8 | Prairie des moulins | Grange rouge, portes, moulin rotatif, champs de blé, verger et bottes de paille, vélo, chien, papillons |
| 9 | Village des cimes | Chalets à balcons, sommets à neige ajustée, sapins, télécabine, flocons hors piste, palette bleue |
| 10 | Stade des étoiles | Gradins sur quatre côtés, tableau, mâts, foule MultiMesh réactive, confettis extérieurs, bus et drapeaux |

Les trois nouveaux sols sont vert prairie, bleu alpin et bleu ardoise ; les sept sols anciens ne sont pas recolorés. Les rampes utilisent toujours le kit Kenney, avec implantation différente dans chacun des trois nouveaux parcs. Les ciels, couleurs, signatures de parcours, pistes et volumes de lumière effectifs sont exportés dans `rendu/worlds.json`.

**Choix de protection du rendu :** pas de brouillard global propre à chaque monde, puisqu'il modifierait la référence et délaverait les couleurs. Les signes météo sont locaux et légers. La neige est volontairement blanche hors piste ; le sol jouable alpin reste bleu pour garder la lecture des obstacles. Les accessoires de toit/route sont stylisés, pas des simulations techniques réalistes.

## Vie périphérique et sécurité

Piétons : modèles garçon/fille Kenney CC0 déjà fournis, tailles et accessoires variés, animations natives marche/repos/interactions/réaction. Pauses cadencées ; lorsque deux piétons se rapprochent, arrêt commun, orientation face à face et interaction, puis reprise avec temporisation pour éviter une boucle de discussion permanente. Réaction à la notification de figure encaissée ≥ 400 points. Pas de nouveau pack de personnages mélangé au style d'origine.

Trajets piétons à 3 m hors limite ; véhicules routiers à 14 m ; animaux et circulation maritime/aérienne sur couloirs séparés. Trois réglages persistants **Basse / Moyenne / Haute** : 4/8/12 piétons, 1/2/3 véhicules maximum (une seule cabine sur le câble), 3/5/8 animaux aériens plus un chien/chat selon monde, 8/16/28 éléments météo, 12/24/48 spectateurs sur les mondes 5 et 10. Plusieurs bateaux ont des voies distinctes. Aucune collision physique des extras ne peut bloquer le skateur : ce sont des nœuds visuels à trajectoire contrôlée, pas des corps bloquants.

LOD : personnages masqués au-delà de 105 m, bateaux/oiseaux au-delà de 145 m, animations de squelettes arrêtées au-delà de 65 m ; mises à jour groupées à 20 Hz. Architecture/feuillage et foule sont batchés en MultiMesh. Les extras mobiles ne multiplient pas les passes d'ombres ; les ombres de l'arène/skateur et du décor statique restent celles du réglage courant. Un index spatial accélère les contrôles sans remplacer le test segment/AABB conservateur.

La sécurité n'est pas un simple constat visuel : à chaque pas, balayage du trajet contre les boîtes élargies des décors, évitement mutuel et distance au skateur. Les tests ajoutent des requêtes de chevauchement dans le vrai moteur physique. Les personnages restent hors piste même lorsqu'ils s'arrêtent pour discuter. Les animaux sont des silhouettes originales géométriques, pas des modèles animaliers téléchargés.

## Tests effectués

'''
md+='| Suite | Contrôles passés |\n|---|---:|\n'+''.join(f'| {name} | {count} |\n' for name,count in checks)
md+='''
- Vie : dix mondes × trois densités × 60 s de simulation, 20 contrôles de mouvement par seconde ; 1 000 segments supplémentaires par combinaison pour comparer index spatial et balayage exhaustif. Aucune intrusion d'agent dans l'arène, aucun balayage invalide, chevauchement solide, chevauchement entre agents ni contact avec le skateur dans cette matrice. Détails par cas : `rendu/tests/life_details.json`.
- Chevauchements physiques sondés chaque seconde ; balayages/évitement contrôlés à chaque pas. Cela reste une matrice déterministe de tests, **pas** une preuve mathématique pour tous les états ni un test de tous les triangles de décor non solide.
- Ancienne sauvegarde sans champ de densité : progression/monnaie/records conservés ; aller-retour de densité et clamp contrôlés dans un dossier utilisateur isolé. Aucun fichier de sauvegarde utilisateur normal touché.
- Routes et sept modes testés sur les dix parcs par le pilote réel, sans téléporter le skateur pour finir le mot. La suite learning reste la couverture des 70 mots d'origine ; elle ne constitue pas une matrice exhaustive de tous les mots sur tous les mondes.
- Les captures et nouvelles options ont ensuite été contrôlées en rendu OpenGL réel. Les tests de logique headless ne servent jamais de preuve graphique ou de mesure FPS.

## Captures et comparaisons

'''
md+=f"{len(after)} captures après : sept parcs existants aux mêmes flags/frame que la référence, trois nouveaux parcs, tous les quinze écrans de référence, HUD tactile, dix vues d'ensemble, trois qualités et tactile 1920 × 1080. Journaux, recettes et SHA dans `rendu/apres/`. Aucun rendu n'est une illustration générée.\n\n"
md+="""- Planche des dix mondes : `rendu/MONDES.jpg`.
- Comparaisons de chacun des 23 cas initiaux : `rendu/comparaisons/avant_apres_01.jpg` à `06.jpg`.
- Lecture sans dépendance réseau : `RENDU.html`.
- Vidéo de vie périphérique : `rendu/vie_peripherique.mp4`, capture hors ligne à cadence encodée 30, non une mesure de fluidité matérielle.
- Les vues d’ensemble 2 et 6 utilisent une caméra de démonstration sud pour éviter de cadrer derrière une façade ; les 23 comparaisons avec la référence gardent leurs recettes initiales.

## FPS réellement mesurés

"""
md+='**VM Linux, Mesa llvmpipe logiciel, OpenGL Compatibility, 1280 × 720, audio Dummy. Ce ne sont ni un GPU de PC cible ni un téléphone.** Les essais après utilisent LP_NUM_THREADS=2 ; les parcs 1 et 5 de la référence ont aussi été restaurés depuis le commit de gel et remesurés sur 480 pas physiques avec ce même réglage. Les références initiales 1/5 sans cette variable restent conservées. Le dernier chiffre de drawcalls peut correspondre à une position de caméra différente en fin de parcours non synchronisé ; ne pas le traiter comme un profil GPU à point fixe.\n\n'
md+='| Phase | Journal / réglage | FPS médian des échantillons |\n|---|---|---:|\n'
for row in measurements:md+=f"| {row['phase']} | `{row['log']}` | {row['median_fps'] if row['median_fps'] is not None else 'non disponible'} |\n"
md+='''
**Les cibles 60 FPS PC et ≥ 30 FPS mobile ne sont pas validées.** Les mesures du rasteriseur logiciel ne permettent pas de conclure à une performance sur GPU ou téléphone. Le profil bas est un scénario logiciel, pas une mesure Android. Aucune mesure iPhone/iPad, téléphone Android, Windows natif, manette physique ou écoute humaine. La cadence encodée d'une vidéo de démonstration éventuelle n'est pas un FPS du jeu.

## Audio, licences et limites

Dix musiques différentes et dix ambiances mappées distinctement. Sept nouvelles boucles Kenney CC0 ; sources naturelles/stylisées CC0 et quatre compositions explicites. Notices, URL, auteurs, fichiers et transformations : `rendu/AUDIO.md`, `rendu/audio_sources.json`, `CREDITS.md`, `ASSETS_LEDGER.csv`. Les mélanges ne sont pas revendiqués comme des field recordings originaux. Aucun nouvel audio de voix ni droit vocal supposé.

Ce lot fournit les **sources Godot 4.3**, pas de nouveaux exécutables Windows/APK signés ou testés. Les archives exécutables du lot 2 sont historiques et ne représentent pas ces dix mondes ; elles ne doivent pas servir à juger cette version. Les presets excluent les preuves raster/vidéo et les outils des futurs exports ; aucun export natif nouveau n’est revendiqué. Les rapports `REPORT.md`, `BUILD_MANIFEST.json` et `docs/tests/lot2` sont des preuves de l'ancien lot, pas le manifeste de cette extension.

Le rendu protégé est démontré par comparaison et réglages ; la préférence esthétique de l'utilisateur reste le juge final. L'exhaustivité des états de circulation, les performances matérielles, la conformité d'une publication mobile et une validation humaine audio restent hors de cette validation.

## Reproduire

Ouvrir `project.godot` dans **Godot 4.3**, renderer Compatibility. Les ressources sont déjà intégrées et le jeu reste hors ligne, sans compte, publicité ou télémétrie.

```sh
GODOT=/chemin/Godot_v4.3-stable_linux.x86_64 python3 tools/validate_worlds.py
# Génération des planches / rapport (Python + Pillow)
python3 tools/render_world_report.py
# Sauvegarde isolée (ne jamais viser le dossier normal de l'utilisateur)
XDG_DATA_HOME=/chemin/cache/density_save_test "$GODOT" --headless --path . --script tools/test_density_save.gd
```

Les CLI historiques sont conservées ; ajout de `--density=0|1|2`, `--quality=0|1|2`, `--test=life`, `--overview` et `--life-camera` pour les preuves. Les deux dernières caméras n'affectent jamais la caméra normale. `tools/fetch_world_audio.py` est un outil de préparation réseau explicite, pas du code exécuté par le jeu ; FFmpeg requis uniquement pour reconstruire les composites audio.
'''
(P/'docs/RENDU.md').write_text(md)
# Self-contained gallery with compact real images: no network dependency in Arena preview.
style='''body{margin:0;background:#102a38;color:#eaf2eb;font:16px system-ui,sans-serif}main{max-width:1180px;margin:auto;padding:32px}h1{font-size:42px;margin-bottom:8px}p{line-height:1.55;color:#bfd1d1}.tag{color:#b4e76a;font-weight:bold;letter-spacing:2px;font-size:12px}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(min(100%,310px),1fr));gap:16px}.card{background:#1d3a47;border:1px solid #395561;border-radius:14px;overflow:hidden}img{width:100%;display:block}.caption{padding:15px}h3{margin:0 0 8px}small{color:#bdd3d0}details{background:#1d3a47;padding:14px;margin:14px 0;border-radius:12px}summary{cursor:pointer;font-weight:bold;padding:8px}table{width:100%;border-collapse:collapse;margin:20px 0}td,th{text-align:left;padding:12px;border-bottom:1px solid #365360}code{color:#b4e76a}a{color:#b4e76a}.warning{border-left:4px solid #e7ba69;background:#243e47;padding:18px;margin:24px 0}.stats{display:flex;gap:14px;flex-wrap:wrap;margin:24px 0}.stats div{background:#1d3a47;padding:16px;border-radius:12px}h2{margin-top:42px}button{background:#b4e76a;border:0;border-radius:6px;padding:9px 14px;cursor:pointer;color:#183b47;font-weight:bold}'''
parts=['<!doctype html><html lang="fr"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Grindlish — dix mondes</title><style>'+style+'</style><main><div class="tag">DOSSIER RENDU / GODOT 4.3</div><h1>Dix mondes. Le même skate.</h1><p>Référence figée avant modification. Décors, musique et vie périphérique distincts ; caméra, éclairage et matériaux historiques protégés.</p>']
parts+=['<div class="stats"><div><b>10</b> mondes, dont 2 bonus</div><div><b>'+str(sum(c for n,c in checks))+'</b> contrôles recensés</div><div><b>'+str(len(after))+'</b> captures OpenGL après</div><div><b>3</b> densités de vie</div></div>']
parts+=['<div class="warning"><b>Mesures honnêtes.</b> Tests sur VM sans GPU, rasteriseur llvmpipe. Les cibles 60 FPS PC / 30 FPS mobile ne sont pas validées sur matériel réel. Pas de nouveau binaire Windows/APK dans ce lot.</div><h2>Atlas des mondes</h2><div class="grid">']
for world in worlds:
 i=world['id'];parts += ['<article class="card"><img loading="lazy" src="'+uri(thumb(A/f'monde_{i}.png',600))+'"><div class="caption"><h3>'+html.escape(f'{i:02d} · '+world['name'])+'</h3><small>'+('BONUS · ' if world['bonus'] else '')+html.escape(world['kind']+' / '+world['weather'])+'</small></div></article>']
parts+=['</div><h2>Chaque écran, avant / après</h2><p>Les 23 recettes de référence sont rejouées aux mêmes flags, résolution et nombre de frames. Les trois mondes nouveaux n’ont pas de faux « avant ».</p>']
for index,path in enumerate(boards):parts+=['<details><summary>Planche '+str(index+1)+' · '+html.escape(', '.join(c['name'] for c in recipes[index*4:index*4+4]))+'</summary><img loading="lazy" src="'+uri(Image.open(path),83)+'"></details>']
movie=R/'vie_peripherique.mp4'
if movie.exists():
 parts+=['<h2>La vie en mouvement</h2><p>Courte capture réelle hors ligne, caméra de démonstration hors piste. La cadence encodée ne mesure pas les FPS du jeu.</p><video controls playsinline style="width:100%;border-radius:14px" src="data:video/mp4;base64,'+base64.b64encode(movie.read_bytes()).decode()+'"></video>']
parts+=['<h2>Protection du rendu</h2><p>Renderer Compatibility, tonemapping LINEAR, ambiant #bbced1 0,55 / 0,40, soleil 0,85 / 0,45 et ombres 70 m inchangés. Les sept niveaux historiques sont comparés à leur copie du commit de gel.</p><table><tr><th>Contrôle</th><th>Résultat vérifié</th></tr>']
for key,value in metrics.items():parts+=['<tr><td>'+html.escape(key)+'</td><td>'+html.escape(str(value))+'</td></tr>']
parts+=['</table><h2>Validation</h2><table><tr><th>Suite</th><th>Contrôles passés</th></tr>'+''.join('<tr><td>'+name+'</td><td>'+str(count)+'</td></tr>' for name,count in checks)+'</table><p>Vie : 10 mondes × 3 densités × 60 secondes simulées. Balayages continus, évitement, requêtes physiques et comparaison de l’index spatial à des segments exhaustifs. Aucun chevauchement détecté dans cette matrice déterministe ; pas une garantie pour tous les états.</p>']
parts+=['<h2>FPS du rasteriseur logiciel</h2><table><tr><th>Phase / journal</th><th>Médiane</th></tr>'+''.join('<tr><td>'+html.escape(row['phase']+' / '+row['log'])+'</td><td>'+str(row['median_fps'])+'</td></tr>' for row in measurements)+'</table><p>Le profil bas n’est pas un appareil Android émulé. Les courtes vidéos hors ligne éventuelles ne sont pas des mesures de FPS.</p><h2>Sources et licence</h2><p>Piétons : modèles/animations Kenney CC0 existants. Sept nouvelles musiques Kenney CC0 ; ambiances libres documentées. Animaux, architecture et foule procédurale originaux. Crédits complets dans CREDITS.md et docs/rendu/AUDIO.md.</p><p>Rapport canonique : <code>docs/RENDU.md</code>. Preuves brutes, SHA, recettes, limites et mesures : <code>docs/rendu/</code>. Projet hors ligne, sans compte ni suivi.</p></main></html>']
(P/'docs/RENDU.html').write_text(''.join(parts))
print('REPORT BUILT:',len(after),'images,',checks,'metrics',metrics)
