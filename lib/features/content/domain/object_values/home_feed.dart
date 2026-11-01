import 'package:bedbug/features/content/domain/entities/content.dart';
import 'package:bedbug/shared/domain/value_object.dart';

/// Fil de la page d'accueil : les contenus dans leur ordre d'affichage, et ceux à signaler comme nouveaux.
class HomeFeed extends ValueObject {
  /// Crée un [HomeFeed].
  ///
  /// - [contents] : contenus dans leur ordre d'affichage.
  /// - [unviewedContentIds] : identifiants des contenus que l'utilisateur n'a pas encore vus.
  const HomeFeed({required this.contents, required this.unviewedContentIds});

  /// Contenus dans leur ordre d'affichage.
  final List<Content> contents;

  /// Identifiants des contenus que l'utilisateur n'a pas encore vus.
  final Set<String> unviewedContentIds;

  @override
  bool operator ==(Object other) {
    if (other is! HomeFeed || other.contents.length != contents.length) {
      return false;
    }
    if (other.unviewedContentIds.length != unviewedContentIds.length) {
      return false;
    }
    for (var index = 0; index < contents.length; index++) {
      if (other.contents[index] != contents[index]) {
        return false;
      }
    }
    return other.unviewedContentIds.containsAll(unviewedContentIds);
  }

  @override
  int get hashCode {
    return Object.hash(Object.hashAll(contents), Object.hashAllUnordered(unviewedContentIds));
  }

  @override
  String toString() {
    return 'HomeFeed(${contents.length} contenus, ${unviewedContentIds.length} non vus)';
  }
}
