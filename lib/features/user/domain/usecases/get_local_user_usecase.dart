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

/// Provider du [GetLocalUserUsecase].
final getLocalUserUsecaseProvider = Provider<GetLocalUserUsecase>(
  (ref) => GetLocalUserUsecase(ref.read(userRepositoryProvider)),
);

/// Récupère le profil de l'utilisateur du téléphone.
///
/// Le profil (pseudo, icône, couleur, réseaux) est ce qui donne du style aux
/// contenus créés sur cet appareil. Il est lu pour être édité dans les
/// options, et le sera plus tard pour signer les contenus. Retourne `null`
/// tant que l'utilisateur n'a jamais enregistré son profil.
class GetLocalUserUsecase extends Usecase<NoParams, GetLocalUserFailure, User?> {
  /// Crée un [GetLocalUserUsecase].
  GetLocalUserUsecase(this._userRepository);

  final UserRepository _userRepository;

  @override
  Future<Either<GetLocalUserFailure, User?>> call(NoParams params) async {
    try {
      final user = await _userRepository.getLocal();
      return Right(user);
    } on DataException catch (error, stackTrace) {
      AppLogger.error('GetLocalUserUsecase', error, stackTrace);
      return const Left(GetLocalUserFailure.invalidData);
    } on DatasourceException catch (error, stackTrace) {
      AppLogger.error('GetLocalUserUsecase', error, stackTrace);
      return const Left(GetLocalUserFailure.storageError);
    } catch (error, stackTrace) {
      AppLogger.error('GetLocalUserUsecase', error, stackTrace);
      return const Left(GetLocalUserFailure.unknown);
    }
  }
}

/// Échecs possibles du [GetLocalUserUsecase].
enum GetLocalUserFailure {
  /// La donnée lue est invalide ou corrompue.
  invalidData,

  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue lors de la lecture du profil.
  unknown,
}
