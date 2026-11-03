/// Poids maximal cumulé des contenus demandés en un échange, en octets, avant compression.
///
/// Mesuré en BLE (phase 0) : environ 30 Ko/s. Le texte se compresse environ trois fois : 200 Ko de contenus
/// passent en deux à trois secondes, ce que dure une rencontre brève.
const int defaultMaxRequestedBytes = 200 * 1024;

/// Poids minimal d'un contenu dans le tirage, quelle que soit sa place dans l'offre.
///
/// Le premier contenu de l'offre pèse `1`, le dernier ce plancher : il garde une chance sur cinq d'être tiré
/// face au premier. Les contenus les plus récents sont favorisés sans que les autres soient condamnés.
const double selectionWeightFloor = 0.2;
