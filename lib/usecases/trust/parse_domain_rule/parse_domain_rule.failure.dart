import 'package:bedbug/usecases/trust/parse_domain_rule/parse_domain_rule.usecase.dart';

/// Échecs possibles du [ParseDomainRuleUsecase].
enum ParseDomainRuleFailure {
  /// La saisie n'est ni un domaine, ni `*.domaine`, ni une URL https valide.
  invalidFormat,

  /// La règle porte sur un suffixe public (`co.uk`, `github.io`…) et ouvrirait des sites inconnus.
  publicSuffix,

  /// Erreur inattendue lors de la vérification.
  unknown,
}
