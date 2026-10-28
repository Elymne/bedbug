import 'package:bedbug/shared/domain/value_object.dart';

/// Règle d'une liste de domaines : un domaine, avec ou sans ses sous-domaines.
///
/// Se lit et s'applique avec `DomainRuleService`.
class DomainRule extends ValueObject {
  /// Crée une [DomainRule].
  ///
  /// - [host] : nom de domaine, déjà validé et en minuscules (voir `DomainRuleService.parse`).
  /// - [isIncludingSubdomains] : `true` pour couvrir aussi tous les sous-domaines de [host].
  const DomainRule({required this.host, required this.isIncludingSubdomains});

  /// Nom de domaine couvert, en minuscules.
  final String host;

  /// Indique si la règle couvre aussi les sous-domaines de [host].
  ///
  /// `*.imgur.com` couvre `imgur.com` lui-même et tous ses sous-domaines.
  final bool isIncludingSubdomains;

  @override
  bool operator ==(Object other) {
    return other is DomainRule && other.host == host && other.isIncludingSubdomains == isIncludingSubdomains;
  }

  @override
  int get hashCode {
    return Object.hash(host, isIncludingSubdomains);
  }

  @override
  String toString() {
    return 'DomainRule($host, isIncludingSubdomains: $isIncludingSubdomains)';
  }
}
