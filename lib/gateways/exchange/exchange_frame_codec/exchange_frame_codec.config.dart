import 'package:bedbug/gateways/exchange/exchange_frame_codec/exchange_frame_type.enum.dart';

/// Taille maximale de la charge utile d'une trame de contrôle ou de négociation ([ExchangeFrameType.offer] et
/// [ExchangeFrameType.request]), en octets.
///
/// Une offre compressée pèse quelques kilo-octets : cette marge n'est jamais atteinte par un pair honnête.
const int maxExchangeNegotiationBytes = 64 * 1024;

/// Taille maximale d'un lot sur le fil, en octets, une fois compressé.
///
/// Le budget de 200 Ko de contenus se compresse bien en dessous, et 1 Mo laisse la place aux réactions. Au-delà,
/// le transfert ne tiendrait pas dans une rencontre, et la trame serait une façon de saturer la mémoire du pair.
const int maxExchangeDataBytes = 1024 * 1024;
