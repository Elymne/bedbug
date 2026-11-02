import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/usecases/trust/parse_domain_rule/parse_domain_rule.usecase.dart';

/// Paramètres du [ParseDomainRuleUsecase].
class ParseDomainRuleParams extends Params {
  /// Crée des [ParseDomainRuleParams].
  ///
  /// - [input] : saisie brute de l'utilisateur (domaine, `*.domaine` ou URL).
  const ParseDomainRuleParams({required this.input});

  /// Saisie brute de l'utilisateur.
  final String input;
}
