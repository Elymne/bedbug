import 'package:bedbug/application/l10n/generated/app_localizations.dart';
import 'package:bedbug/shared/extensions/datetime_x.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('fr'));

  /// Date située [elapsed] avant maintenant.
  DateTime ago(Duration elapsed) {
    return DateTime.now().subtract(elapsed);
  }

  group('timeAgoLong', () {
    test('écrit le temps écoulé en toutes lettres, au singulier comme au pluriel', () {
      expect(ago(const Duration(seconds: 10)).timeAgoLong(l10n), "À l'instant");
      expect(ago(const Duration(minutes: 1)).timeAgoLong(l10n), 'Il y a une minute');
      expect(ago(const Duration(minutes: 12)).timeAgoLong(l10n), 'Il y a 12 minutes');
      expect(ago(const Duration(hours: 1)).timeAgoLong(l10n), 'Il y a une heure');
      expect(ago(const Duration(hours: 5)).timeAgoLong(l10n), 'Il y a 5 heures');
      expect(ago(const Duration(days: 1)).timeAgoLong(l10n), 'Il y a une journée');
      expect(ago(const Duration(days: 6)).timeAgoLong(l10n), 'Il y a 6 jours');
      expect(ago(const Duration(days: 31)).timeAgoLong(l10n), 'Il y a un mois');
      expect(ago(const Duration(days: 90)).timeAgoLong(l10n), 'Il y a 3 mois');
      expect(ago(const Duration(days: 400)).timeAgoLong(l10n), 'Il y a un an');
      expect(ago(const Duration(days: 800)).timeAgoLong(l10n), 'Il y a 2 ans');
    });
  });
}
