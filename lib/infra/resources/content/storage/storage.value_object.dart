import 'package:bedbug/core/domain/value_object.dart';
import 'package:bedbug/infra/resources/content/storage/cleanup_strategy.enum.dart';

/// Configuration du stockage local des contenus : la limite de poids et la stratégie de nettoyage appliquée lorsque
/// cette limite est atteinte.
///
/// Le poids utilisé n'en fait pas partie : il n'est pas un réglage mais un constat, lu sur la base elle-même
/// (`StorageRepository.getUsedSizeInBytes`).
///
/// Une seule configuration par appareil, toujours remplacée en entier : elle n'a pas d'identité à suivre, c'est un
/// value object.
class Storage extends ValueObject {
  /// Crée un [Storage].
  ///
  /// - [maxSizeInBytes] : poids maximal de la base, en octets.
  /// - [strategy] : stratégie de suppression automatique appliquée lors d'un nettoyage. Par défaut :
  ///   [CleanupStrategy.byPriorityThenDate].
  const Storage({required this.maxSizeInBytes, this.strategy = CleanupStrategy.byPriorityThenDate});

  /// Poids maximal de la base, exprimé en octets.
  final int maxSizeInBytes;

  /// Stratégie de suppression automatique des contenus.
  final CleanupStrategy strategy;

  /// Deux configurations sont égales quand leur limite et leur stratégie le sont.
  ///
  /// - [other] : objet comparé.
  @override
  bool operator ==(Object other) {
    return other is Storage && other.maxSizeInBytes == maxSizeInBytes && other.strategy == strategy;
  }

  /// Empreinte cohérente avec [operator ==].
  @override
  int get hashCode {
    return Object.hash(maxSizeInBytes, strategy);
  }

  /// Retourne une copie de ce [Storage] avec [maxSizeInBytes] remplacé.
  ///
  /// La limite se règle dans les paramètres, sans toucher au reste de la configuration.
  ///
  /// - [maxSizeInBytes] : nouvelle limite, en octets.
  Storage copyWithMaxSizeInBytes(int maxSizeInBytes) {
    return Storage(maxSizeInBytes: maxSizeInBytes, strategy: strategy);
  }
}
