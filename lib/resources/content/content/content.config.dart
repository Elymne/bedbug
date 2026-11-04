import 'package:bedbug/resources/content/content/media_content.entity.dart';

/// Longueur maximale, en caractères, d'un flair saisi.
///
/// Appliquée au formulaire de création et aux contenus reçus des pairs, qui ne passent par aucun formulaire.
const int maxFlairLength = 32;

/// Nombre maximal de médias regroupés dans un même [MediaContent].
const int maxMediaPerContent = 10;

/// Nom de la box Hive des contenus.
const String contentBoxName = 'contents';

/// Préfixe d'affichage d'un flair, à la manière de Reddit (`r/`) : `f/france`.
///
/// Toujours affiché devant le flair via `AppPrefixedText`, en gras avec un léger effet ghost.
const String flairPrefix = 'f/';
