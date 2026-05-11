import 'package:bedbug/features/content/infrastructure/models/comment_hive_model.dart';
import 'package:bedbug/features/content/infrastructure/models/content_hive_model.dart';
import 'package:bedbug/features/user/infrastructure/models/user_hive_model.dart';

/// Registre centralisé des typeId Hive utilisés dans l'application.
///
/// Chaque valeur doit être unique. Ne jamais réutiliser un typeId supprimé.
class HiveTypeIds {
  HiveTypeIds._();

  /// TypeId de [UserHiveModel].
  static const int user = 0;

  /// TypeId de [ContentHiveModel].
  static const int content = 1;

  /// TypeId de [CommentHiveModel].
  static const int comment = 2;
}
