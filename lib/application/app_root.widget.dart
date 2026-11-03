import 'package:bedbug/application/l10n/app_localizations_provider.dart';
import 'package:bedbug/application/l10n/generated/app_localizations.dart';
import 'package:bedbug/application/l10n/locale_notifier.dart';
import 'package:bedbug/application/router/app_router.dart';
import 'package:bedbug/application/style/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Pour permettre de créer des widgets non lié au build context.
/// Utile pour mes snackbars.
final GlobalKey<ScaffoldMessengerState> messengerKey = GlobalKey<ScaffoldMessengerState>();

/// Widget racine de l'application.
///
/// Configure le thème, la localisation et le router GoRouter.
class AppRoot extends ConsumerStatefulWidget {
  /// Crée un [AppRoot].
  const AppRoot({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _State();
}

class _State extends ConsumerState<AppRoot> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeNotifierProvider);

    return MaterialApp.router(
      title: 'Data SL Consulting Tools',
      scaffoldMessengerKey: messengerKey,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.light,
      routerConfig: router,
      builder: (context, child) {
        final l10n = AppLocalizations.of(context)!;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(appLocalizationsProvider.notifier).state = l10n;
        });
        return child!;
      },
    );
  }
}
