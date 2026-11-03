import 'package:bedbug/core/domain/value_object.dart';
import 'package:bedbug/resources/content/storage/cleanup_strategy.enum.dart';

/// Configuration du stockage local des contenus : la limite de poids, le poids actuel et la stratégie de nettoyage
/// appliquée lorsque cette limite est atteinte.
///
/// Une seule configuration par appareil, toujours remplacée en entier : elle n'a pas d'identité à suivre, c'est un
/// value object.
class Storage extends ValueObject {
  /// Crée un [Storage].
  ///
  /// - [maxSizeInBytes] : taille maximale allouée aux contenus, en octets.
  /// - [currentSizeInBytes] : taille actuellement occupée par les contenus,
  ///   en octets. Maintenue à jour par les use cases qui ajoutent ou
  ///   suppriment des contenus, pour éviter de recalculer ce total en
  ///   parcourant l'intégralité des contenus stockés à chaque lecture.
  /// - [strategy] : stratégie de suppression automatique appliquée lors
  ///   d'un nettoyage. Par défaut : [CleanupStrategy.byPriorityThenDate].
  const Storage({
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

  @override
  bool operator ==(Object other) {
    return other is Storage &&
        other.maxSizeInBytes == maxSizeInBytes &&
        other.currentSizeInBytes == currentSizeInBytes &&
        other.strategy == strategy;
  }

  @override
  int get hashCode {
    return Object.hash(maxSizeInBytes, currentSizeInBytes, strategy);
  }

  /// Retourne une copie de ce [Storage] avec [currentSizeInBytes] remplacé.
  ///
  /// Les use cases qui ajoutent ou suppriment des contenus appellent cette
  /// méthode pour maintenir le total à jour sans devoir reconstruire
  /// manuellement la configuration.
  ///
  /// - [currentSizeInBytes] : nouveau poids actuel, en octets.
  Storage copyWithCurrentSizeInBytes(int currentSizeInBytes) {
    return Storage(maxSizeInBytes: maxSizeInBytes, currentSizeInBytes: currentSizeInBytes, strategy: strategy);
  }

  /// Retourne une copie de ce [Storage] avec [maxSizeInBytes] remplacé.
  ///
  /// La limite se règle dans les paramètres, sans toucher au poids actuel ni au reste de la configuration.
  ///
  /// - [maxSizeInBytes] : nouvelle limite, en octets.
  Storage copyWithMaxSizeInBytes(int maxSizeInBytes) {
    return Storage(maxSizeInBytes: maxSizeInBytes, currentSizeInBytes: currentSizeInBytes, strategy: strategy);
  }
}
