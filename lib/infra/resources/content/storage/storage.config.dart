import 'package:bedbug/infra/resources/content/storage/storage.value_object.dart';

/// Nombre d'octets dans un mégaoctet, l'unité des limites de stockage présentées à l'utilisateur.
const int bytesPerMegabyte = 1024 * 1024;

/// Poids maximal par défaut de la base, en octets (100 Mo).
///
/// La limite porte sur le poids réel de la base (contenus, réactions, signatures, index) : un contenu pesant 128 Ko
/// au maximum, 100 Mo en gardent déjà plusieurs milliers, sans peser sur l'espace du téléphone.
const int defaultMaxStorageSizeInBytes = 100 * bytesPerMegabyte;

/// Limites proposées d'office à l'utilisateur, en octets.
const List<int> storageLimitPresetsInBytes = [
  50 * bytesPerMegabyte,
  defaultMaxStorageSizeInBytes,
  250 * bytesPerMegabyte,
];

/// Plus petite limite qu'un utilisateur peut définir, en mégaoctets.
const int minStorageLimitInMegabytes = 1;

/// Plus grande limite qu'un utilisateur peut définir, en mégaoctets.
const int maxStorageLimitInMegabytes = 1000;

/// Configuration d'un appareil qui n'a encore rien réglé : limite et stratégie par défaut.
const Storage defaultStorage = Storage(maxSizeInBytes: defaultMaxStorageSizeInBytes);
