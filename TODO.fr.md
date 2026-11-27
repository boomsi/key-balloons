# Key Balloons

[English](TODO.en.md) · [简体中文](TODO.md) · [繁體中文](TODO.zh-TW.md) · [Français](TODO.fr.md) · [日本語](TODO.ja.md) · [한국어](TODO.ko.md) · [Español](TODO.es.md)

## Première version

- [x] Utiliser C++ et Qt Quick pour le code commun. Réserver les événements système et la gestion des fenêtres au code propre à chaque plateforme.
- [x] Automatiser les tests de frappes répétées, de disparition indépendante et de saisie rapide.
- [x] Créer le boîtier translucide au premier plan et les libellés qui montent et s’effacent chacun en trois secondes.
- [x] Ajouter la surveillance globale du clavier, la mise en pause et la fermeture sur macOS et Windows.
- [x] Compiler sur macOS, exécuter les tests d’animation et analyser QML statiquement.
- [x] Sur macOS, vérifier que le boîtier reste au-dessus, laisse le focus à la fenêtre d’origine et transmet les clics à la fenêtre en dessous.
- [x] Sur macOS, simuler 20 entrées par seconde pendant 30 secondes. Les 600 libellés ont été créés puis libérés. Au plus 59 étaient visibles en même temps. Le 95e percentile entre la création et l’image Qt suivante était de 12 ms.
- [x] Mesurer le processeur au repos sur macOS. Les deux relevés donnent 0,0 %.
- [x] Compiler et exécuter les tests d’animation en intégration continue sur macOS et Windows. [Exécution CI](https://github.com/boomsi/key-balloons/actions/runs/45830723721)
- [ ] Vérifier avec des claviers physiques que la saisie est détectée entre applications sur les deux plateformes. Sur Windows, vérifier aussi le premier plan, le focus et la transmission des clics.
- [ ] Mesurer la latence entre une frappe réelle et son affichage, et l’intervalle des images pendant une animation prolongée sous Windows.
- [ ] Confirmer la répétition des touches maintenues et l’option de suivi du système. La première version affiche les frappes réelles et place le boîtier sur l’écran principal.
- [x] Valider la première version et la pousser vers le nouveau dépôt public.
