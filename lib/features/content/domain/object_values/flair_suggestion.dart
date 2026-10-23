import 'package:bedbug/shared/domain/value_object.dart';

/// Flair proposé en autocomplétion pendant la saisie d'une recherche.
///
/// Porte le nombre de contenus rattachés au flair pour que l'utilisateur
/// voie, comme sur Reddit, quels flairs sont réellement fournis avant de
/// choisir.
class FlairSuggestion extends ValueObject {
  /// Crée une [FlairSuggestion].
  ///
  /// - [flair] : flair normalisé, sans le `/` initial (ex. `france`).
  /// - [contentCount] : nombre de contenus stockés rattachés à ce flair.
  const FlairSuggestion({required this.flair, required this.contentCount});

  /// Flair normalisé, sans le `/` initial.
  final String flair;

  /// Nombre de contenus stockés rattachés à ce flair.
  final int contentCount;

  @override
  bool operator ==(Object other) {
    return other is FlairSuggestion && other.flair == flair && other.contentCount == contentCount;
  }

  @override
  int get hashCode {
    return Object.hash(flair, contentCount);
  }
}
