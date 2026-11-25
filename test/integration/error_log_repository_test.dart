import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/infra/resources/drift.database.dart';
import 'package:bedbug/infra/resources/error_log/error_log/error_log.config.dart';
import 'package:bedbug/infra/resources/error_log/error_log/error_log.entity.dart';
import 'package:bedbug/infra/resources/error_log/error_log/error_log.mapper.drift.dart';
import 'package:bedbug/infra/resources/error_log/error_log/error_log.repository.drift.dart';
import 'package:bedbug/infra/resources/signature/signature/signature.entity.dart';
import 'package:bedbug/infra/resources/signature/signature/signature.repository.dart';
import 'package:bedbug/infra/resources/signature/signature/signature.repository.drift.dart';
import 'package:bedbug/logic/usecases/signature/get_local_signature/get_local_signature.usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/drift_test_helper.dart';

/// Lit toutes les traces du journal des erreurs, directement dans la base de [container].
Future<List<ErrorLog>> _readErrorLogs(ProviderContainer container) async {
  final database = container.read(appDatabaseProvider);
  final rows = await database.select(database.errorLogs).get();
  return rows.map(ErrorLogDriftMapper.toEntity).toList();
}

void main() {
  late ProviderContainer container;

  setUp(() {
    container = createTestContainer();
  });

  tearDown(() {
    container.dispose();
  });

  test('enregistre la source, le type et le message de l\'erreur', () async {
    final repository = container.read(errorLogRepositoryProvider);

    await repository.record(source: 'SomeUsecase', error: StateError('boom'), stackTrace: StackTrace.current);

    final logs = await _readErrorLogs(container);
    expect(logs, hasLength(1));
    expect(logs.single.source, 'SomeUsecase');
    expect(logs.single.errorType, 'StateError');
    expect(logs.single.message, contains('boom'));
    expect(logs.single.stackTrace, isNotEmpty);
  });

  test('ne garde que les traces les plus récentes au-delà du plafond', () async {
    final repository = container.read(errorLogRepositoryProvider);

    for (var index = 0; index < maxErrorLogs + 5; index++) {
      await repository.record(source: 'Usecase$index', error: Exception('$index'), stackTrace: StackTrace.empty);
    }

    final sources = (await _readErrorLogs(container)).map((log) => log.source).toSet();
    expect(sources, hasLength(maxErrorLogs));
    expect(sources, contains('Usecase${maxErrorLogs + 4}'));
    expect(sources, isNot(contains('Usecase0')));
  });

  test('ne lève pas quand la base est fermée', () async {
    final repository = container.read(errorLogRepositoryProvider);
    await container.read(appDatabaseProvider).close();

    await expectLater(
      repository.record(source: 'SomeUsecase', error: Exception('boom'), stackTrace: StackTrace.empty),
      completes,
    );
  });

  test('un use case enregistre son erreur imprévue dans le journal', () async {
    final failingContainer = createTestContainer(
      overrides: [signatureRepositoryProvider.overrideWithValue(_FailingSignatureRepository())],
    );
    addTearDown(failingContainer.dispose);

    final result = await failingContainer.read(getLocalSignatureUsecaseProvider)(const NoParams());

    expect(result.isFailure, isTrue);
    final sources = (await _readErrorLogs(failingContainer)).map((log) => log.source);
    expect(sources, contains('GetLocalSignatureUsecase'));
  });
}

/// Repository de signatures dont toutes les lectures échouent de façon imprévue.
class _FailingSignatureRepository implements SignatureRepository {
  @override
  Future<Signature?> getLocal() {
    throw StateError('boom');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}
