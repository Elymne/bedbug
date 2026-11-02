import 'package:bedbug/resources/content/content/media_content.entity.dart';

/// Longueur maximale, en caractères, d'un flair saisi.
///
/// Appliquée au formulaire de création et aux contenus reçus des pairs, qui ne passent par aucun formulaire.
const int maxFlairLength = 32;

/// Nombre maximal de médias regroupés dans un même [MediaContent].
const int maxMediaPerContent = 10;
