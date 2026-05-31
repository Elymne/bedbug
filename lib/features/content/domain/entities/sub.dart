import 'package:bedbug/shared/domain/entity.dart';

/// Espace thématique regroupant des contenus partageant un même sujet.
///
/// L'accès aux contenus d'un [Sub] pourra être restreint par une clé
/// de déchiffrement que l'utilisateur ajoute manuellement à son
/// portefeuille de clés.
class Sub extends Entity {
  /// Crée un [Sub].
  ///
  /// - [name] : nom du sub.
  /// - [description] : description du sub.
  Sub({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required this.name,
    required this.description,
  });

  /// Nom du sub.
  final String name;

  /// Description du sub.
  final String description;
}
