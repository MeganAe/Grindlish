# Builds, mobile et reproduction

## Exports réellement produits
- Windows x86_64, release Godot 4.3 : `build/windows/Grindlish.exe` et `.pck`, distribués ensemble dans l'archive Windows.
- Android ARM64, APK **debug signé**, version 0.2.0 / code 2, identifiant provisoire `org.grindlish.prototype`. Pas un paquet de publication ; clé debug non livrée.
- Templates officiels 4.3 utilisés. L'environnement d'export de ce lot utilise OpenJDK 21 et Android SDK 34 ; les dépendances ne sont pas contenues dans le projet source.
- Permission Internet/réseau désactivée. Aucun suivi. Orientation paysage. L'APK ne remplace pas une installation/test sur téléphone.

## Refaire les exports
Installer Godot 4.3 stable et les modèles EXACTS 4.3, puis SDK/JDK et configuration Android selon la documentation [Godot 4.3](https://docs.godotengine.org/en/4.3/tutorials/export/exporting_for_android.html). Éviter de réutiliser une clé debug pour un store.

```sh
mkdir -p build/windows build/android
godot --headless --path . --editor --import --quit
godot --headless --path . --export-release 'Windows Desktop' build/windows/Grindlish.exe
godot --headless --path . --export-debug Android build/android/Grindlish-debug.apk
# Post-traitement Windows sur Linux, dependances de developpement uniquement :
python3 -m pip install pillow pefile
godot --headless --path . --script res://tools/export_icon.gd
python3 tools/patch_windows.py
adb install -r build/android/Grindlish-debug.apk
```

La dernière commande est un guide : **aucun appareil n'était connecté**, elle n'a pas été exécutée avec succès ici. Le dossier `build/` est généré/ignoré ; les binaires livrés sont à télécharger séparément.

## Travail mobile fait
Safe area système et recalcul au redimensionnement ; tactile multi-index ; relâchement global à la pause ; option gaucher et taille ; qualité 0.65/0.85/1.0 et ombres, cap 30/60 FPS ; notifications retour Android/pause application. Contrôles AZERTY physiques, manette et remappage conservés.

Matrice de **rendu réel** avec tactile simulé : 2400×1080, 1920×1080, 2560×1600, 1280×720. Les captures et logs sont fournis. Tests d'événements tactiles synthétiques : pas de vitre, pas de doigts réels et pas de mesure dp réelle. Le simulateur desktop ne fournit pas d'encoche Android ; les safe areas physiques restent à contrôler.

## Non validé
Windows natif, Android matériel, iOS, manette physique, son au haut-parleur/casque, 48 dp sur appareils, appels/reprise Android réelle, thermique, batterie, mémoire et FPS GPU. Le renderer logiciel du serveur ne permet pas de promettre 60 FPS PC ou 30–60 FPS mobile.

Windows : fichier non signé Authenticode. Le post-traitement remplace les six icônes PE et métadonnées sans modifier les sections de code ; type PE, capacités des ressources et checksum vérifiés, pas le lancement natif.
