import 'package:bedbug/features/content/domain/enums/cleanup_strategy.dart';
import 'package:bedbug/shared/domain/entity.dart';

/// Configuration du stockage local des contenus.
///
/// Entité singleton définissant la limite de poids et la stratégie
/// de nettoyage automatique appliquée lorsque cette limite est atteinte.
class Storage extends Entity {
  /// Crée un [Storage].
  ///
  /// - [maxSizeInBytes] : taille maximale allouée aux contenus, en octets.
  /// - [strategy] : stratégie de suppression automatique appliquée lors
  ///   d'un nettoyage. Par défaut : [CleanupStrategy.byPriorityThenDate].
  Storage({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required this.maxSizeInBytes,
    this.strategy = CleanupStrategy.byPriorityThenDate,
  });

  /// Taille maximale allouée aux contenus, exprimée en octets.
  final int maxSizeInBytes;

  /// Stratégie de suppression automatique des contenus.
  final CleanupStrategy strategy;
}
