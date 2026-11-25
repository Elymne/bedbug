import 'package:bedbug/infra/resources/data.exception.dart';
import 'package:bedbug/infra/resources/datasource.exception.dart';

/// Exécute une opération sur la base et traduit ses échecs en exceptions de la couche resources.
///
/// Une erreur de drift ou de SQLite peut prendre plusieurs formes (`SqliteException` sur la connexion,
/// `DriftRemoteException` quand la base tourne dans un isolate, `DriftWrappedException`, `CouldNotRollBackException`) :
/// les use cases ne doivent connaître que [DatasourceException]. Les [DataException] levées par les mappers, et les
/// [DatasourceException] déjà levées par le repository, passent telles quelles.
///
/// [source] : nom du repository, repris dans l'exception.
/// [action] : opération à exécuter sur la base.
Future<T> guardDrift<T>(String source, Future<T> Function() action) async {
  try {
    return await action();
  } on DataException {
    rethrow;
  } on DatasourceException {
    rethrow;
  } on Exception catch (error) {
    throw DatasourceException(source, error);
  }
}
