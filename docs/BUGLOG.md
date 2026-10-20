# Bugs — correctifs cumulés, lots 1 et 2

| Problème | Cause | Correction et preuve |
|---|---|---|
| SKATE fixe, lettres de mots longs hors parcours | cinq coordonnées d'origine et absence de validation de chemin | 12 positions sûres, graphe A*, collecte physique ; `learning.log`, 70 mots |
| Respawn ou collectable dans un obstacle | point réutilisé sans validation de capsule/sol | requêtes physiques d'espace libre, origine et repli sûrs ; `safety.log` |
| Sortie du parc à grande vitesse | capsule dépassant la limite rectangulaire | marge de capsule et correction de limite ; sept parcs sans anomalie dans le fuzz |
| Faces arrière de rampes ignorées | trimesh à sens unique | collisions double-face ; pas une preuve topologique exhaustive de toutes les jonctions |
| Caméra traverse/voit derrière un mur | interpolation après contrôle unique | rayons avant/après interpolation, repli vertical si trop proche ; pas encore de balayage sphérique |
| Sons persistent après fin/quiz | boucles non arrêtées | arrêt des boucles, arrêt à la fin, pause du mix pendant quiz ; tests audio et captures |
| Interface muette en pause | garde globale bloquant aussi les clics | exception pour clic/retour/achat/refus |
| Ogg/texture restent vivants à la fermeture | libération trop tardive, curseur natif gardant sa texture, duplication des streams | retrait du curseur, streams libérés, arrêt explicite puis frames de nettoyage avant quit ; dernières sorties vérifiées |
| `mesh_get_surface_count(null)` headless | comportement du renderer dummy 4.3 lors de la destruction | détachement explicite des meshes ; seul le visuel Label3D est omis en headless. Les nœuds collectables/physiques sont identiques ; glyphes vérifiés en OpenGL |
| Tactile reste pressé en pause | événements retenus dans plusieurs doigts | `release_all`, garde de pause et suivi des index ; tests synthétiques pression/relâchement |
| Chrono avance hors focus | pas de gestion de focus | pause hors focus en usage normal ; désactivée dans le harnais/captures |
| Sauvegarde écrasée directement | écriture non transactionnelle | temporaire puis renommage, copie `.bak`, chargement secondaire, migration de l'ancien dossier |
| Reset remappage conserve une ancienne touche | événements ajoutés sans effacement | effacement puis reconstruction des valeurs par défaut ; test touche J → espace |
| Achat répété refacture un style | besoin d'un chemin de transaction commun | garde de propriété ; essais monnaie insuffisante, achat exact, rééquipement gratuit |
| Troisième réponse du quiz sous le panneau | titre/image/boutons trop hauts | compactage local du quiz, scroller conservé pour textes longs |
| CSV du registre importé comme traduction | import automatique de Godot sur `.csv` | `docs/.gdignore` ; catalogue UI seul sous `data/i18n` |

Les anciens logs de lot 1 restent historiques. Ils ne remplacent pas les logs de lot 2. Un essai d'import intermédiaire a échoué sur un mauvais nom de méthode de reset ; corrigé avant les tests finaux et les exports. Un premier harnais final a été interrompu après ce changement ; les preuves finales sont celles du manifeste courant.

Post-traitement Windows : réécriture globale PE trop gourmande en mémoire, abandonnée après blocage de l’environnement. Export refait depuis le template, remplacement par écritures mmap bornées, checksum contrôlé par une seconde implémentation. Aucun exe intermédiaire diffusé.

Matrice mobile : les premières captures étaient encore à 1280×720 malgré --res. Correction via la taille de la Window Godot et écran Xvfb assez grand ; le harnais contrôle maintenant les dimensions PNG, pas seulement le code de sortie.
