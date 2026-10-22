# Audio des dix mondes

Tous les ajouts audio proviennent de sources déclarées **CC0** sur les pages vérifiées. Les URL de téléchargement, auteurs, preuves de licence et SHA-256 des fichiers sources sont dans `audio_sources.json`. Le registre global `docs/ASSETS_LEDGER.csv` donne les SHA-256 des fichiers effectivement distribués. Aucun nouveau générateur de voix ni droit de voix supposé.

## Musiques

| Monde | Fichier | Auteur / origine |
|---|---|---|
| 1 Quartier | chill.ogg | omfgdude, montage qubodup — existant |
| 2 Arcades | time_driving.ogg | Kenney, Time Driving |
| 3 Plage | calm.mp3 | wipics — existant |
| 4 Fonderie | downtempo.ogg | Nostromo — existant |
| 5 Jardin | infinite_descent.ogg | Kenney, Infinite Descent |
| 6 Toits, bonus | flowing_rocks.ogg | Kenney, Flowing Rocks |
| 7 Port, bonus | night_beach.ogg | Kenney, Night at the Beach |
| 8 Prairie | farm_frolics.ogg | Kenney, Farm Frolics |
| 9 Alpages | polka_train.ogg | Kenney, Polka Train |
| 10 Stade | alpha_dance.ogg | Kenney, Alpha Dance |

Les sept boucles Kenney sont des Ogg originaux renommés, sans modification. Notice : `assets/licenses/Kenney_Music_Loops.txt`. Distribution consultée : https://www.gamesounds.xyz/?dir=Kenney%27s%20Sound%20Pack/Music%20Loops ; preuve CC0 : https://www.gamesounds.xyz/Kenney%27s%20Sound%20Pack/Music%20Loops/readme.txt . Le fondu de changement de musique existant est conservé.

## Ambiances

| Monde | Fichier | Provenance et transformation |
|---|---|---|
| 1 | birds.ogg | isaiah658, enregistrement d'oiseaux, original renommé |
| 2 | city.ogg | TinyWorlds, Scifi City, original renommé ; ville stylisée, pas une promesse de prise de son réaliste |
| 3 | waves.ogg | jasinski / qubodup, Beach Ocean Waves, FLAC converti Vorbis, courts fondus |
| 4 | loops/machine_04.ogg | rubberduck, fichier déjà présent, inchangé |
| 5 | forest.mp3 | TinyWorlds, Forest Ambience, original renommé |
| 6 | wind.ogg | SketchMan3, wind whoosh loop, original renommé |
| 7 | harbor.ogg | vagues jasinski + machine_04 rubberduck, poids 1 / 0,16, passe-bas 4500 Hz |
| 8 | meadow.ogg | oiseaux isaiah658 + vent SketchMan3, poids 1 / 0,2, passe-haut 120 Hz |
| 9 | alpine.ogg | vent SketchMan3 + pluie Ylmir, poids 1 / 0,08, passe-bas 1800 Hz |
| 10 | stadium.ogg | ville TinyWorlds + ambient_01 rubberduck, poids 1 / 0,22, passe-haut 200 Hz ; ambiance électronique stylisée, **pas** un enregistrement de foule |

Les quatre compositions durent 28 s, sont converties en Vorbis qualité 3 avec FFmpeg et ont des fondus de 0,4 s aux extrémités. Ce sont des compositions de sources libres, non de nouveaux field recordings. Le niveau du lecteur d'ambiance est -28 dB avant volume du bus. Les dix chemins d'ambiance et dix chemins de musique sont distincts et contrôlés par test. Aucun test d'écoute humaine ni validation de haut-parleur de téléphone n'a été effectué.

Pages des sources :
- https://opengameart.org/content/ambient-bird-sounds — isaiah658, CC0.
- https://opengameart.org/content/scifi-city-ambient-loop — TinyWorlds, CC0.
- https://opengameart.org/content/forest-ambience — TinyWorlds, CC0.
- https://opengameart.org/content/beach-ocean-waves — jasinski, dépôt qubodup, CC0.
- https://opengameart.org/content/wind-whoosh-loop — SketchMan3, CC0.
- https://opengameart.org/content/rain-loopable — Ylmir, CC0.
- https://opengameart.org/content/30-cc0-sfx-loops — rubberduck, CC0, déjà présent.

Conditions CC0 1.0 : https://creativecommons.org/publicdomain/zero/1.0/ . Les attributions sont conservées même lorsque la licence ne les impose pas.
