# Équilibrage et règles — 0.2.0

- Carrière : mot complet = première étoile ; score cible atteint = deuxième ; meilleur combo ≥ 400 = troisième. Au moins une étoile ouvre le parc suivant. Les seuils de score restent propres à chaque parc.
- Lettre : +250 ; mot complet : +3000 ; pièce : +10. Les mots longs valent davantage : compromis connu, pas une mesure normalisée des acquis.
- Chute : combo perdu et pénalité de 2 s. L'assistance « sans chute » bloque cette sanction, pas les collisions physiques.
- Jam : meilleur score au chrono. Défi du mot : temps de complétion, budget 180 s. Combo : meilleur combo uniquement. Collecte : temps pour toutes les pièces. Journalier : mot stable par date locale et parc. Libre : pas de chrono, fin via pause, aucune récompense de carrière.
- Records séparés `mode:parc` ; suffixe `:assist` quand sans chute/sans chrono. Les records word/collect sont minimisés ; score/combo sont maximisés. Aucun serveur ou classement mondial.
- Les révisions ne conditionnent jamais les étoiles et on peut passer le quiz.

## Preuve et limites
Le pilote automatique utilise des entrées de déplacement, pas des callbacks de collecte ou de la téléportation. Le parcours des mots reste prudent sur terrain plat. Les 49 couples mode/parc sont essayés physiquement. Ce n'est ni une étude du ressenti d'un enfant ni une validation de tous les styles de jeu.

À calibrer avec humains : prix des améliorations, courbe de difficulté, temps par mot, exploitation des scores, vocabulaire et lisibilité. Le mode libre finit explicitement via `end_now()` dans le harnais : ce n'est pas un mode à objectif terminal implicite.
