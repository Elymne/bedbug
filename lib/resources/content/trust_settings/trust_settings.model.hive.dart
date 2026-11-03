import 'package:bedbug/resources/content/trust_settings/trust_settings.value_object.dart';
import 'package:bedbug/resources/data.exception.dart';
import 'package:bedbug/resources/hive.type_ids.dart';
import 'package:hive_ce/hive.dart';

part 'trust_settings.model.hive.g.dart';

/// DTO Hive représentant les [TrustSettings] persistés localement.
///
/// Les règles sont stockées sous leur forme saisie (`imgur.com`,
/// `*.imgur.com`) et réanalysées à la lecture : une règle stockée qui ne
/// passerait plus les vérifications est ignorée plutôt que de faire
/// confiance à un ancien format.
///
/// L'index 4 portait le sort des domaines inconnus, devenu fixe : ne jamais le réutiliser.
@HiveType(typeId: HiveTypeIds.trustSettings)
class TrustSettingsHiveModel extends HiveObject {
  /// Crée un [TrustSettingsHiveModel].
  ///
  /// - [mediaTrustedPatterns] : règles de la whitelist des médias.
  /// - [mediaGreyPatterns] : règles de la greylist des médias.
  /// - [linkTrustedPatterns] : règles de la whitelist des liens.
  /// - [linkGreyPatterns] : règles de la greylist des liens.
  TrustSettingsHiveModel({
    required this.mediaTrustedPatterns,
    required this.mediaGreyPatterns,
    required this.linkTrustedPatterns,
    required this.linkGreyPatterns,
  });

  /// Crée un [TrustSettingsHiveModel] depuis des [TrustSettings].
  ///
  /// - [entity] : réglages à stocker.
  factory TrustSettingsHiveModel.fromEntity(TrustSettings entity) {
    return TrustSettingsHiveModel(
      mediaTrustedPatterns: [for (final rule in entity.mediaPolicy.trustedRules) DomainRule.patternOf(rule)],
      mediaGreyPatterns: [for (final rule in entity.mediaPolicy.greyRules) DomainRule.patternOf(rule)],
      linkTrustedPatterns: [for (final rule in entity.linkPolicy.trustedRules) DomainRule.patternOf(rule)],
      linkGreyPatterns: [for (final rule in entity.linkPolicy.greyRules) DomainRule.patternOf(rule)],
    );
  }

  /// Règles de la whitelist des médias.
  @HiveField(0, defaultValue: <String>[])
  final List<String> mediaTrustedPatterns;

  /// Règles de la greylist des médias.
  @HiveField(1, defaultValue: <String>[])
  final List<String> mediaGreyPatterns;

  /// Règles de la whitelist des liens.
  @HiveField(2, defaultValue: <String>[])
  final List<String> linkTrustedPatterns;

  /// Règles de la greylist des liens.
  @HiveField(3, defaultValue: <String>[])
  final List<String> linkGreyPatterns;

  /// Convertit ce modèle en [TrustSettings].
  ///
  TrustSettings toEntity() {
    try {
      return TrustSettings(
        mediaPolicy: UrlTrustPolicy(
          trustedRules: _toRules(mediaTrustedPatterns),
          greyRules: _toRules(mediaGreyPatterns),
        ),
        linkPolicy: UrlTrustPolicy(trustedRules: _toRules(linkTrustedPatterns), greyRules: _toRules(linkGreyPatterns)),
      );
    } catch (error) {
      throw DataException('TrustSettingsHiveModel', error);
    }
  }

  /// Réanalyse les règles stockées, en ignorant celles qui ne sont plus valides.
  ///
  /// - [patterns] : règles stockées, sous leur forme saisie.
  List<DomainRule> _toRules(List<String> patterns) {
    return [for (final pattern in patterns) ?DomainRule.parse(pattern)];
  }
}
