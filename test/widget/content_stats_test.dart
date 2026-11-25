import 'package:bedbug/application/widgets/stats/content_stats.widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

void main() {
  testWidgets('affiche le nombre de rebonds précédé de + et le nombre de réactions', (tester) async {
    final semantics = tester.ensureSemantics();

    await pumpApp(tester, const Scaffold(body: ContentStats(bounce: 12, reactionCount: 3)));
    await tester.pump();

    // Deux fois chacun : le nombre lui-même, et sa silhouette dans la couche de l'effet ghost.
    expect(find.text('+12'), findsNWidgets(2));
    expect(find.text('3'), findsNWidgets(2));
    expect(find.bySemanticsLabel('12 rebonds'), findsOneWidget);
    expect(find.bySemanticsLabel('3 réactions'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('n\'affiche pas de nombre de réactions tant qu\'il n\'est pas connu', (tester) async {
    await pumpApp(tester, const Scaffold(body: ContentStats(bounce: 12, reactionCount: null)));
    await tester.pump();

    expect(find.text('+12'), findsNWidgets(2));
    expect(find.text('0'), findsNothing);
  });
}
