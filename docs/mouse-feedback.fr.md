# Intégration du retour visuel de la souris

[English](mouse-feedback.md) · [简体中文](mouse-feedback.zh.md) · [繁體中文](mouse-feedback.zh-TW.md) · [Français](mouse-feedback.fr.md) · [日本語](mouse-feedback.ja.md) · [한국어](mouse-feedback.ko.md) · [Español](mouse-feedback.es.md)

Faites un clic droit sur le boîtier ou choisissez **Réglages…** dans la barre des menus ou la zone de notification. Dans **Avancé**, activez **Autoriser les intégrations souris locales**. Les intégrations sont désactivées au démarrage. Les désactiver déconnecte les clients tiers. Le boîtier intégré reste abonné via une connexion privée et utilise le même protocole.

## Connexion

Une fois les intégrations activées, lisez `mouse-feedback-v1.json` à l’un des emplacements ci-dessous. Chaque instance a son propre point de connexion. Relisez le fichier avant de vous reconnecter. Pour un même utilisateur, une seule instance à la fois peut ouvrir l’accès aux clients tiers.

| Plateforme | Chemin du descripteur | Transport |
| --- | --- | --- |
| macOS | `~/Library/Application Support/Key Balloons/mouse-feedback-v1.json` | Socket de domaine Unix |
| Windows | `%LOCALAPPDATA%\Key Balloons\mouse-feedback-v1.json` | Canal nommé |

Le descripteur contient un numéro `version` et une chaîne `endpoint`. Utilisez `endpoint` comme chemin du socket ou du canal local. Les processus lancés par le même utilisateur peuvent s’y connecter.

## Envoi et réception

Chaque message est un objet JSON UTF-8 suivi d’un saut de ligne (`\n`), avec un maximum de 512 octets, saut de ligne compris. Chaque message contient `"version":1`. Un message trop long ferme la connexion.

| Événement | Entrée native | Boîtier intégré |
| --- | --- | --- |
| `mouse.left` | Appui sur le bouton gauche | Le côté gauche s’allume |
| `mouse.right` | Appui sur le bouton droit | Le côté droit s’allume |
| `mouse.wheel` | Défilement vertical ou horizontal, ou clic sur la molette | Le centre s’allume |

Envoyez une fois `subscribe` sur la connexion. Après confirmation, les nouveaux événements arrivent dans des messages `event`. Les événements antérieurs ne sont pas rejoués. Vous pouvez publier sur la même connexion et recevoir les événements que vous y publiez.

```jsonl
{"version":1,"op":"subscribe"}
{"version":1,"op":"ok","request":"subscribe"}
{"version":1,"op":"event","event":"mouse.left"}
```

Envoyez `publish` avec un nom d’événement du tableau. Le boîtier s’allume et les abonnés reçoivent l’événement. La publication déclenche uniquement le retour visuel. Les clients peuvent publier lorsque la surveillance native est suspendue. Sur macOS, les événements natifs nécessitent l’autorisation Surveillance de l’entrée.

```jsonl
{"version":1,"op":"publish","event":"mouse.right"}
{"version":1,"op":"ok","request":"publish"}
```

Une requête invalide renvoie `{"version":1,"op":"error","code":"…"}`. Les codes sont `invalid_message`, `unsupported_version`, `unsupported_operation` et `unsupported_event`. L’accusé indique que la requête est acceptée. Les événements contiennent uniquement le nom de l’action. Un client trop lent peut être déconnecté. Pour reprendre, reconnectez-vous et abonnez-vous de nouveau.

## Exécuter l’exemple

Avec Node.js installé et les intégrations activées, exécutez ces commandes à la racine du dépôt dans deux terminaux. La commande de veille affiche la confirmation de l’abonnement et les événements suivants.

```sh
node examples/mouse-feedback.mjs watch
```

```sh
node examples/mouse-feedback.mjs mouse.left
node examples/mouse-feedback.mjs mouse.right
node examples/mouse-feedback.mjs mouse.wheel
```

Pour afficher les événements dans une interface graphique, consultez [l’abonné du boîtier intégré](../examples/basic-box/overlay_mouse_client.cpp).
