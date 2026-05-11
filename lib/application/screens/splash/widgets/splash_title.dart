import 'package:bedbug/application/widgets/texts/app_title_text.dart';
import 'package:bedbug/shared/extensions/build_context_x.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Widget affichant le titre animé de l'application sur le splashscreen.
class SplashTitle extends ConsumerWidget {
  /// Crée un [SplashTitle].
  const SplashTitle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppTitleText(
      text: context.loc.title,
      style: const TextStyle(
        fontFamily: 'DynaPuff',
        fontSize: 48,
        fontWeight: FontWeight.bold,
        letterSpacing: 4,
      ),
    );
  }
}
