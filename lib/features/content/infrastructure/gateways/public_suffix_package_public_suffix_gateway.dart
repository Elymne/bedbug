import 'package:bedbug/features/content/domain/gateways/public_suffix_gateway.dart';
import 'package:bedbug/shared/logger/app_logger.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:public_suffix/public_suffix.dart';

/// Chemin de la Public Suffix List embarquée dans l'application.
///
/// Embarquée plutôt que téléchargée : l'app doit fonctionner sans connexion.
/// À mettre à jour de temps en temps depuis https://publicsuffix.org/list/public_suffix_list.dat.
const String publicSuffixListAssetPath = 'assets/data/public_suffix_list.dat';

/// Provider du [PublicSuffixGateway].
final publicSuffixGatewayProvider = Provider<PublicSuffixGateway>((ref) {
  return PublicSuffixPackagePublicSuffixGateway(() => rootBundle.loadString(publicSuffixListAssetPath));
});

/// [PublicSuffixGateway] basé sur le paquet `public_suffix`, à partir de la liste embarquée.
///
/// Seule la recherche du suffixe public est confiée au paquet : sa
/// comparaison de sous-domaines (`isSubdomainOf`) repose sur un simple
/// « se termine par » et n'est pas utilisée.
class PublicSuffixPackagePublicSuffixGateway implements PublicSuffixGateway {
  /// Crée un [PublicSuffixPackagePublicSuffixGateway].
  ///
  /// - [_loadList] : lecture du contenu de la Public Suffix List, appelée une seule fois, au premier besoin.
  PublicSuffixPackagePublicSuffixGateway(this._loadList);

  final Future<String> Function() _loadList;

  /// Règles analysées, gardées en mémoire : la liste compte des milliers de lignes.
  late final Future<SuffixRules> _rules = _parseRules();

  @override
  Future<bool> isPublicSuffix(String host) async {
    try {
      final suffix = PublicSuffix(urlString: 'https://$host/', suffixRules: await _rules);
      // `suffix` tient compte des suffixes privés (`github.io`), pas seulement
      // de ceux des registres officiels (`co.uk`).
      return suffix.suffix == host;
    } catch (error, stackTrace) {
      AppLogger.error('PublicSuffixPackagePublicSuffixGateway', error, stackTrace);
      return true;
    }
  }

  /// Lit et analyse la Public Suffix List.
  Future<SuffixRules> _parseRules() async {
    return SuffixRules.fromString(await _loadList());
  }
}
