# Tests et pannes

## Les tests automatisés

| Fichier | Ce qu'il vérifie |
| ---------------------------------------------- | ---------------------------------------------------- |
| `test/unit/exchange_frame_test.dart` | Format des trames, découpage quelconque |
| `test/unit/ble_peer_link_gateway_test.dart` | Le pont Dart, avec des canaux simulés |
| `test/unit/start_peer_link_usecase_test.dart` | Démarrage, permissions, reprise |
| `test/widget/exchange_screen_test.dart` | La page, l'icône du menu, le choix enregistré |
| `test/integration/exchange_usecases_test.dart` | Offre, demande, lot, import |
| `test/integration/exchange_usecases_limits_test.dart` | Limites et valeurs falsifiées |
| `test/integration/exchange_session_test.dart` | Deux appareils simulés, pair hostile, coupures |
| `test/integration/exchange_network_test.dart` | 10 appareils en parallèle |
| `test/integration/storage_limit_usecases_test.dart` | Nettoyage du stockage, ordre de suppression |
| `test/widget/storage_section_test.dart` | Choix de la limite dans les paramètres |

`exchange_network_test.dart` donne à chaque appareil ses vrais use cases et sa propre base Hive, et les fait se rencontrer
par paires, en vagues parallèles. Il vérifie que tout le monde finit par tout posséder, sans doublon, avec un compteur de
stockage juste, y compris avec 50 % de connexions coupées.

**Ce que les tests ne couvrent pas** : tout le Kotlin. Le scan, l'annonce, L2CAP, le service et les délais avant de
recontacter un pair ne se vérifient que sur de vrais téléphones.

## Tester sur deux téléphones

1. Installer l'app sur les deux, Bluetooth activé. Sur Android 10 et 11, activer aussi la localisation.
2. Créer un contenu différent sur chacun.
3. Cocher la case de l'onglet Échange sur les deux, et accepter les permissions.
4. Poser les téléphones côte à côte. Compter jusqu'à une minute.
5. Regarder les compteurs, puis tirer le fil d'accueil vers le bas.

Pour relancer un essai sans attendre les 10 minutes, décocher puis recocher la case : cela vide la table des délais et
change l'identifiant.

Pour repartir d'un téléphone vierge, vider les données de l'app dans les réglages Android.

## Lire les compteurs

| Ce que tu vois | Ce que ça veut dire |
| ---------------------------------------------- | -------------------------------------------------- |
| Réussis et contenus reçus augmentent | Le transfert marche |
| Réussis augmente, contenus reçus reste à 0 | Connexion et protocole OK, rien de nouveau à recevoir |
| Échoués augmente | L'échange se coupe : voir la console Flutter, `Échange interrompu : …` |
| Tout reste à 0 | Les téléphones ne se trouvent pas ou ne se connectent pas |

## Où regarder

```text
adb logcat -s ExchangeRadio BleDiscovery LinkTuner ExchangeService ExchangeChannels
```

| Message ou symptôme | Piste |
| --------------------------------------- | -------------------------------------------------- |
| `Annonce impossible, code …` | Trop d'annonces sur le téléphone, ou Bluetooth instable |
| `Scan impossible, code …` | Trop de démarrages de scan rapprochés, Android bloque un moment |
| `Connexion L2CAP impossible` | Pair parti, ou téléphone qui gère mal L2CAP |
| `Serveur L2CAP interrompu` | Le Bluetooth a été coupé |
| `Passage au premier plan refusé` | Android a refusé la relance en arrière-plan |
| La case se décoche toute seule | Bouton « Arrêter », Bluetooth coupé, ou relance refusée |
| Échange trouvé, mais très lent | La découverte n'a pas été coupée, ou le lien n'a pas eu la PHY 2M (`LinkTuner`) |
| Un contenu n'apparaît pas | Tirer le fil vers le bas, puis parcourir la liste : son rang dépend de `displayScore` |
| Un contenu reçu disparaît | Limite de stockage atteinte : il était parmi les plus faibles `survivalScore` |

## Limites connues

- Pas de repli GATT : un téléphone dont le L2CAP échoue n'échange pas.
- L'échange ne redémarre pas après un redémarrage du téléphone, seulement à l'ouverture de l'app.
- La consommation de batterie et le comportement à 5-10 m n'ont pas été mesurés.
- Les compteurs de l'onglet Échange repartent de zéro au redémarrage de l'app.
- La home ne se recharge pas d'elle-même après une réception ou un nettoyage : un contenu supprimé reste affiché jusqu'au
  prochain rechargement.
- Le comportement face à plus de deux vrais téléphones n'a pas été observé.
- iOS n'est pas pris en charge.
- Les contenus voyagent en clair : `Wrap` et `Keychain` ne sont pas branchés.
