import 'package:bedbug/application/widgets/reactions/app_reaction_bubble.dart';
import 'package:bedbug/application/widgets/scatter/app_scatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

void main() {
  testWidgets('disperse de vraies réactions de tailles variées sans chevauchement ni débordement', (tester) async {
    final bubbleTexts = [null, 'mdr', 'trop bien ce post, vraiment', null, 'ok', 'je ne m\'y attendais pas du tout'];
    final keys = [for (var index = 0; index < 30; index++) ValueKey(index)];

    await pumpApp(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(
            width: 320,
            child: AppScatter(
              seed: 3,
              children: [
                for (final (index, key) in keys.indexed)
                  AppReactionBubble(
                    key: key,
                    avatarText: '(◕‿◕)',
                    bubbleText: bubbleTexts[index % bubbleTexts.length],
                    ghostColor: Colors.pink,
                    isAnimating: false,
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    final scatterRect = tester.getRect(find.byType(AppScatter));
    final rects = [for (final key in keys) tester.getRect(find.byKey(key))];
    for (final (index, rect) in rects.indexed) {
      expect(rect.left, greaterThanOrEqualTo(scatterRect.left), reason: 'réaction $index');
      expect(rect.right, lessThanOrEqualTo(scatterRect.right), reason: 'réaction $index');
      expect(rect.bottom, lessThanOrEqualTo(scatterRect.bottom), reason: 'réaction $index');
      for (final other in rects.skip(index + 1)) {
        expect(rect.overlaps(other), isFalse, reason: 'réaction $index');
      }
    }
  });
}
