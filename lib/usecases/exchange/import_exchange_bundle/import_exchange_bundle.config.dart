import 'package:bedbug/services/content/content_size.service.dart';

/// Poids maximal d'un contenu reçu d'un pair, en octets.
///
/// Un dessin au maximum de ses limites pèse environ 90 Ko selon le calcul de [ContentSizeService] ; au-delà,
/// un contenu reçu n'a rien de légitime et ne sert qu'à remplir le stockage.
const int maxReceivedContentBytes = 128 * 1024;

/// Nombre de rebonds au-delà duquel le compteur reçu n'est plus cru.
///
/// Le compteur vient du pair et n'est pas vérifiable : il est borné pour qu'une valeur extrême n'ait pas
/// d'effet sur les scores.
const int maxReceivedBounce = 1000;

/// Durée pendant laquelle un contenu reçu ou supprimé reste mémorisé comme déjà vu.
///
/// Au-delà, un contenu a presque fini de circuler (sa priorité de diffusion décroît en quelques jours) : le
/// risque de le retélécharger est faible, et la mémoire ne grossit pas indéfiniment.
const Duration seenContentRetention = Duration(days: 30);

/// Préfixe des identifiants de signatures reçues des pairs.
///
/// Les distingue de la signature locale et de la signature anonyme : aucune signature reçue ne peut prendre
/// l'identifiant `local` et s'afficher comme celle de l'utilisateur.
const String peerSignatureIdPrefix = 'peer-';
