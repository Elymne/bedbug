import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Page de création de contenu.
class CreateScreen extends ConsumerWidget {
  /// Crée un [CreateScreen].
  const CreateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(body: Center(child: Text('Create')));
  }
}
