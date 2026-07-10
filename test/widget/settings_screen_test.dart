import 'package:bedbug/application/screens/settings/settings_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_app.dart';

void main() {
  testWidgets('affiche la page de settings', (tester) async {
    await pumpApp(tester, const SettingsScreen());
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
  });
}
