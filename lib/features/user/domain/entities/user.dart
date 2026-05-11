import 'package:bedbug/shared/domain/entity.dart';

/// Représente un utilisateur de l'application.
class User extends Entity {
  /// Crée un [User].
  ///
  /// - [pseudo] : nom d'affichage choisi par l'utilisateur.
  /// - [email] : adresse e-mail, nullable car non obligatoire.
  User({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required this.pseudo,
    this.email,
  });

  /// Nom d'affichage de l'utilisateur.
  final String pseudo;

  /// Adresse e-mail de l'utilisateur, nullable.
  final String? email;
}
