# Grindlish — lot 2, version 0.2.0

**Livraison jouable enrichie, pas certification d'un jeu commercial fini.** Godot **4.3.stable.official.77dcf97d8**, OpenGL Compatibility. Rapport historique conservé : `REPORT_LOT1.md`.

## Fait
- Recherche de trois projets et lecture de fichiers ciblés, sans copie de code : `RESEARCH.md`.
- Graphe A*, 12 positions sûres/connectées, pilote par entrées réelles ; contrôle de capsule/respawn/limites, collisions double-face et rayons caméra avant/après interpolation.
- Sept parcs dont deux bonus ; décors low-poly originaux en MultiMesh, éclairages et ambiances différenciés.
- Objectifs permanents mot/score/combo, étoiles explicables, briefings Max/Lou et tutoriel progressif passable au clavier.
- **70 mots**, pictogrammes et prononciations US synthétisées localement ; A1/A2 et dix entrées B1 indicatives. Ordre, indices, filtre de niveau, sans chrono/sans chute.
- Quiz facultatif au mot terminé ; carnet et révisions effectivement sélectionnées par échéance ; professeur/PIN, CSV et import JSON avec restauration en cas de rejet.
- Sept modes : carrière, jam, mot, combo, collecte, journalier et libre. Stockage des records séparé par mode/parc et aides ; écran de classement complet restant à faire.
- Garage, améliorations et styles ; **aperçu 3D animé/rotatif avant achat**. Remappage clavier/manette, affichage des associations et rétablissement.
- UI illustrée : quatre états de boutons, 9-slice, focus, police libre, curseur, transitions ; **195 chaînes FR/EN**, dont des modèles dynamiques. Certains fragments restent non traduits.
- Audio par fichiers, bus Music/SFX/Interface/Voice/Ambience, fondu et atténuation sous la voix. Arrêt et nettoyage explicite. Trois musiques partagées ; effets et boucles stylisés, pas tous des enregistrements de skate.
- Tactile multi-index, relâchement en pause, gaucher/taille, safe area, qualité/ombres et cap 30/60 FPS. Notifications retour/pause Android.
- Sauvegarde compatible avec section v2, migration, `.tmp` et `.bak`, flags historiques conservés ; crédits et registre SHA-256.
- **Exports réellement générés** : Windows x86_64 release (icônes/métadonnées PE contrôlées), Android ARM64 debug signé (signature, contenu et permissions contrôlés).

## Preuves
`tools/run_tests.py`, `docs/tests/lot2/manifest.json`, `render_manifest.json` et logs bruts.

| Vérification | Résultat | Portée réelle |
|---|---|---|
| Import 4.3 | code 0, pas d'erreur | Scripts et assets importables |
| Apprentissage physique | **210 contrôles, 0 échec** | 70 mots parcourus dans leur parc thématique, déplacement et collecte réels |
| Fuzz collisions | **7 contrôles agrégés, 0 échec** | 1 050 trajectoires, 252 000 frames ; finitude, sol, limites, recouvrement, immobilisation et respawn |
| Systèmes | **104 contrôles, 0 échec** | 70 couples audio/image, échéances, pause, tactile synthétique, transactions, aperçu sans débit, remappage/reset, EN et B1 |
| Mix audio numérique | **4 signaux non silencieux** | Effet, voix, musique et roulement ; pas une écoute humaine |
| Modes | **49 contrôles, 0 échec** | Sept modes × sept parcs, pilote physique ; libre terminé explicitement après le mot |
| Flux | **17 OK, 0 FAIL** | Navigation, pause/options/reprise, fin, déblocage, boutique ; fixture pour les trois étoiles |
| OpenGL | **28 captures**, zéro erreur console | Sept parcs, écrans, anglais et tactile 2400×1080 / 1920×1080 / 2560×1600 / 1280×720 ; dimensions du raster vérifiées |
| Flux OpenGL | **17 OK, 0 FAIL** | Même navigation sous Mesa/Xvfb, pas fixe ; avertissement V-Sync du pilote logiciel seulement |
| Windows / Android | exports et contrôles structurels réussis | Aucune exécution Windows native ni installation sur téléphone |

Total des suites métier : **370 contrôles, 0 échec**, plus le flux. Les diagnostics antérieurs sont historiques. Les Label3D sont omis uniquement dans le renderer dummy headless à cause d'un bug de destruction 4.3 ; nœuds collectables et physique inchangés, glyphes vérifiés en OpenGL.

### Limites des tests
Le fuzz démarre sur des positions libres à vitesse initiale 4–32 m/s, ensuite régulée. Ce n'est pas un boost permanent ni un test exhaustif de chaque jonction/rail/sommet de half-pipe. Le recouvrement utilise une capsule réduite ; un trimesh ouvert n'est pas un solide volumétrique parfait. **Aucune promesse universelle « zéro passe-à-travers ».** La combinaison complète 70 mots × 7 parcs × 7 modes n'a pas été exécutée. Les lettres sont prudemment au sol, pas en vol au-dessus des rails. Les captures d'écrans utilisent des fixtures, pas toutes des manches gagnées.

## Reste du cahier des charges
1. Campagne réellement scénarisée/animée (boutique menacée, rival, scènes), chargement dédié et tutoriel adapté aux gestes tactiles/manette.
2. Calibrage CECRL/relecture enseignante ; mini-jeux écoute/épelle et mot/image ; plusieurs mots par run bonus, leurres, indices payants et vitesse d'apparition réglable.
3. Derniers fragments de localisation/messages techniques ; rafraîchissement immédiat de tous les textes après changement de langue.
4. Son de skate documenté, pushs, sélection d'atterrissage par surface, ambiances plus spécifiques, transitions/jingles victoire-défaite complètes et écoute humaine.
5. Tests segment par segment des rails, anti-tunneling extrême et caméra par balayage sphérique ; compléter la couverture topologique.
6. Particules, passants animés, LOD/distance et lumière sur appareils ; classement complet par mode.
7. Windows/Android natifs, manette/tactile/audio physiques, vrais safe areas/48 dp, appels/reprise, mémoire, batterie, thermique et FPS. iOS non réalisé.
8. Signature de publication, identifiant de studio, SDK cible exigé par le store au moment de publier et contrôle de marque « Grindlish ».

## Risques
- APK **debug**, pas Play Store ; Windows sans Authenticode, SmartScreen possible. Aucun matériel cible connecté.
- PIN SHA-256 à sel constant : verrou d'interface, **pas chiffrement**. Petits JSON de confiance seulement : 500 entrées maximum, limite octets non imposée.
- B1 indicatif, pas certification CECRL. Voix issue d'un modèle déclaré domaine public ; sources et nuances dans `CREDITS.md`.
- Mesa llvmpipe/Xvfb ne prouve pas 60 FPS PC ou 30–60 FPS mobile. Nom commercial et droits globaux de publication à confirmer.
- Le premier post-traitement PE consommait trop de mémoire et a bloqué l'environnement. Il a été abandonné ; export Windows refait puis patch mmap à mémoire bornée, six icônes et checksum vérifiés. Aucun binaire intermédiaire n'est à diffuser.

Livrables : source ZIP sans `.godot/`, Windows exe+pck en ZIP, APK séparé, planches d'aperçu, guides et preuves. `build/` contient les sorties locales générées, ignorées par Git ; copies distribuées hors de ce dossier.
