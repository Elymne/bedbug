import 'package:bedbug/application/screens/exchange_logs/exchange_logs_screen.dart';
import 'package:bedbug/features/exchange/domain/entities/exchange_log.dart';
import 'package:bedbug/features/exchange/domain/enums/exchange_frame_type.dart';
import 'package:bedbug/features/exchange/domain/enums/exchange_log_outcome.dart';
import 'package:bedbug/features/exchange/domain/usecases/get_exchange_logs_usecase.dart';
import 'package:bedbug/shared/domain/either.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

/// Fake [GetExchangeLogsUsecase] retournant un journal fixe.
class _FakeGetExchangeLogsUsecase implements GetExchangeLogsUsecase {
  _FakeGetExchangeLogsUsecase(this._logs);
  final List<ExchangeLog> _logs;

  @override
  Future<Either<GetExchangeLogsFailure, List<ExchangeLog>>> call(NoParams params) async {
    return Right(_logs);
  }
}

void main() {
  final date = DateTime(2026, 10, 31, 14, 5);

  /// Monte la page avec le journal [logs].
  Future<void> pumpScreen(WidgetTester tester, List<ExchangeLog> logs) async {
    await pumpApp(
      tester,
      const ExchangeLogsScreen(),
      overrides: [getExchangeLogsUsecaseProvider.overrideWithValue(_FakeGetExchangeLogsUsecase(logs))],
    );
    await tester.pumpAndSettle();
  }

  testWidgets('indique qu\'il n\'y a encore aucune rencontre', (tester) async {
    await pumpScreen(tester, const []);

    expect(find.text('Aucune rencontre pour le moment.'), findsOneWidget);
  });

  testWidgets('détaille une session interrompue', (tester) async {
    await pumpScreen(tester, [
      ExchangeLog(
        id: 'session',
        createdAt: date,
        updatedAt: date,
        peerAddress: 'AA:BB',
        outcome: ExchangeLogOutcome.transportClosed,
        isInitiator: true,
        duration: const Duration(milliseconds: 2500),
        awaitedFrame: ExchangeFrameType.data,
        sentBytes: 100,
        receivedBytes: 200,
        importedContents: 3,
        rejectedContents: 1,
      ),
    ]);

    expect(find.text('Connexion perdue'), findsOneWidget);
    expect(find.text('Pair : AA:BB'), findsOneWidget);
    expect(find.text('Ce téléphone a appelé'), findsOneWidget);
    expect(find.text('Durée : 2.5 s'), findsOneWidget);
    expect(find.text('Arrêté en attendant : data'), findsOneWidget);
    expect(find.text('Octets envoyés : 100, reçus : 200'), findsOneWidget);
    expect(find.text('Contenus reçus : 3, écartés : 1'), findsOneWidget);
  });

  testWidgets('une rencontre sans échange n\'affiche pas de détails de session', (tester) async {
    await pumpScreen(tester, [
      ExchangeLog(
        id: 'ignore',
        createdAt: date,
        updatedAt: date,
        peerAddress: 'CC:DD',
        outcome: ExchangeLogOutcome.peerDelayed,
      ),
    ]);

    expect(find.text('Pair ignoré : échange trop récent'), findsOneWidget);
    expect(find.textContaining('Octets'), findsNothing);
  });
}
