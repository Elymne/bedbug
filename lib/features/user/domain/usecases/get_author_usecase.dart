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

/// Provider du [GetAuthorUsecase].
final getAuthorUsecaseProvider = Provider<GetAuthorUsecase>(
  (ref) => GetAuthorUsecase(ref.read(userRepositoryProvider)),
);

/// Retrouve le profil à afficher pour l'auteur d'un contenu.
///
/// Un contenu ne porte que l'identifiant de son auteur. Pour lui donner un
/// visage sur la page de détail (pseudo, icône, couleur), on cherche ce
/// profil sur l'appareil. Un contenu anonyme, ou dont l'auteur est inconnu
/// de l'appareil (profil jamais configuré, pair dont on n'a pas reçu le
/// profil), est présenté avec le profil [anonymousUser] : on n'affiche
/// jamais un auteur qu'on ne connaît pas.
class GetAuthorUsecase extends Usecase<GetAuthorParams, GetAuthorFailure, User> {
  /// Crée un [GetAuthorUsecase].
  GetAuthorUsecase(this._userRepository);

  final UserRepository _userRepository;

  @override
  Future<Either<GetAuthorFailure, User>> call(GetAuthorParams params) async {
    try {
      if (params.authorId == anonymousUserId) {
        return Right(anonymousUser);
      }
      final user = await _userRepository.getById(params.authorId);
      return Right(user ?? anonymousUser);
    } on DataException catch (error, stackTrace) {
      AppLogger.error('GetAuthorUsecase', error, stackTrace);
      return const Left(GetAuthorFailure.invalidData);
    } on DatasourceException catch (error, stackTrace) {
      AppLogger.error('GetAuthorUsecase', error, stackTrace);
      return const Left(GetAuthorFailure.storageError);
    } catch (error, stackTrace) {
      AppLogger.error('GetAuthorUsecase', error, stackTrace);
      return const Left(GetAuthorFailure.unknown);
    }
  }
}

/// Échecs possibles du [GetAuthorUsecase].
enum GetAuthorFailure {
  /// La donnée lue est invalide ou corrompue.
  invalidData,

  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue lors de la lecture du profil.
  unknown,
}

/// Paramètres du [GetAuthorUsecase].
class GetAuthorParams extends Params {
  /// Crée des [GetAuthorParams].
  ///
  /// - [authorId] : identifiant d'auteur porté par le contenu.
  const GetAuthorParams({required this.authorId});

  /// Identifiant d'auteur porté par le contenu.
  final String authorId;
}
