# Direction artistique — lot 2

## Langage commun
Low-poly cartoon, silhouettes simples et volumes mats cohérents avec Mini Skate. Palette : bleu pétrole `#173b48`, crème `#f5f1e8`, vert citron `#b4e76a`, orange pêche et or pour les collectables. Les motifs de menu et les 70 pictogrammes sont des créations du projet, pas des images de marques.

UI : illustration vectorielle de skatepark, PNG quatre états, panneaux et boutons 9-slice, bordure de focus transparente, police libre DejaVu Sans, curseur original, thème centralisé. Contraste foncé sur crème ; objectifs validés par coche, pas seulement par couleur.

## Mondes
1. Initiation : quartier, maisons, arbres, reliefs lointains.
2. Plaza : façade urbaine, lampadaires, volumes de véhicules en périphérie.
3. Half-pipe : mer, sable, palmiers et volumes de jetée.
4. Industrie : entrepôts, conteneurs et silhouettes de grues.
5. Bowl : ciel sombre, étoiles, éclairage et ville périphérique.
6. Toits : parc bonus nocturne, ville et structures de toit.
7. Docks : parc bonus maritime, eau, bâtiments et conteneurs.

`scenery.gd` regroupe les répétitions par mesh/matériau en MultiMesh. Le décor est hors de l'arène, derrière les limites physiques ; ce n'est pas un monde ouvert. Les volumes ont des collisions simplifiées. L'éclairage et l'ambiance changent selon le parc, les ombres sont désactivables via la qualité basse.

## Validation et limites
Captures réelles dans `docs/captures/lot2/`, planches `APERCU_PARCS.jpg` et `APERCU_MENUS.jpg`. Moteur OpenGL, Mesa llvmpipe sous Xvfb : il s'agit d'un rendu réel, pas d'une preuve de performances GPU/mobile. Certains sols maritimes restent très clairs ; pas de validation colorimétrique sur écran de téléphone. Pas de foule animée, de particules de feuilles/lucioles ou de pipeline LOD complet.
