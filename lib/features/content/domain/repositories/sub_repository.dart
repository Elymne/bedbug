import 'package:bedbug/features/content/domain/entities/sub.dart';
import 'package:bedbug/shared/domain/repository.dart';
import 'package:bedbug/shared/domain/repository_params.dart';
import 'package:bedbug/shared/query/no_pagination.dart';

/// Contrat du repository gérant les [Sub].
abstract class SubRepository extends Repository<Sub, SubRepositoryParams> {}

/// Paramètres de requête du [SubRepository].
class SubRepositoryParams extends RepositoryParams<NoPagination> {
  /// Crée des [SubRepositoryParams].
  const SubRepositoryParams({super.pagination, super.orderBy});
}
