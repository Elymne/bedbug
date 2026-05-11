import 'package:bedbug/application/screens/splash/splash_notifier.dart';
import 'package:bedbug/application/screens/splash/widgets/splash_bedbug.dart';
import 'package:bedbug/application/screens/splash/widgets/splash_title.dart';
import 'package:bedbug/application/style/app_colors.dart';
import 'package:bedbug/application/style/app_values.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    ref.listen(splashNotifierProvider, (previous, next) {
      if (previous?.isLoading == true && next.hasValue) {}
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(AppValues.baseMargin),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SplashBedbug(
                style: TextStyle(
                  fontFamily: 'DynaPuff',
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SplashTitle(),
            ],
          ),
        ),
      ),
    );
  }
}
