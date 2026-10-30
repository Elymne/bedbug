import 'package:bedbug/features/signature/domain/entities/signature.dart';
import 'package:bedbug/features/signature/domain/repositories/signature_repository.dart';
import 'package:bedbug/features/signature/infrastructure/datasources/hive_signature_repository.dart';
import 'package:bedbug/shared/domain/either.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:bedbug/shared/domain/usecase.dart';
import 'package:bedbug/shared/exceptions/data_exception.dart';
import 'package:bedbug/shared/exceptions/datasource_exception.dart';
import 'package:bedbug/shared/logger/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Nombre maximal de pseudos de signature proposés en autocomplétion.
const int maxSignatureSuggestions = 4;

/// Provider du [GetSignatureSuggestionsUsecase].
final getSignatureSuggestionsUsecaseProvider = Provider<GetSignatureSuggestionsUsecase>((ref) {
  return GetSignatureSuggestionsUsecase(ref.read(signatureRepositoryProvider));
});

/// Propose les signatures connues de l'appareil dont le pseudo commence par la saisie de l'utilisateur.
///
/// Comme pour les flairs, l'utilisateur ne peut pas deviner quelles
/// signatures figurent sur son appareil : on les lui suggère pendant la
/// frappe, pour qu'un tap l'amène à la page de la signature et aux contenus
/// qu'elle a signés. Plusieurs signatures peuvent porter le même pseudo :
/// chacune est proposée séparément, reconnaissable à son bedbug. La saisie
/// peut être préfixée de `s/`, comme les pseudos sont affichés. La signature
/// anonyme n'est jamais proposée : elle ne désigne personne, filtrer dessus
/// n'a pas de sens.
class GetSignatureSuggestionsUsecase
    extends Usecase<GetSignatureSuggestionsParams, GetSignatureSuggestionsFailure, List<Signature>> {
  /// Crée un [GetSignatureSuggestionsUsecase].
  GetSignatureSuggestionsUsecase(this._signatureRepository);

  final SignatureRepository _signatureRepository;

  @override
  Future<Either<GetSignatureSuggestionsFailure, List<Signature>>> call(GetSignatureSuggestionsParams params) async {
    try {
      final prefix = params.input.trim().replaceFirst(RegExp('^s/', caseSensitive: false), '');
      if (prefix.isEmpty) {
        return const Right([]);
      }

      final signatures = await _signatureRepository.getAllWithPseudoStartingWith(
        prefix,
        limit: maxSignatureSuggestions,
      );
      return Right(signatures.where((signature) => signature.id != anonymousSignatureId).toList());
    } on DataException catch (error, stackTrace) {
      AppLogger.error('GetSignatureSuggestionsUsecase', error, stackTrace);
      return const Left(GetSignatureSuggestionsFailure.invalidData);
    } on DatasourceException catch (error, stackTrace) {
      AppLogger.error('GetSignatureSuggestionsUsecase', error, stackTrace);
      return const Left(GetSignatureSuggestionsFailure.storageError);
    } catch (error, stackTrace) {
      AppLogger.error('GetSignatureSuggestionsUsecase', error, stackTrace);
      return const Left(GetSignatureSuggestionsFailure.unknown);
    }
  }
}

/// Échecs possibles du [GetSignatureSuggestionsUsecase].
enum GetSignatureSuggestionsFailure {
  /// La donnée lue est invalide ou corrompue.
  invalidData,

  /// Erreur de la couche de stockage locale.
  storageError,

  /// Erreur inattendue lors de la recherche de suggestions.
  unknown,
}

/// Paramètres du [GetSignatureSuggestionsUsecase].
class GetSignatureSuggestionsParams extends Params {
  /// Crée des [GetSignatureSuggestionsParams].
  ///
  /// - [input] : saisie brute de l'utilisateur, avec ou sans `s/` initial.
  const GetSignatureSuggestionsParams({required this.input});

  /// Saisie brute de l'utilisateur, avec ou sans `s/` initial.
  final String input;
}
