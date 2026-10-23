import 'package:bedbug/features/user/domain/entities/user.dart';

/// Identifiant d'auteur porté par les contenus publiés anonymement.
const String anonymousUserId = 'anonymous';

/// Profil anonyme, identique pour tout le monde.
///
/// Codé en dur dans l'app et jamais stocké en base : un contenu anonyme ne
/// doit rien révéler de son auteur, pas même un profil qu'il aurait pu
/// modifier. Sert aussi de repli pour tout auteur inconnu de l'appareil.
/// Icône « agent secret », couleur et vitesse du ghost par défaut, aucun
/// réseau.
final User anonymousUser = User(
  id: anonymousUserId,
  createdAt: DateTime.fromMillisecondsSinceEpoch(0),
  updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
  pseudo: 'anonyme',
  avatarText: '(⌐■_■)',
);
