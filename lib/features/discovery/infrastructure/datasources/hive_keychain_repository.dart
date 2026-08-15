import 'package:bedbug/features/discovery/domain/repositories/keychain_repository.dart';
import 'package:bedbug/features/discovery/infrastructure/models/keychain_hive_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

/// Provider de la [Box] Hive des portefeuilles de clés.
final hiveKeychainBoxProvider = Provider<Box<KeychainHiveModel>>((ref) => Hive.box<KeychainHiveModel>('keychains'));

/// Provider du [HiveKeychainRepository].
final keychainRepositoryProvider = Provider<KeychainRepository>((ref) => HiveKeychainRepository());

/// Implémentation de [KeychainRepository] utilisant Hive comme stockage local.
class HiveKeychainRepository implements KeychainRepository {}
