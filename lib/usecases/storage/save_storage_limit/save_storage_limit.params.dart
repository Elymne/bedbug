import 'package:bedbug/core/domain/params.dart';
import 'package:bedbug/usecases/storage/save_storage_limit/save_storage_limit.usecase.dart';

/// Paramètres du [SaveStorageLimitUsecase].
class SaveStorageLimitParams extends Params {
  /// Crée des [SaveStorageLimitParams].
  ///
  /// - [maxSizeInBytes] : nouvelle limite, en octets.
  const SaveStorageLimitParams({required this.maxSizeInBytes});

  /// Nouvelle limite, en octets.
  final int maxSizeInBytes;
}
