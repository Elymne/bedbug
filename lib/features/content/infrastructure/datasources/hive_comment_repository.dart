import 'package:bedbug/features/content/domain/repositories/comment_repository.dart';
import 'package:bedbug/features/content/infrastructure/models/comment_hive_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

/// Provider de la [Box] Hive des commentaires.
final hiveCommentBoxProvider = Provider<Box<CommentHiveModel>>((ref) => Hive.box<CommentHiveModel>('comments'));

/// Provider du [HiveCommentRepository].
final commentRepositoryProvider = Provider<CommentRepository>((ref) => HiveCommentRepository());

/// Implémentation de [CommentRepository] utilisant Hive comme stockage local.
class HiveCommentRepository implements CommentRepository {}
