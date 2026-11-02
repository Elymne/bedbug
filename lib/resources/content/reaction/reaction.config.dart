import 'package:bedbug/resources/content/reaction/reaction.entity.dart';

/// Longueur maximale, en caractères, de la bulle de texte d'une [Reaction].
///
/// Une bulle reste une réaction (« trop bien », une courte remarque), pas un
/// commentaire : 250 caractères laissent la place d'une phrase tout en gardant
/// une réaction sous ~1 Ko, ce qui compte pour un transfert de pair à pair.
const int maxReactionBubbleLength = 250;

/// Nombre maximal de réactions conservées par contenu.
///
/// Sans identité vérifiable, rien n'empêche un pair de fabriquer des milliers
/// de réactions sous des auteurs inventés : on ne peut que borner leur
/// nombre. Au-delà, les plus anciennes sont écartées, ce qui plafonne le
/// poids des réactions d'un contenu à ~200 Ko.
const int maxReactionsPerContent = 200;
