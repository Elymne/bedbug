import 'package:bedbug/core/domain/either.dart';
import 'package:bedbug/core/domain/usecase.dart';
import 'package:bedbug/core/logger/app_logger.dart';
import 'package:bedbug/gateways/public_suffix/public_suffix/public_suffix.gateway.dart';
import 'package:bedbug/gateways/public_suffix/public_suffix/public_suffix.gateway.package.dart';
import 'package:bedbug/resources/content/trust_settings/domain_rule.value_object.dart';
import 'package:bedbug/resources/error_log/error_log/error_log.repository.dart';
import 'package:bedbug/resources/error_log/error_log/error_log.repository.hive.dart';
import 'package:bedbug/services/trust/domain_rule.service.dart';
import 'package:bedbug/services/trust/url_safety.service.dart';
import 'package:bedbug/usecases/trust/parse_domain_rule/parse_domain_rule.failure.dart';
import 'package:bedbug/usecases/trust/parse_domain_rule/parse_domain_rule.params.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [ParseDomainRuleUsecase].
final parseDomainRuleUsecaseProvider = Provider<ParseDomainRuleUsecase>((ref) {
  return ParseDomainRuleUsecase(
    ref.read(publicSuffixGatewayProvider),
    ref.read(urlSafetyServiceProvider),
    ref.read(domainRuleServiceProvider),
    ref.read(errorLogRepositoryProvider),
  );
});

/// Transforme la saisie d'un utilisateur en règle de whitelist ou de greylist, après l'avoir vérifiée.
///
/// L'utilisateur garde la main sur ses listes de domaines, mais une règle
/// mal choisie peut tout ouvrir : `*.github.io` autoriserait les sites de
/// tous les utilisateurs de GitHub, `co.uk` tous les sites britanniques.
/// Ce use case est le seul point d'entrée pour créer une règle : il refuse
/// les saisies mal formées ou piégées (voir [DomainRuleService.parse]) et
/// toute règle portant sur un suffixe public. Il accepte aussi une URL
/// complète, dont seul le domaine est gardé : un utilisateur colle plus
/// volontiers une URL qu'il ne tape un domaine.
class ParseDomainRuleUsecase extends Usecase<ParseDomainRuleParams, ParseDomainRuleFailure, DomainRule> {
  /// Crée un [ParseDomainRuleUsecase].
  ParseDomainRuleUsecase(
    this._publicSuffixGateway,
    this._urlSafetyService,
    this._domainRuleService,
    this._errorLogRepository,
  );

  final PublicSuffixGateway _publicSuffixGateway;

  final UrlSafetyService _urlSafetyService;

  final DomainRuleService _domainRuleService;
  final ErrorLogRepository _errorLogRepository;

  @override
  Future<Either<ParseDomainRuleFailure, DomainRule>> call(ParseDomainRuleParams params) async {
    try {
      final rule = _parseInput(params.input.trim());
      if (rule == null) {
        return const Left(ParseDomainRuleFailure.invalidFormat);
      }
      if (await _publicSuffixGateway.isPublicSuffix(rule.host)) {
        return const Left(ParseDomainRuleFailure.publicSuffix);
      }
      return Right(rule);
    } catch (error, stackTrace) {
      AppLogger.error('ParseDomainRuleUsecase', error, stackTrace);
      await _errorLogRepository.record(source: 'ParseDomainRuleUsecase', error: error, stackTrace: stackTrace);
      return const Left(ParseDomainRuleFailure.unknown);
    }
  }

  /// Retourne la règle saisie dans [input], ou `null` si la saisie n'est pas valide.
  ///
  /// Une URL complète donne une règle sur son seul domaine, sans les
  /// sous-domaines ; toute autre saisie est lue comme une règle écrite.
  ///
  /// - [input] : saisie de l'utilisateur, sans espaces autour.
  DomainRule? _parseInput(String input) {
    if (!input.contains('://')) {
      return _domainRuleService.parse(input);
    }
    final url = _urlSafetyService.parse(input);
    if (url == null) {
      return null;
    }
    return DomainRule(host: url.host, isIncludingSubdomains: false);
  }
}
