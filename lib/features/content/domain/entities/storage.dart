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
  /// - [currentSizeInBytes] : taille actuellement occupée par les contenus,
  ///   en octets. Maintenue à jour par les use cases qui ajoutent ou
  ///   suppriment des contenus, pour éviter de recalculer ce total en
  ///   parcourant l'intégralité des contenus stockés à chaque lecture.
  /// - [strategy] : stratégie de suppression automatique appliquée lors
  ///   d'un nettoyage. Par défaut : [CleanupStrategy.byPriorityThenDate].
  Storage({
    required super.id,
    required super.createdAt,
    required super.updatedAt,
    required this.maxSizeInBytes,
    this.currentSizeInBytes = 0,
    this.strategy = CleanupStrategy.byPriorityThenDate,
  });

  /// Taille maximale allouée aux contenus, exprimée en octets.
  final int maxSizeInBytes;

  /// Taille actuellement occupée par les contenus, exprimée en octets.
  final int currentSizeInBytes;

  /// Stratégie de suppression automatique des contenus.
  final CleanupStrategy strategy;

  /// Retourne une copie de ce [Storage] avec [currentSizeInBytes] remplacé.
  ///
  /// Les use cases qui ajoutent ou suppriment des contenus appellent cette
  /// méthode pour maintenir le total à jour sans devoir reconstruire
  /// manuellement l'entité.
  Storage copyWithCurrentSizeInBytes(int currentSizeInBytes) {
    return Storage(
      id: id,
      createdAt: createdAt,
      updatedAt: updatedAt,
      maxSizeInBytes: maxSizeInBytes,
      currentSizeInBytes: currentSizeInBytes,
      strategy: strategy,
    );
  }
}
