import 'package:bedbug/resources/content/comment/comment.entity.dart';

/// Longueur maximale, en caractères, du corps d'un [Comment].
///
/// Plus long qu'une bulle de réaction (un commentaire développe un avis),
/// mais borné : il voyage de pair à pair et doit rester sous ~2 Ko.
const int maxCommentLength = 500;

/// Nombre maximal de commentaires conservés par contenu.
///
/// Comme pour les réactions, rien n'empêche un pair de fabriquer des
/// commentaires en masse : au-delà, les plus anciens sont écartés, ce qui
/// plafonne le poids des commentaires d'un contenu à ~200 Ko.
const int maxCommentsPerContent = 100;

/// Nom de la box Hive des commentaires.
const String commentBoxName = 'comments';
