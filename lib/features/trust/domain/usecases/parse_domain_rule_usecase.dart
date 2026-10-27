import 'package:bedbug/features/trust/domain/gateways/public_suffix_gateway.dart';
import 'package:bedbug/features/trust/domain/object_values/domain_rule.dart';
import 'package:bedbug/features/trust/infrastructure/gateways/public_suffix_package_public_suffix_gateway.dart';
import 'package:bedbug/shared/domain/either.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:bedbug/shared/domain/usecase.dart';
import 'package:bedbug/shared/logger/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [ParseDomainRuleUsecase].
final parseDomainRuleUsecaseProvider = Provider<ParseDomainRuleUsecase>((ref) {
  return ParseDomainRuleUsecase(ref.read(publicSuffixGatewayProvider));
});

/// Transforme la saisie d'un utilisateur en règle de whitelist ou de greylist, après l'avoir vérifiée.
///
/// L'utilisateur garde la main sur ses listes de domaines, mais une règle
/// mal choisie peut tout ouvrir : `*.github.io` autoriserait les sites de
/// tous les utilisateurs de GitHub, `co.uk` tous les sites britanniques.
/// Ce use case est le seul point d'entrée pour créer une règle : il refuse
/// les saisies mal formées ou piégées (voir [DomainRule.tryParse]) et toute
/// règle portant sur un suffixe public.
class ParseDomainRuleUsecase extends Usecase<ParseDomainRuleParams, ParseDomainRuleFailure, DomainRule> {
  /// Crée un [ParseDomainRuleUsecase].
  ParseDomainRuleUsecase(this._publicSuffixGateway);

  final PublicSuffixGateway _publicSuffixGateway;

  @override
  Future<Either<ParseDomainRuleFailure, DomainRule>> call(ParseDomainRuleParams params) async {
    try {
      final rule = DomainRule.tryParse(params.input);
      if (rule == null) {
        return const Left(ParseDomainRuleFailure.invalidFormat);
      }
      if (await _publicSuffixGateway.isPublicSuffix(rule.host)) {
        return const Left(ParseDomainRuleFailure.publicSuffix);
      }
      return Right(rule);
    } catch (error, stackTrace) {
      AppLogger.error('ParseDomainRuleUsecase', error, stackTrace);
      return const Left(ParseDomainRuleFailure.unknown);
    }
  }
}

/// Échecs possibles du [ParseDomainRuleUsecase].
enum ParseDomainRuleFailure {
  /// La saisie n'est ni un domaine, ni `*.domaine`, ni une URL https valide.
  invalidFormat,

  /// La règle porte sur un suffixe public (`co.uk`, `github.io`…) et ouvrirait des sites inconnus.
  publicSuffix,

  /// Erreur inattendue lors de la vérification.
  unknown,
}

/// Paramètres du [ParseDomainRuleUsecase].
class ParseDomainRuleParams extends Params {
  /// Crée des [ParseDomainRuleParams].
  ///
  /// - [input] : saisie brute de l'utilisateur (domaine, `*.domaine` ou URL).
  const ParseDomainRuleParams({required this.input});

  /// Saisie brute de l'utilisateur.
  final String input;
}
