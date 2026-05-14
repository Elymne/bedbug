import 'package:bedbug/application/router/app_router.dart';
import 'package:bedbug/application/screens/splash/splash_notifier.dart';
import 'package:bedbug/application/screens/splash/widgets/app_title_text.dart';
import 'package:bedbug/application/screens/splash/widgets/splash_bedbug.dart';
import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/style/app_values.dart';
import 'package:bedbug/shared/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Splashscreen de l'application.
///
/// Affiche une animation du logo de l'app avec une bar de chargement.
/// C'est sur cette vue qu'on charge les données récupéré des utilisateurs.
class SplashScreen extends ConsumerStatefulWidget {
  /// Crée une [SplashScreen].
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _State();
}

class _State extends ConsumerState<SplashScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = context.loc;

    ref.listen(splashNotifierProvider, (previous, next) {
      if (next.isLoading) return;
      if (next.hasValue) context.go(homePath);
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(AppValues.baseMargin),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SplashBedbug(
                style: TextStyle(
                  fontFamily: 'DynaPuff',
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              AppTitleText(
                text: l10n.title,
                style: const TextStyle(
                  fontFamily: 'DynaPuff',
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
