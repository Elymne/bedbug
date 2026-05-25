import 'package:bedbug/features/discovery/domain/entities/keychain.dart';
import 'package:bedbug/shared/domain/repository.dart';
import 'package:bedbug/shared/domain/repository_params.dart';
import 'package:bedbug/shared/query/no_pagination.dart';

/// Contrat du repository gérant les [Keychain].
abstract class KeychainRepository
    extends Repository<Keychain, KeychainRepositoryParams> {}

/// Paramètres de requête du [KeychainRepository].
class KeychainRepositoryParams extends RepositoryParams<NoPagination> {
  /// Crée des [KeychainRepositoryParams].
  ///
  /// - [subId] : filtre optionnel sur le sub associé.
  const KeychainRepositoryParams({super.pagination, super.orderBy, this.subId});

  /// Filtre sur l'identifiant du sub. `null` = aucun filtre.
  final String? subId;
}
