# <img src="assets/KeyBalloons.svg" alt="Icône de Key Balloons" width="36"> Key Balloons

[English](README.md) · [简体中文](README.zh.md) · [繁體中文](README.zh-TW.md) · [Français](README.fr.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Español](README.es.md)

Key Balloons affiche un boîtier flottant sur macOS et Windows. Lorsque vous tapez dans une application, les touches s’élèvent au-dessus du boîtier puis disparaissent en deux secondes environ. Chaque frappe a sa propre animation, même si vous répétez la même touche.

**[Télécharger](https://github.com/boomsi/key-balloons/releases)** · [Installation](#installation) · [Utilisation](#utilisation) · [Compilation depuis les sources](#compilation-depuis-les-sources) · [Guide d’intégration](docs/mouse-feedback.fr.md)

![Démonstration de Key Balloons : les touches flottent à mesure que l’on saisit kissmenow](assets/key-balloons-demo.gif)

> Les frappes servent à afficher les animations sur votre appareil. L’application ne conserve aucun historique des frappes et ne les transmet pas sur le réseau.

## Installation

Téléchargez le programme correspondant à votre système depuis [GitHub Releases](https://github.com/boomsi/key-balloons/releases).

| Plateforme | Étapes d’installation |
| --- | --- |
| macOS | Ouvrez le fichier universel `.dmg`, glissez **KeyBalloons.app** dans Applications puis ouvrez-le depuis ce dossier. |
| Windows | Lancez le programme d’installation x64 `.exe`, puis ouvrez **Key Balloons** depuis le menu Démarrer. |

### Surveillance de l’entrée sur macOS

1. Si une autorisation est demandée au démarrage, cliquez sur **Ouvrir la surveillance de l’entrée**. Vous pouvez aussi choisir **Activer la surveillance…** dans la barre des menus.
2. Dans Réglages Système → Confidentialité et sécurité → Surveillance de l’entrée, glissez l’icône Key Balloons de la carte d’aide vers la liste.
3. Activez l’interrupteur. La carte se ferme dès que l’application détecte l’autorisation. Si macOS vous invite à quitter puis à rouvrir l’application, suivez cette indication.

Après une mise à jour, utilisez **−** pour retirer une éventuelle ancienne entrée, puis ajoutez et autorisez la version actuelle.

## Utilisation

Tapez dans votre application habituelle. Le boîtier reste au premier plan et affiche un libellé par frappe.

Les clics gauche et droit éclairent leur côté. Le défilement ou le clic sur la molette éclaire le centre. Dans **Avancé**, activez les [intégrations locales de la souris](docs/mouse-feedback.fr.md).

### Réglages

Faites un clic droit sur le boîtier ou choisissez **Settings… (Réglages…)** dans la barre des menus ou la zone de notification pour ouvrir le même panneau.

- Dans **Apparence**, **Taille** (50 % à 150 %) et **Opacité** (20 % à 100 %) s’appliquent au boîtier et aux libellés.
- Dans **Position**, activez **Autoriser le déplacement** pour déplacer le boîtier avec le bouton gauche. **Ancrer en bas de l’écran** le place au bas de la zone utilisable de l’écran le plus proche lorsque vous le relâchez.
- **Langue** change immédiatement l’interface et mémorise votre choix. L’anglais est la langue par défaut.
- Le menu affiche la mémoire utilisée par l’application et l’état de la surveillance. Il sert aussi à suspendre ou reprendre la surveillance et à quitter.

Sur macOS 26, une compilation avec Xcode 26 ou une version ultérieure utilise un panneau Liquid Glass avec des commandes natives. Lorsque vous changez d’espace sur macOS, le boîtier et les animations gardent leur position.

## Compilation depuis les sources

Installez CMake 3.21 ou ultérieur, le SDK de bureau Qt 6.10 avec Qt Quick, Qt Quick Test et les outils Qt Linguist, ainsi que Xcode ou les outils C++ de Visual Studio 2022. Les commandes utilisent Qt 6.10.3.

### macOS

```sh
cmake -S . -B build \
  -DCMAKE_BUILD_TYPE=Release \
  -DKEY_BALLOONS_DEVELOPMENT_BUILD=ON \
  -DCMAKE_PREFIX_PATH="$HOME/Qt/6.10.3/macos"
cmake --build build --parallel
ctest --test-dir build --output-on-failure
open build/KeyBalloonsDev.app
```

### Windows (PowerShell)

```powershell
$qt = "$env:USERPROFILE/Qt/6.10.3/msvc2022_64"
$env:Path = "$qt/bin;$env:Path"
cmake -S . -B build -A x64 "-DCMAKE_PREFIX_PATH=$qt"
cmake --build build --config Release --parallel
ctest --test-dir build --build-config Release --output-on-failure
& "./build/Release/KeyBalloons.exe"
```

## Programmes d’installation des versions

La publication d’une version sur GitHub lance **Release installers**. Le workflow compile le code du tag, exécute les tests, puis joint le `.dmg` universel pour macOS et le `.exe` x64 pour Windows après vérification.

Pour tester le paquet, choisissez **Actions → Release installers → Run workflow**. Les deux programmes figurent sous **Artifacts**. Le paquet macOS utilise une signature ad hoc. La notarisation Apple et la signature de publication Windows nécessitent leurs propres identifiants.

## Organisation et tests

- [`examples/basic-box/`](examples/basic-box/) contient l’exemple du boîtier intégré, ses animations et son abonné au retour visuel de la souris.
- `src/macos/` et `src/windows/` gèrent les entrées de chaque plateforme. Le module macOS fournit aussi les réglages natifs et l’assistant de surveillance.
- `tests/tst_balloons.qml` couvre la frappe rapide, la disparition indépendante, le déplacement, la souris et les réglages. `tests/tst_overlay_core.cpp` couvre le placement, l’intégration locale, les traductions et la mémoire.
- `tests/tst_stress.qml` simule 20 entrées par seconde pendant 30 secondes. Il relève le 95e percentile de l’intervalle entre images et du délai entre la création d’un libellé et l’image Qt suivante. La latence physique doit être mesurée séparément.

Exécutez le test d’animation prolongé dans une session de bureau.

```sh
./build/key_balloons_tests -input tests/tst_stress.qml
```

Sous Windows, utilisez `./build/Release/key_balloons_tests.exe`. Pour un contrôle rapide, tapez `A A B` dans TextEdit ou le Bloc-notes. L’éditeur doit garder le focus et les trois libellés doivent disparaître séparément. Voir la [liste des vérifications](TODO.fr.md).
