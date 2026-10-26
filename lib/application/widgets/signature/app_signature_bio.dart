import 'package:bedbug/application/style/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Courte description d'une signature, affichée centrée et en retrait sous son pseudo.
///
/// Partagé entre la page d'une signature et l'aperçu du formulaire de
/// profil, pour que l'utilisateur voie sa description telle que les autres
/// la verront.
class AppSignatureBio extends ConsumerWidget {
  /// Crée un [AppSignatureBio].
  ///
  /// - [bio] : description à afficher.
  const AppSignatureBio({super.key, required this.bio});

  /// Description à afficher.
  final String bio;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Text(
      bio,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: AppColors.onLighter),
    );
  }
}
