import 'dart:io';

import 'package:bedbug/features/exchange/domain/entities/exchange_log.dart';
import 'package:bedbug/features/exchange/domain/enums/exchange_frame_type.dart';
import 'package:bedbug/features/exchange/domain/enums/exchange_log_outcome.dart';
import 'package:bedbug/features/exchange/domain/usecases/get_exchange_logs_usecase.dart';
import 'package:bedbug/features/exchange/domain/usecases/save_exchange_log_usecase.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/hive_test_helper.dart';

/// Construit une trace datée de [minute] minutes après une date fixe.
///
/// - [id] : identifiant de la trace.
/// - [minute] : décalage de la date, en minutes.
ExchangeLog _buildLog(String id, int minute) {
  final date = DateTime(2026, 10, 31).add(Duration(minutes: minute));
  return ExchangeLog(
    id: id,
    createdAt: date,
    updatedAt: date,
    peerAddress: 'AA:BB',
    outcome: ExchangeLogOutcome.timeout,
    isInitiator: false,
    duration: const Duration(milliseconds: 1500),
    awaitedFrame: ExchangeFrameType.offer,
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

  /// Enregistre [log] puis retourne le journal.
  Future<void> save(ExchangeLog log) async {
    await container.read(saveExchangeLogUsecaseProvider)(SaveExchangeLogParams(log: log));
  }

  /// Lit le journal.
  Future<List<ExchangeLog>> readLogs() async {
    return (await container.read(getExchangeLogsUsecaseProvider)(const NoParams())).right!;
  }

  test('relit une trace à l\'identique, y compris une trace sans échange', () async {
    final now = DateTime(2026, 10, 31);
    await save(_buildLog('session', 1));
    await save(
      ExchangeLog(
        id: 'ignore',
        createdAt: now,
        updatedAt: now,
        peerAddress: 'CC:DD',
        outcome: ExchangeLogOutcome.peerDelayed,
      ),
    );

    final logs = await readLogs();

    final session = logs.first;
    expect(session.outcome, ExchangeLogOutcome.timeout);
    expect(session.isInitiator, isFalse);
    expect(session.duration, const Duration(milliseconds: 1500));
    expect(session.awaitedFrame, ExchangeFrameType.offer);
    expect(session.sentBytes, 10);
    expect(session.receivedBytes, 20);
    expect(session.importedContents, 1);
    expect(session.rejectedContents, 2);
    expect(session.importedReactions, 3);
    expect(session.rejectedReactions, 4);
    expect(session.removedContents, 5);
    expect(logs.last.isInitiator, isNull);
    expect(logs.last.awaitedFrame, isNull);
  });

  test('retourne les traces de la plus récente à la plus ancienne', () async {
    await save(_buildLog('ancienne', 1));
    await save(_buildLog('recente', 3));
    await save(_buildLog('milieu', 2));

    final logs = await readLogs();

    expect(logs.map((log) => log.id), ['recente', 'milieu', 'ancienne']);
  });

  test('oublie les traces les plus anciennes au-delà de la limite', () async {
    for (var index = 0; index < maxExchangeLogs + 5; index++) {
      await save(_buildLog('trace-$index', index));
    }

    final logs = await readLogs();

    expect(logs, hasLength(maxExchangeLogs));
    expect(logs.first.id, 'trace-${maxExchangeLogs + 4}');
    expect(logs.last.id, 'trace-5');
  });
}
