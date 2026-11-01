import 'package:bedbug/application/style/app_icons.dart';
import 'package:bedbug/application/widgets/icons/app_icon.dart';
import 'package:flutter_test/flutter_test.dart';

export 'package:bedbug/application/style/app_icons.dart';

/// Retourne le finder des [AppIcon] affichant [icon], équivalent de `find.byIcon` pour nos icônes.
///
/// - [icon] : icône cherchée.
Finder findAppIcon(AppIcons icon) {
  return find.byWidgetPredicate((widget) => widget is AppIcon && widget.icon == icon);
}
