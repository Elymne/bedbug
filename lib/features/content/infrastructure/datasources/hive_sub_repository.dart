import 'package:bedbug/features/content/domain/repositories/sub_repository.dart';
import 'package:bedbug/features/content/infrastructure/models/sub_hive_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

/// Provider de la [Box] Hive des subs.
final hiveSubBoxProvider = Provider<Box<SubHiveModel>>((ref) => Hive.box<SubHiveModel>('subs'));

/// Provider du [HiveSubRepository].
final subRepositoryProvider = Provider<SubRepository>((ref) => HiveSubRepository());

/// Implémentation de [SubRepository] utilisant Hive comme stockage local.
class HiveSubRepository implements SubRepository {}
