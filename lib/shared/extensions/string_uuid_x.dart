import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Extension de génération d'UUID sur [String].
extension UuidX on String {
  /// Génère un UUID v4 aléatoire.
  static String generate() => _uuid.v4();
}
