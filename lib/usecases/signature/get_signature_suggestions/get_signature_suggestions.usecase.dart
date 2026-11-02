import 'package:bedbug/core/domain/either.dart';
import 'package:bedbug/core/domain/usecase.dart';
import 'package:bedbug/core/logger/app_logger.dart';
import 'package:bedbug/resources/data.exception.dart';
import 'package:bedbug/resources/datasource.exception.dart';
import 'package:bedbug/resources/error_log/error_log/error_log.repository.dart';
import 'package:bedbug/resources/error_log/error_log/error_log.repository.hive.dart';
import 'package:bedbug/resources/signature/signature/signature.entity.dart';
import 'package:bedbug/resources/signature/signature/signature.repository.dart';
import 'package:bedbug/resources/signature/signature/signature.repository.hive.dart';
import 'package:bedbug/usecases/signature/get_signature_suggestions/get_signature_suggestions.failure.dart';
import 'package:bedbug/usecases/signature/get_signature_suggestions/get_signature_suggestions.params.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Nombre maximal de pseudos de signature proposés en autocomplétion.
const int maxSignatureSuggestions = 4;

/// Provider du [GetSignatureSuggestionsUsecase].
final getSignatureSuggestionsUsecaseProvider = Provider<GetSignatureSuggestionsUsecase>((ref) {
  return GetSignatureSuggestionsUsecase(ref.read(signatureRepositoryProvider), ref.read(errorLogRepositoryProvider));
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
  GetSignatureSuggestionsUsecase(this._signatureRepository, this._errorLogRepository);

  final SignatureRepository _signatureRepository;
  final ErrorLogRepository _errorLogRepository;

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
      await _errorLogRepository.record(source: 'GetSignatureSuggestionsUsecase', error: error, stackTrace: stackTrace);
      return const Left(GetSignatureSuggestionsFailure.unknown);
    }
  }
}
