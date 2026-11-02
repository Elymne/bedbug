import 'package:bedbug/gateways/exchange/exchange_codec/exchange_codec.config.dart';

/// Nombre de contenus de l'offre choisis par priorité de diffusion, le reste étant tiré au hasard.
///
/// Une offre uniquement faite des contenus les plus prioritaires proposerait toujours les mêmes : au-delà de
/// [maxOfferedContents] contenus, les autres ne circuleraient plus du tout.
const int priorityOfferedContents = 35;
