import 'package:bedbug/application/screens/create/create_form/create_form.widget.dart';
import 'package:bedbug/application/screens/create/create_publishing/create_publishing.widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Page de création de contenu.
///
/// Page statique : le formulaire, et par-dessus la page de chargement affichée pendant la publication. Le formulaire
/// reste intact derrière elle, pour être retrouvé tel quel en cas d'échec.
class CreateScreen extends ConsumerWidget {
  /// Crée un [CreateScreen].
  const CreateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Stack(
      children: [
        CreateForm(),
        Positioned.fill(child: CreatePublishing()),
      ],
    );
  }
}
