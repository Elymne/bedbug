import 'package:bedbug/features/discovery/domain/entities/keychain.dart';
import 'package:bedbug/shared/domain/repository.dart';
import 'package:bedbug/shared/domain/repository_params.dart';

/// Contrat du repository gérant les [Keychain].
abstract class KeychainRepository extends Repository<Keychain, KeychainRepositoryParams> {}

/// Paramètres de requête du [KeychainRepository].
class KeychainRepositoryParams extends RepositoryParams {
  /// Crée des [KeychainRepositoryParams].
  ///
  /// - [subId] : filtre optionnel sur le sub associé.
  /// - [limit] : nombre maximum d'éléments à retourner. `null` = tous.
  /// - [orderBy] : tri appliqué aux résultats.
  const KeychainRepositoryParams({super.limit, super.orderBy, this.subId});

  /// Filtre sur l'identifiant du sub. `null` = aucun filtre.
  final String? subId;
}
