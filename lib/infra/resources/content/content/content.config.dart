import 'package:bedbug/infra/resources/content/content/media_content.entity.dart';

/// Longueur maximale, en caractères, d'un flair saisi.
///
/// Appliquée au formulaire de création et aux contenus reçus des pairs, qui ne passent par aucun formulaire.
const int maxFlairLength = 32;

/// Nombre maximal de médias regroupés dans un même [MediaContent].
const int maxMediaPerContent = 10;

/// Préfixe d'affichage d'un flair, à la manière de Reddit (`r/`) : `f/france`.
///
/// Toujours affiché devant le flair via `AppPrefixedText`, en gras avec un léger effet ghost.
const String flairPrefix = 'f/';

/// Nombre de contenus lus par page dans les listes qui défilent (fil d'accueil, résultats de recherche).
///
/// Assez pour remplir plusieurs écrans d'un coup, assez peu pour que chaque page se lise vite même quand le
/// téléphone garde des milliers de contenus.
const int contentPageSize = 30;
