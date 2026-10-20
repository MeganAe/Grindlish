# Grindlish — crédits et provenance, lot 2

Jeu hors ligne basé sur Skate Jam fourni par l'utilisateur. Aucun code des jeux consultés dans `docs/RESEARCH.md` n'a été copié. Les licences des composants ne constituent pas une licence globale nouvelle du code de base ni une validation du nom commercial.

## Modèles
**Kenney — Mini Skate 2.0, CC0**, modèles et colormap fournis dans l'archive initiale. Notice originale : `models/LICENSE_Kenney.txt`, recopiée dans les notices exportées. Site auteur : https://kenney.nl/ ; CC0 : https://creativecommons.org/publicdomain/zero/1.0/

## SFX et jingles — fichiers téléchargés, CC0
- **Kenney, Interface Sounds** : https://kenney.nl/assets/interface-sounds — archive `kenney_interface-sounds.zip`. Clics, sélection, confirmation, questions, etc.
- **Kenney, Impact Sounds** : https://kenney.nl/assets/impact-sounds — archive `kenney_impact-sounds.zip`. Métal, planches, impacts doux et pas sur bois/béton. Ces sons sont stylisés ; tous les fichiers distribués ne sont pas encore sélectionnés par la logique de jeu.
- **Kenney, Music Jingles** : https://kenney.nl/assets/music-jingles — `jingles_HIT00.ogg`, `jingles_HIT01.ogg`.
- **rubberduck, 30 CC0 SFX loops**, https://opengameart.org/content/30-cc0-sfx-loops — archive https://opengameart.org/sites/default/files/sfx_loops.zip . Fichiers retenus : `rolling.ogg`, `noise_03.ogg`, `ambient_01.ogg`, `machine_04.ogg`, `water_flowing.ogg`.

Les boucles de roulement/grind servent d'illustrations sonores, **pas d'enregistrements de terrain certifiés de skateboard**. Le son d'atterrissage n'a pas encore de sélection complète par surface. Aucun son propriétaire présumé gratuit n'a été utilisé.

## Musiques — CC0
- `audio/music/chill.ogg` : **omfgdude**, montage de boucle **qubodup**, « Chill lofi-inspired loop edit ». Page : https://opengameart.org/content/chill-lofi-inspired-loop-edit ; fichier : https://opengameart.org/sites/default/files/chilllofir-loop.ogg . Renommage seulement.
- `audio/music/calm.mp3` : **wipics**, « Calm loop ». Page : https://opengameart.org/content/calm-loop ; fichier : https://opengameart.org/sites/default/files/Relaxing_0.mp3 . Renommage seulement.
- `audio/music/downtempo.ogg` : **Nostromo**, « Music loop strong downtempo seamless ». Page : https://opengameart.org/content/music-loop-strong-downtempo-seamless ; source WAV : https://opengameart.org/sites/default/files/space_ranger_seamless_loop.wav . Conversion en Vorbis par FFmpeg.

Trois pistes sont partagées entre menu/parcs : pas sept compositions exclusives.

## 70 prononciations anglaises — génération locale
Fichiers `audio/words/*.wav`, une seule voix américaine féminine synthétique. Outil local **Piper**, version publiée 2023-11-14-2 ; code de cette version sous MIT, https://github.com/rhasspy/piper/releases/tag/2023.11.14-2 . Modèle **en_US/ljspeech/medium**, entraîné par **Bryce Beattie** sur **LJSpeech**, déclaré domaine public :
- carte du modèle : https://huggingface.co/rhasspy/piper-voices/raw/main/en/en_US/ljspeech/medium/MODEL_CARD
- déclaration de l'entraîneur : https://brycebeattie.com/files/tts/
- dataset : **Linda Johnson / Keith Ito**, https://keithito.com/LJ-Speech-Dataset/

Notices/carte recopiées sous `docs/licenses`. Le moteur de synthèse, eSpeak et les poids ONNX **ne sont pas distribués** : seuls les WAV générés sont dans le jeu. Ils ne sont pas présentés comme une interprétation humaine ni comme une voix de service propriétaire. La provenance et la déclaration public-domain sont celles des sources ; aucune garantie juridique mondiale n'est formulée.

## Police et créations du projet
- **DejaVu Sans**, Bitstream Vera / DejaVu ; https://dejavu-fonts.github.io/License.html . Notice fournie, fichier de police non modifié.
- Pictogrammes des 70 mots, illustration de menu, textures de boutons/panneaux/focus, curseur, icône, textes pédagogiques et géométrie du décor : créations propres à ce projet, assistées par IA/code, sans reprise de marque ou d'illustration tierce identifiée. Pas de garantie d'exclusivité du nom ou d'une forme graphique.
- **Godot Engine 4.3**, MIT : https://godotengine.org/license/ . Texte et notices des dépendances extraits du moteur utilisé dans `docs/licenses/GODOT_4.3.txt`, également inclus dans les paquets exportés.

## Registre et distribution
`docs/ASSETS_LEDGER.csv` : auteur, statut/licence, source, transformation et SHA-256 pour chaque asset distribué ; `.import` et caches ne sont pas des assets sources indépendants. Les notices nécessaires aux binaires sont également sous `assets/licenses/`.
Ni Piper/SDK/JDK ni projets de recherche ne sont embarqués dans les archives livrées.
