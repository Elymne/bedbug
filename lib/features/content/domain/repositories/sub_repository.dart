import 'package:bedbug/features/content/domain/entities/sub.dart';
import 'package:bedbug/shared/domain/repository.dart';
import 'package:bedbug/shared/domain/repository_params.dart';

/// Contrat du repository gérant les [Sub].
abstract class SubRepository extends Repository<Sub, SubRepositoryParams> {}

/// Paramètres de requête du [SubRepository].
class SubRepositoryParams extends RepositoryParams {
  /// Crée des [SubRepositoryParams].
  ///
  /// - [page] : numéro de la page demandée. Par défaut 1.
  /// - [limit] : nombre maximum d'éléments à retourner. `null` = tous.
  /// - [orderBy] : tri appliqué aux résultats.
  const SubRepositoryParams({super.page, super.limit, super.orderBy});
}
