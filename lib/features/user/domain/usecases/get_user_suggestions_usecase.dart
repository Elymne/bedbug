import 'package:bedbug/features/user/domain/entities/anonymous_user.dart';
import 'package:bedbug/features/user/domain/entities/user.dart';
import 'package:bedbug/features/user/domain/repositories/user_repository.dart';
import 'package:bedbug/features/user/infrastructure/datasources/hive_user_repository.dart';
import 'package:bedbug/shared/domain/either.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:bedbug/shared/domain/usecase.dart';
import 'package:bedbug/shared/exceptions/data_exception.dart';
import 'package:bedbug/shared/exceptions/datasource_exception.dart';
import 'package:bedbug/shared/logger/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Nombre maximal d'utilisateurs proposés en autocomplétion.
const int maxUserSuggestions = 4;

/// Provider du [GetUserSuggestionsUsecase].
final getUserSuggestionsUsecaseProvider = Provider<GetUserSuggestionsUsecase>(
  (ref) => GetUserSuggestionsUsecase(ref.read(userRepositoryProvider)),
);

/// Propose les utilisateurs connus de l'appareil dont le pseudo commence par la saisie de l'utilisateur.
///
/// Comme pour les flairs, l'utilisateur ne peut pas deviner quels auteurs
/// sont connus de son appareil : on les lui suggère pendant la frappe, pour
/// qu'un tap l'amène directement à leurs contenus. La saisie peut être
/// préfixée de `u/`, comme les pseudos sont affichés. Le profil anonyme
/// n'est jamais proposé : il ne désigne personne, filtrer dessus n'a pas de
/// sens.
class GetUserSuggestionsUsecase extends Usecase<GetUserSuggestionsParams, GetUserSuggestionsFailure, List<User>> {
  /// Crée un [GetUserSuggestionsUsecase].
  GetUserSuggestionsUsecase(this._userRepository);

  final UserRepository _userRepository;

  @override
  Future<Either<GetUserSuggestionsFailure, List<User>>> call(GetUserSuggestionsParams params) async {
    try {
      final prefix = params.input.trim().replaceFirst(RegExp('^u/', caseSensitive: false), '');
      if (prefix.isEmpty) {
        return const Right([]);
      }

      final users = await _userRepository.getAllWithPseudoStartingWith(prefix, limit: maxUserSuggestions);
      return Right(users.where((user) => user.id != anonymousUserId).toList());
    } on DataException catch (error, stackTrace) {
      AppLogger.error('GetUserSuggestionsUsecase', error, stackTrace);
      return const Left(GetUserSuggestionsFailure.invalidData);
    } on DatasourceException catch (error, stackTrace) {
      AppLogger.error('GetUserSuggestionsUsecase', error, stackTrace);
      return const Left(GetUserSuggestionsFailure.storageError);
    } catch (error, stackTrace) {
      AppLogger.error('GetUserSuggestionsUsecase', error, stackTrace);
      return const Left(GetUserSuggestionsFailure.unknown);
    }
  }
}

/// Échecs possibles du [GetUserSuggestionsUsecase].
enum GetUserSuggestionsFailure {
  /// La donnée lue est invalide ou corrompue.
  invalidData,

  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue lors de la recherche de suggestions.
  unknown,
}

/// Paramètres du [GetUserSuggestionsUsecase].
class GetUserSuggestionsParams extends Params {
  /// Crée des [GetUserSuggestionsParams].
  ///
  /// - [input] : saisie brute de l'utilisateur, avec ou sans `u/` initial.
  const GetUserSuggestionsParams({required this.input});

  /// Saisie brute de l'utilisateur, avec ou sans `u/` initial.
  final String input;
}
