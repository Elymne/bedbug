import 'package:bedbug/features/user/domain/entities/user.dart';
import 'package:bedbug/shared/domain/repository.dart';
import 'package:bedbug/shared/domain/repository_params.dart';
import 'package:bedbug/shared/query/no_pagination.dart';

/// Contrat du repository gérant les [User].
abstract class UserRepository extends Repository<User, UserRepositoryParams> {}

/// Paramètres de requête du [UserRepository].
class UserRepositoryParams extends RepositoryParams<NoPagination> {
  /// Crée des [UserRepositoryParams].
  ///
  /// - [pseudo] : filtre optionnel sur le pseudo de l'utilisateur.
  const UserRepositoryParams({super.pagination, super.orderBy, this.pseudo});

  /// Filtre sur le pseudo. `null` = aucun filtre.
  final String? pseudo;
}
