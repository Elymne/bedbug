/// Version du format d'échange. À incrémenter à chaque changement incompatible.
const int exchangeFormatVersion = 1;

/// Taille maximale d'un message une fois décompressé, en octets.
///
/// Un message compressé de quelques kilo-octets peut se décompresser en plusieurs giga-octets (« zip bomb ») :
/// la décompression s'arrête net au-delà de cette taille, bien au-dessus d'un lot légitime.
const int maxDecompressedExchangeBytes = 4 * 1024 * 1024;
