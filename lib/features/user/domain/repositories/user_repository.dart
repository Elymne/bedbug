import 'package:bedbug/features/user/domain/entities/user.dart';
import 'package:bedbug/shared/domain/repository.dart';
import 'package:bedbug/shared/domain/repository_params.dart';

/// Contrat du repository gérant les [User].
abstract class UserRepository extends Repository<User, UserRepositoryParams> {}

/// Paramètres de requête du [UserRepository].
class UserRepositoryParams extends RepositoryParams {
  /// Crée des [UserRepositoryParams].
  ///
  /// - [pseudo] : filtre optionnel sur le pseudo de l'utilisateur.
  /// - [page] : numéro de la page demandée. Par défaut 1.
  /// - [limit] : nombre maximum d'éléments à retourner. `null` = tous.
  /// - [orderBy] : tri appliqué aux résultats.
  const UserRepositoryParams({super.page, super.limit, super.orderBy, this.pseudo});

  /// Filtre sur le pseudo. `null` = aucun filtre.
  final String? pseudo;
}
