# Vocabulaire et méthode — lot 2

70 mots externes, cinq thèmes de 14 mots : 60 A1/A2 et 10 nouveaux mots indicatifs B1. **Ce classement est éditorial, non certifié CECRL et non calibré par une étude pédagogique.** Il nécessite une relecture par un enseignant avant utilisation en classe.

## Données
`data/words.json` : tableau de dictionnaires `word`, `fr`, `theme`, `level`, `definition`, `example`, `audio`, `image`. Mot ASCII minuscule de 1–12 lettres, unique ; thèmes skate/town/sea/industry/night. Images et WAV référencés par `res://`. Les 70 fichiers audio et pictogrammes sont présents et contrôlés par le test systems.

Import professeur : JSON local via le sélecteur. Données copiées vers `user://custom_words.json`, original conservé ; import invalidé et annulé si des entrées sont rejetées. Maximum 500 entrées. Aucune limite de taille en octets n’est encore imposée : n’importer que de petits fichiers de confiance. `audio`/`image` sont des chemins locaux facultatifs, pas des URL téléchargées ; un enseignant doit fournir des droits et fichiers valides. Le ZIP source ne modifie pas le paquet Android pour ajouter des ressources. Restaurer les mots d'origine ne supprime pas le carnet.

## Pédagogie réelle
- Un mot par session ; lettres au sol sur chemin sûr, ordre optionnel. Pas de lettres leurres ni de séquences de plusieurs mots dans un même run bonus.
- Le mot complété est découvert, prononcé et présenté au quiz. Question traduction à trois choix, prioritairement même niveau/thème, possibilité de passer. La définition/exemple sont des aides : ce n'est pas un examen à l'aveugle.
- Maîtrise 0–5 : réussite +1, erreur −1. Prochaine échéance après réussite : 1, 2, 4, 8 ou 16 jours selon la maîtrise ; erreur immédiatement due. Tri des mots dus par maîtrise puis date. « Réviser maintenant » enchaîne les mots dus ; sortie toujours disponible.
- CSV local : progression par mot, maîtrise, tentatives, bonnes réponses et échéance. Pas de nom d'élève, de compte ou de télémétrie.
- PIN 4–8 chiffres haché SHA-256 avec sel constant : simple verrou d'interface, **pas un contrôle de sécurité ni du chiffrement**.

## Sens ambigus et prononciation
`board` = planche, `rail` = barre de grind, `trick` = figure, `ride` = balade, `crane` = grue de chantier, `light` = lumière, `dream` = rêve de sommeil ; `current` = courant d'eau, `harbor` = port (orthographe américaine), `reflect` = refléter la lumière. Les traductions sont contextuelles, pas universelles. Le B1 comprend aussi balance, protect, traffic, journey, repair, material et silence ; certaines entrées peuvent être abordées plus tôt selon le programme.

Voix US unique : Piper local, modèle `en_US-ljspeech-medium`, jeu de données LJSpeech public domain. WAV générés, pas de services propriétaires ni d'enregistrement humain revendiqué. Sources et limites juridiques détaillées dans `CREDITS.md`. Le test de mix prouve un signal numérique non silencieux, pas la qualité d'accent sur un haut-parleur.

## Liste
| Mot | Français (sens choisi) | Thème | Niveau indicatif |
|---|---|---|---|
| board | planche | skate | A1 |
| wheel | roue | skate | A1 |
| rail | barre | skate | A1 |
| jump | saut | skate | A1 |
| trick | figure | skate | A1 |
| speed | vitesse | skate | A1 |
| turn | virage | skate | A1 |
| helmet | casque | skate | A1 |
| knee | genou | skate | A1 |
| shoe | chaussure | skate | A1 |
| push | poussée | skate | A1 |
| ride | balade | skate | A1 |
| street | rue | town | A1 |
| bench | banc | town | A1 |
| shop | boutique | town | A1 |
| car | voiture | town | A1 |
| tree | arbre | town | A1 |
| house | maison | town | A1 |
| park | parc | town | A1 |
| road | route | town | A1 |
| door | porte | town | A1 |
| window | fenêtre | town | A1 |
| school | école | town | A1 |
| friend | ami | town | A1 |
| beach | plage | sea | A1 |
| wave | vague | sea | A1 |
| sand | sable | sea | A1 |
| shell | coquillage | sea | A1 |
| boat | bateau | sea | A1 |
| sea | mer | sea | A1 |
| sun | soleil | sea | A1 |
| fish | poisson | sea | A1 |
| water | eau | sea | A1 |
| wind | vent | sea | A1 |
| bird | oiseau | sea | A1 |
| sky | ciel | sea | A1 |
| truck | camion | industry | A2 |
| crane | grue | industry | A2 |
| metal | métal | industry | A2 |
| factory | usine | industry | A2 |
| bridge | pont | industry | A2 |
| worker | ouvrier | industry | A2 |
| tool | outil | industry | A2 |
| wood | bois | industry | A2 |
| brick | brique | industry | A2 |
| roof | toit | industry | A2 |
| gate | portail | industry | A2 |
| machine | machine | industry | A2 |
| light | lumière | night | A2 |
| star | étoile | night | A2 |
| moon | lune | night | A2 |
| night | nuit | night | A2 |
| city | ville | night | A2 |
| shadow | ombre | night | A2 |
| cloud | nuage | night | A2 |
| dream | rêve | night | A2 |
| sound | son | night | A2 |
| music | musique | night | A2 |
| evening | soirée | night | A2 |
| lamp | lampe | night | A2 |
| balance | équilibre | skate | B1 |
| protect | protéger | skate | B1 |
| traffic | circulation routière | town | B1 |
| journey | voyage | town | B1 |
| current | courant d’eau | sea | B1 |
| harbor | port | sea | B1 |
| repair | réparer | industry | B1 |
| material | matériau | industry | B1 |
| reflect | refléter | night | B1 |
| silence | silence | night | B1 |
