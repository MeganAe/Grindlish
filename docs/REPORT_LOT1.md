# Grindlish — rapport de livraison, lot 1

## Fait
- Import et exécution Godot **4.3.stable.official.77dcf97d8**, OpenGL Compatibility.
- Nom et icône originaux, navigation quatre modes et aide aux règles.
- 60 entrées de vocabulaire FR/EN externes, cinq thèmes ; lettres et HUD à longueur variable (12 cases max).
- Mot par thème, découverte locale, carnet, quiz, maîtrise 0–5, calcul d'échéance.
- Carrière originale conservée ; Jam, défi du mot, sans pression ajoutés.
- Décors géométriques originaux autour des cinq parcs : arbres/conifères, volumes urbains, eau et conteneurs suivant le parc. Première passe, pas une direction artistique finale.
- Rayons caméra avant et après interpolation, collisions double-face des rampes, respawn testé par capsule, libération du nœud temporaire du sol.
- Pause perte de focus hors harnais automatisé ; sauvegarde temporaire + sauvegarde précédente.

## Preuves et limites
- `flow_final.log` : **17 OK, 0 FAIL**, headless, pas fixe.
- `collision.log` : **500 trajectoires** déterministes (100/parc), 90 frames chacune, **0 anomalie** pour nombres non finis, sous-sol y < -0,5 et limites.
- Ce fuzz ne teste **pas** l'intérieur des solides, immobilisation >3s, chaque pièce individuellement ni l'accessibilité des collectables. Ce n'est PAS la preuve « zéro passe-à-travers » du cahier des charges.
- `vocabulary_final.log` : 60 mots, unicité/champs essentiels/longueur, callbacks de collecte sur cinq parcs et modification de maîtrise. La collecte est appelée directement : **pas une preuve d'accès par autopilote**.
- Captures réelles OpenGL via Mesa llvmpipe/Xvfb : cinq parcs et neuf écrans. Planches regardées ; texte blanc sur panneau clair des nouvelles pages corrigé après inspection.
- Un essai de flux en rendu logiciel sans pas fixe a échoué sur plusieurs attentes temporelles ; le résultat n'est pas présenté comme validé. Voir BUGLOG.
- Headless Godot 4.3 : messages `mesh_get_surface_count: Parameter m is null` du renderer dummy à la destruction. Non observés dans les captures OpenGL. Avertissement ObjectDB à la sortie encore à investiguer.
- Pas de mesure FPS matériel : llvmpipe n'est pas représentatif d'un PC/mobile.

## Reste, explicitement
La demande complète n'est PAS achevée. Restent : recherche comparative de 3–5 projets, validation approfondie des collisions et des rails, preuve de parcours autopilote, vrais enregistrements audio et musiques, UI illustrée/9-slice (StyleBoxFlat conservé), niveaux bonus, vraie campagne/scénario animé et tutoriel guidé, B1 calibré, leurres/ordre/indices, quiz automatique en fin de mot, planification effective des révisions, modes combo/collecte/journalier, records séparés, professeur/CSV/PIN, boutique 3D, accessibilité avancée, contrôles remappables, qualité mobile et safe area, traduction complète, exports Windows et Android.

Le mot peut avoir plus de cinq lettres : les emplacements supplémentaires sont décalés depuis ceux du parc, sans validation de chemin. Ne pas livrer à des élèves avant contrôle de chacun des 60 parcours.

## Risques
- Nom Grindlish provisoire : recherche web générale sans résultat exact évident, pas de vérification exhaustive de marques ou de stores ; aucune garantie juridique.
- Licences : les modèles portent une licence CC0 incluse ; pas de nouvel asset téléchargé.
- Pas de tests physiques manette, Android/iOS, son matériel ni installation Windows.
