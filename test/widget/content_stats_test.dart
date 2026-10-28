import 'package:bedbug/application/widgets/stats/content_stats.dart';
import 'package:bedbug/features/content/domain/usecases/count_content_reactions_usecase.dart';
import 'package:bedbug/shared/domain/either.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

class _FakeCountContentReactionsUsecase implements CountContentReactionsUsecase {
  @override
  Future<Either<CountContentReactionsFailure, int>> call(CountContentReactionsParams params) async {
    return const Right(3);
  }
}

void main() {
  testWidgets('affiche le nombre de rebonds précédé de + et le nombre de réactions', (tester) async {
    final semantics = tester.ensureSemantics();

    await pumpApp(
      tester,
      const Scaffold(body: ContentStats(contentId: 'content', bounce: 12)),
      overrides: [countContentReactionsUsecaseProvider.overrideWithValue(_FakeCountContentReactionsUsecase())],
    );
    await tester.pump();

    // Deux fois chacun : le nombre lui-même, et sa silhouette dans la couche de l'effet ghost.
    expect(find.text('+12'), findsNWidgets(2));
    expect(find.text('3'), findsNWidgets(2));
    expect(find.bySemanticsLabel('12 rebonds'), findsOneWidget);
    expect(find.bySemanticsLabel('3 réactions'), findsOneWidget);
    semantics.dispose();
  });
}
