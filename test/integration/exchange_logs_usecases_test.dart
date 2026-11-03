import 'dart:io';

import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/gateways/exchange/exchange_frame_codec/exchange_frame_codec.gateway.dart';
import 'package:bedbug/resources/exchange/exchange_log/exchange_log.entity.dart';
import 'package:bedbug/resources/exchange/exchange_log/exchange_log_outcome.enum.dart';
import 'package:bedbug/resources/exchange/exchange_log/exchange_log_step.enum.dart';
import 'package:bedbug/usecases/exchange/get_exchange_logs/get_exchange_logs.usecase.dart';
import 'package:bedbug/usecases/exchange/save_exchange_log/save_exchange_log.config.dart';
import 'package:bedbug/usecases/exchange/save_exchange_log/save_exchange_log.params.dart';
import 'package:bedbug/usecases/exchange/save_exchange_log/save_exchange_log.usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/hive_test_helper.dart';

/// Construit une rencontre datée de [minute] minutes après une date fixe.
///
/// - [peerAddress] : adresse du pair, qui sert ici à reconnaître la trace.
/// - [minute] : décalage de la date, en minutes.
/// - [awaitedFrame] : trame attendue à la fin de l'échange.
SaveExchangeLogParams _buildParams(String peerAddress, int minute, {ExchangeFrameType? awaitedFrame}) {
  return SaveExchangeLogParams(
    startedAt: DateTime(2026, 10, 31).add(Duration(minutes: minute)),
    peerAddress: peerAddress,
    outcome: ExchangeLogOutcome.timeout,
    isInitiator: false,
    duration: const Duration(milliseconds: 1500),
    awaitedFrame: awaitedFrame ?? ExchangeFrameType.offer,
    sentBytes: 10,
    receivedBytes: 20,
    importedContents: 1,
    rejectedContents: 2,
    importedReactions: 3,
    rejectedReactions: 4,
    removedContents: 5,
  );
}

void main() {
  late Directory tempDir;
  late ProviderContainer container;

  setUp(() async {
    tempDir = await openTestHive();
    container = ProviderContainer();
  });

  tearDown(() async {
    container.dispose();
    await closeTestHive(tempDir);
  });

  /// Enregistre la rencontre décrite par [params].
  Future<void> save(SaveExchangeLogParams params) async {
    await container.read(saveExchangeLogUsecaseProvider)(params);
  }

  /// Lit le journal.
  Future<List<ExchangeLog>> readLogs() async {
    return (await container.read(getExchangeLogsUsecaseProvider)(const NoParams())).right!;
  }

  test('relit une trace à l\'identique, y compris une trace sans échange', () async {
    await save(_buildParams('AA:BB', 1));
    await save(
      SaveExchangeLogParams(
        startedAt: DateTime(2026, 10, 31),
        peerAddress: 'CC:DD',
        outcome: ExchangeLogOutcome.peerDelayed,
      ),
    );

    final logs = await readLogs();

    final session = logs.first;
    expect(session.id, isNotEmpty);
    expect(session.peerAddress, 'AA:BB');
    expect(session.createdAt, DateTime(2026, 10, 31, 0, 1));
    expect(session.outcome, ExchangeLogOutcome.timeout);
    expect(session.isInitiator, isFalse);
    expect(session.duration, const Duration(milliseconds: 1500));
    expect(session.awaitedStep, ExchangeLogStep.offer);
    expect(session.sentBytes, 10);
    expect(session.receivedBytes, 20);
    expect(session.importedContents, 1);
    expect(session.rejectedContents, 2);
    expect(session.importedReactions, 3);
    expect(session.rejectedReactions, 4);
    expect(session.removedContents, 5);
    expect(logs.last.isInitiator, isNull);
    expect(logs.last.awaitedStep, isNull);
  });

  test('traduit la trame attendue en étape du journal', () async {
    for (final (index, frame) in ExchangeFrameType.values.indexed) {
      await save(_buildParams(frame.name, index, awaitedFrame: frame));
    }

    final stepsByPeer = {for (final log in await readLogs()) log.peerAddress: log.awaitedStep};

    expect(stepsByPeer, {
      'hello': ExchangeLogStep.hello,
      'offer': ExchangeLogStep.offer,
      'request': ExchangeLogStep.request,
      'data': ExchangeLogStep.data,
      'done': ExchangeLogStep.done,
      'error': null,
    });
  });

  test('retourne les traces de la plus récente à la plus ancienne', () async {
    await save(_buildParams('ancienne', 1));
    await save(_buildParams('recente', 3));
    await save(_buildParams('milieu', 2));

    final logs = await readLogs();

    expect(logs.map((log) => log.peerAddress), ['recente', 'milieu', 'ancienne']);
  });

  test('oublie les traces les plus anciennes au-delà de la limite', () async {
    for (var index = 0; index < maxExchangeLogs + 5; index++) {
      await save(_buildParams('trace-$index', index));
    }

    final logs = await readLogs();

    expect(logs, hasLength(maxExchangeLogs));
    expect(logs.first.peerAddress, 'trace-${maxExchangeLogs + 4}');
    expect(logs.last.peerAddress, 'trace-5');
  });
}
