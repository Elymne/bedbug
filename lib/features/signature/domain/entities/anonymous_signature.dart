import 'package:bedbug/features/signature/domain/entities/signature.dart';

/// Identifiant d'auteur porté par les contenus publiés anonymement.
const String anonymousSignatureId = 'anonymous';

/// Signature anonyme, identique pour tout le monde.
///
/// Codée en dur dans l'app et jamais stockée en base : un contenu anonyme ne
/// doit rien révéler de son auteur, pas même une signature qu'il aurait pu
/// modifier. Sert aussi de repli pour tout auteur dont la signature est
/// inconnue de l'appareil.
/// Icône « agent secret », couleur et vitesse du ghost par défaut, aucun
/// réseau.
final Signature anonymousSignature = Signature(
  id: anonymousSignatureId,
  createdAt: DateTime.fromMillisecondsSinceEpoch(0),
  updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
  pseudo: 'anonyme',
  avatarText: '(⌐■_■)',
);
