# Recherche comparative — lot 2

Trois bases ont été consultées (README, licence, arborescence et fichiers indiqués). Aucun code de ces jeux n'a été intégré. Leur exécution n'a pas été testée ; seule Grindlish a été exécutée sous Godot 4.3. La recherche du lot 1 n'avait pas été faite avant ses développements : ce retard de méthode est signalé, pas réécrit a posteriori.

| Projet / source | Fichiers étudiés et enseignements | Application à Grindlish |
|---|---|---|
| [3deric/godot-skateboarding-game](https://github.com/3deric/godot-skateboarding-game), code MIT ; assets séparés ; projet déclare Godot 4.5 | `Skategame/Scripts/Player/Player_States/player_grind.gd` : position sur chemin, tangente et normale du rail, équilibre, boucle et sortie aux extrémités | Vérification de la séparation entre rail logique et représentation ; conservation du contrôleur existant, pas d'import de scripts ni d'assets |
| [TinyBitAdventures/not-pro-skater](https://github.com/TinyBitAdventures/not-pro-skater), MIT ; projet déclare des fonctionnalités 4.7 | `game/scripts/camera/chase_camera.gd` : cap suivant la vitesse et non les spins, maintien vertical, FOV, collision caméra par sphère avec repli rayon | Caméra existante sécurisée par rayons avant/après interpolation ; un vrai balayage sphérique reste une amélioration |
| [Godot demo projects, branche 4.3](https://github.com/godotengine/godot-demo-projects/tree/4.3/3d/kinematic_character), MIT | `player/cubio.gd`, `player/follow_camera.gd` : CharacterBody3D, accélération/freinage, gravité, remise en position, caméra distance/hauteur | Référence compatible avec le moteur cible ; intégration originale d'une capsule, des contrôles d'espace libre et du graphe de parcours |

## Décisions techniques
- Pas de migration vers une version plus récente : Godot **4.3.stable.official.77dcf97d8**, rendu Compatibility.
- Route A* conservatrice sur sol plat et libre : les lettres/pièces sont déplacées sur des positions connectées. Cela garantit des itinéraires simples, pas des lettres spectaculaires en vol au-dessus des rails.
- Décors originaux en géométrie low-poly et MultiMesh, plutôt qu'un mélange de packs de styles ou de licences différents.
- Voix anglaise américaine unique, synthèse locale Piper/LJSpeech. Aucun appel à Forvo ou à une API vocale propriétaire.
- Musiques/SFX téléchargés avec sources et notices : voir `CREDITS.md` et le registre SHA-256.

## Nom et risques
Recherche web initiale puis nouvelle requête exacte « Grindlish » avec game/itch/Steam/Google Play : disponibilité non établie. Aucune recherche exhaustive de marques, aucun compte développeur ni réservation de nom. **Grindlish reste provisoire** ; ne pas présenter ce travail comme une validation juridique. Les alternatives du cahier des charges ne sont pas davantage vérifiées.
