import 'package:bedbug/application/screens/splash/splash_notifier.dart';
import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/style/app_values.dart';
import 'package:bedbug/application/widgets/app_snackbar.dart';
import 'package:bedbug/shared/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Splashscreen de l'application.
/// TODO : Je vais en faire une page de chargement des contents.
/// On pourra utiliser cette page à chaque fois que l'utilisateur soiuhaites charger ses contents.
/// Pourquoi ? Car je compte stocker de manière brute les données dans le téléphone pour éviter de griller la batterie trop vite.
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
    final splashWatcher = ref.watch(splashNotifierProvider);
    final l10n = context.loc;

    ref.listen(splashNotifierProvider, (previous, next) {
      if (next.isLoading) return;

      if (previous?.isLoading == true && !next.isLoading) {
        final message = next.value?.failureMessage;
        // TODO = Je vais gérer les erreurs avec un bouton pour relancer l'action.
        if (message != null) AppSnackbar.showError(context, message);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(AppValues.baseMargin),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [],
          ),
        ),
      ),
    );
  }
}
