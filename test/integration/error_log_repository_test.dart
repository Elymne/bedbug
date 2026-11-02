import 'dart:io';

import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/resources/error_log/error_log/error_log.config.dart';
import 'package:bedbug/resources/error_log/error_log/error_log.model.hive.dart';
import 'package:bedbug/resources/error_log/error_log/error_log.repository.hive.dart';
import 'package:bedbug/resources/signature/signature/signature.entity.dart';
import 'package:bedbug/resources/signature/signature/signature.repository.dart';
import 'package:bedbug/resources/signature/signature/signature.repository.hive.dart';
import 'package:bedbug/usecases/signature/get_local_signature/get_local_signature.usecase.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import '../helpers/hive_test_helper.dart';

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

  test('enregistre la source, le type et le message de l\'erreur', () async {
    final repository = container.read(errorLogRepositoryProvider);

    await repository.record(source: 'SomeUsecase', error: StateError('boom'), stackTrace: StackTrace.current);

    final logs = Hive.box<ErrorLogHiveModel>(errorLogBoxName).values.map((model) => model.toEntity()).toList();
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

    final sources = Hive.box<ErrorLogHiveModel>(errorLogBoxName).values.map((model) => model.source).toSet();
    expect(sources, hasLength(maxErrorLogs));
    expect(sources, contains('Usecase${maxErrorLogs + 4}'));
  });

  test('ne lève pas quand la box est fermée', () async {
    final repository = container.read(errorLogRepositoryProvider);
    await Hive.box<ErrorLogHiveModel>(errorLogBoxName).close();

    await expectLater(
      repository.record(source: 'SomeUsecase', error: Exception('boom'), stackTrace: StackTrace.empty),
      completes,
    );
  });

  test('un use case enregistre son erreur imprévue dans le journal', () async {
    final failingContainer = ProviderContainer(
      overrides: [signatureRepositoryProvider.overrideWithValue(_FailingSignatureRepository())],
    );
    addTearDown(failingContainer.dispose);

    final result = await failingContainer.read(getLocalSignatureUsecaseProvider)(const NoParams());

    expect(result.isFailure, isTrue);
    final sources = Hive.box<ErrorLogHiveModel>(errorLogBoxName).values.map((model) => model.source);
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
