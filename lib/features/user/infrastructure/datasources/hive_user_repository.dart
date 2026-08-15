import 'package:bedbug/features/user/domain/repositories/user_repository.dart';
import 'package:bedbug/features/user/infrastructure/models/user_hive_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

/// Provider de la [Box] Hive des utilisateurs.
final hiveUserBoxProvider = Provider<Box<UserHiveModel>>((ref) => Hive.box<UserHiveModel>('users'));

/// Provider du [HiveUserRepository].
final userRepositoryProvider = Provider<UserRepository>((ref) => HiveUserRepository());

/// Implémentation de [UserRepository] utilisant Hive comme stockage local.
class HiveUserRepository implements UserRepository {}
