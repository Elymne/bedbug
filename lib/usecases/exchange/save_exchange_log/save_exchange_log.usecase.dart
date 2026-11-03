import 'package:bedbug/core/domain/either.dart';
import 'package:bedbug/core/domain/usecase.dart';
import 'package:bedbug/core/extensions/string_uuid_x.dart';
import 'package:bedbug/core/logger/app_logger.dart';
import 'package:bedbug/gateways/exchange/exchange_frame_codec/exchange_frame_codec.gateway.dart';
import 'package:bedbug/resources/data.exception.dart';
import 'package:bedbug/resources/datasource.exception.dart';
import 'package:bedbug/resources/error_log/error_log/error_log.repository.dart';
import 'package:bedbug/resources/error_log/error_log/error_log.repository.hive.dart';
import 'package:bedbug/resources/exchange/exchange_log/exchange_log.entity.dart';
import 'package:bedbug/resources/exchange/exchange_log/exchange_log.repository.dart';
import 'package:bedbug/resources/exchange/exchange_log/exchange_log.repository.hive.dart';
import 'package:bedbug/resources/exchange/exchange_log/exchange_log_step.enum.dart';
import 'package:bedbug/usecases/exchange/save_exchange_log/save_exchange_log.config.dart';
import 'package:bedbug/usecases/exchange/save_exchange_log/save_exchange_log.failure.dart';
import 'package:bedbug/usecases/exchange/save_exchange_log/save_exchange_log.params.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du [SaveExchangeLogUsecase].
final saveExchangeLogUsecaseProvider = Provider<SaveExchangeLogUsecase>((ref) {
  return SaveExchangeLogUsecase(ref.read(exchangeLogRepositoryProvider), ref.read(errorLogRepositoryProvider));
});

/// Ajoute une rencontre au journal des échanges, sans dépasser [maxExchangeLogs] traces.
///
/// Les échanges se déroulent en arrière-plan, sans témoin : sans cette trace, rien ne permettrait de savoir pourquoi
/// un contenu n'est pas arrivé.
///
/// C'est aussi la frontière entre le protocole et le journal : la session parle en trames ([ExchangeFrameType]), le
/// journal en étapes ([ExchangeLogStep]). Ce use case traduit l'une en l'autre, pour que le journal ne dépende pas du
/// protocole.
class SaveExchangeLogUsecase extends Usecase<SaveExchangeLogParams, SaveExchangeLogFailure, void> {
  /// Crée un [SaveExchangeLogUsecase].
  SaveExchangeLogUsecase(this._exchangeLogRepository, this._errorLogRepository);

  final ExchangeLogRepository _exchangeLogRepository;
  final ErrorLogRepository _errorLogRepository;

  @override
  Future<Either<SaveExchangeLogFailure, void>> call(SaveExchangeLogParams params) async {
    try {
      final log = ExchangeLog(
        id: UuidX.generate(),
        createdAt: params.startedAt,
        updatedAt: DateTime.now(),
        peerAddress: params.peerAddress,
        outcome: params.outcome,
        isInitiator: params.isInitiator,
        duration: params.duration,
        awaitedStep: _stepOf(params.awaitedFrame),
        sentBytes: params.sentBytes,
        receivedBytes: params.receivedBytes,
        importedContents: params.importedContents,
        rejectedContents: params.rejectedContents,
        importedReactions: params.importedReactions,
        rejectedReactions: params.rejectedReactions,
        removedContents: params.removedContents,
      );
      await _exchangeLogRepository.addOne(log);
      await _exchangeLogRepository.keepNewest(maxExchangeLogs);
      return const Right(null);
    } on DataException catch (error, stackTrace) {
      AppLogger.error('SaveExchangeLogUsecase', error, stackTrace);
      return const Left(SaveExchangeLogFailure.storageError);
    } on DatasourceException catch (error, stackTrace) {
      AppLogger.error('SaveExchangeLogUsecase', error, stackTrace);
      return const Left(SaveExchangeLogFailure.storageError);
    } catch (error, stackTrace) {
      AppLogger.error('SaveExchangeLogUsecase', error, stackTrace);
      await _errorLogRepository.record(source: 'SaveExchangeLogUsecase', error: error, stackTrace: stackTrace);
      return const Left(SaveExchangeLogFailure.unknown);
    }
  }

  /// Retourne l'étape du journal correspondant à la trame [frame], `null` sans échange.
  ///
  /// Une trame d'abandon n'est jamais attendue : elle n'a pas d'étape.
  ///
  /// - [frame] : trame du protocole attendue à la fin de l'échange.
  ExchangeLogStep? _stepOf(ExchangeFrameType? frame) {
    return switch (frame) {
      null => null,
      ExchangeFrameType.hello => ExchangeLogStep.hello,
      ExchangeFrameType.offer => ExchangeLogStep.offer,
      ExchangeFrameType.request => ExchangeLogStep.request,
      ExchangeFrameType.data => ExchangeLogStep.data,
      ExchangeFrameType.done => ExchangeLogStep.done,
      ExchangeFrameType.error => null,
    };
  }
}
