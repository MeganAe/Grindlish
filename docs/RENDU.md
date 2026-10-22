# Rendu et dix mondes — 20 octobre 2026

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

| Suite | Contrôles passés |
|---|---:|
| learning | 210 |
| systems | 104 |
| modes | 70 |
| safety | 10 |
| life | 139 |
| flow | 17 |
| save_density | 3 |

- Vie : dix mondes × trois densités × 60 s de simulation, 20 contrôles de mouvement par seconde ; 1 000 segments supplémentaires par combinaison pour comparer index spatial et balayage exhaustif. Aucune intrusion d'agent dans l'arène, aucun balayage invalide, chevauchement solide, chevauchement entre agents ni contact avec le skateur dans cette matrice. Détails par cas : `rendu/tests/life_details.json`.
- Chevauchements physiques sondés chaque seconde ; balayages/évitement contrôlés à chaque pas. Cela reste une matrice déterministe de tests, **pas** une preuve mathématique pour tous les états ni un test de tous les triangles de décor non solide.
- Ancienne sauvegarde sans champ de densité : progression/monnaie/records conservés ; aller-retour de densité et clamp contrôlés dans un dossier utilisateur isolé. Aucun fichier de sauvegarde utilisateur normal touché.
- Routes et sept modes testés sur les dix parcs par le pilote réel, sans téléporter le skateur pour finir le mot. La suite learning reste la couverture des 70 mots d'origine ; elle ne constitue pas une matrice exhaustive de tous les mots sur tous les mondes.
- Les captures et nouvelles options ont ensuite été contrôlées en rendu OpenGL réel. Les tests de logique headless ne servent jamais de preuve graphique ou de mesure FPS.

## Captures et comparaisons

40 captures après : sept parcs existants aux mêmes flags/frame que la référence, trois nouveaux parcs, tous les quinze écrans de référence, HUD tactile, dix vues d'ensemble, trois qualités et tactile 1920 × 1080. Journaux, recettes et SHA dans `rendu/apres/`. Aucun rendu n'est une illustration générée.

- Planche des dix mondes : `rendu/MONDES.jpg`.
- Comparaisons de chacun des 23 cas initiaux : `rendu/comparaisons/avant_apres_01.jpg` à `06.jpg`.
- Lecture sans dépendance réseau : `RENDU.html`.
- Vidéo de vie périphérique : `rendu/vie_peripherique.mp4`, capture hors ligne à cadence encodée 30, non une mesure de fluidité matérielle.
- Les vues d’ensemble 2 et 6 utilisent une caméra de démonstration sud pour éviter de cadrer derrière une façade ; les 23 comparaisons avec la référence gardent leurs recettes initiales.

## FPS réellement mesurés

**VM Linux, Mesa llvmpipe logiciel, OpenGL Compatibility, 1280 × 720, audio Dummy. Ce ne sont ni un GPU de PC cible ni un téléphone.** Les essais après utilisent LP_NUM_THREADS=2 ; les parcs 1 et 5 de la référence ont aussi été restaurés depuis le commit de gel et remesurés sur 480 pas physiques avec ce même réglage. Les références initiales 1/5 sans cette variable restent conservées. Le dernier chiffre de drawcalls peut correspondre à une position de caméra différente en fin de parcours non synchronisé ; ne pas le traiter comme un profil GPU à point fixe.

| Phase | Journal / réglage | FPS médian des échantillons |
|---|---|---:|
| avant | `fps_parc_1.log` | 5.0 |
| avant | `fps_parc_5.log` | 5.0 |
| avant | `fps_threads2_full_parc_1.log` | 6.0 |
| avant | `fps_threads2_full_parc_5.log` | 5.0 |
| avant | `fps_threads2_parc_1.log` | 5.0 |
| après | `fps_parc_10_q0_d0.log` | 16.0 |
| après | `fps_parc_10_q1_d1.log` | 6.0 |
| après | `fps_parc_10_q2_d2.log` | 6.0 |
| après | `fps_parc_1_q1_d1.log` | 6.0 |
| après | `fps_parc_5_q1_d1.log` | 6.0 |
| après | `fps_parc_9_q1_d1.log` | 6.0 |

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
