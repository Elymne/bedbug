import 'dart:math';

import 'package:bedbug/core/domain/cursor_page.dart';
import 'package:bedbug/infra/resources/content/content/content.entity.dart';
import 'package:bedbug/infra/resources/content/content/content.entity.detailed.dart';
import 'package:bedbug/infra/resources/content/content/content.entity.summary.dart';
import 'package:bedbug/infra/resources/content/content/content_origin.enum.dart';
import 'package:bedbug/infra/resources/content/content/content_score.entity.summary.dart';
import 'package:bedbug/infra/resources/content/content/content_url.entity.summary.dart';

/// Contrat du repository gérant les [Content].
///
/// Les réactions, les commentaires et la trace d'affichage d'un contenu disparaissent avec lui : supprimer un contenu
/// suffit à tout nettoyer.
abstract class ContentRepository {
  /// Persiste un nouveau contenu [entity], en notant la date de son enregistrement sur ce téléphone.
  Future<Content> addOne(Content entity);

  /// Retourne le résumé des scores de chaque contenu reçu (pas ceux de l'utilisateur), sans ordre garanti.
  ///
  /// Les contenus de l'utilisateur gardent des scores fixes : seuls les contenus reçus sont recalculés.
  Future<List<ContentScoreSummary>> getReceivedScoreSummaries();

  /// Remplace le `broadcastScore` des contenus de [scoresById], et lui seul, en une seule opération atomique.
  ///
  /// Un identifiant absent (contenu supprimé entre la lecture et l'écriture) est ignoré.
  ///
  /// - [scoresById] : nouveau score de diffusion, par identifiant de contenu.
  Future<void> updateBroadcastScores(Map<String, double> scoresById);

  /// Remplace le `survivalScore` des contenus de [scoresById], et lui seul, en une seule opération atomique.
  ///
  /// Un identifiant absent (contenu supprimé entre la lecture et l'écriture) est ignoré.
  ///
  /// - [scoresById] : nouveau score de survie, par identifiant de contenu.
  Future<void> updateSurvivalScores(Map<String, double> scoresById);

  /// Remplace le `displayScore` des contenus de [scoresById], et lui seul, en une seule opération atomique.
  ///
  /// Un identifiant absent (contenu supprimé entre la lecture et l'écriture) est ignoré.
  ///
  /// - [scoresById] : nouveau score d'affichage, par identifiant de contenu.
  Future<void> updateDisplayScores(Map<String, double> scoresById);

  /// Retourne les adresses de chaque contenu reçu (pas ceux de l'utilisateur) qui pointe vers au moins un média ou un
  /// lien, sans ordre garanti.
  Future<List<ContentUrlSummary>> getReceivedUrlSummaries();

  /// Supprime l'intégralité des contenus stockés, avec leurs réactions, commentaires et traces d'affichage.
  Future<void> deleteAll();

  /// Retourne une page du fil d'accueil, figé à [feedStartedAt].
  ///
  /// Les contenus non vus passent en tête (ni à l'utilisateur, ni vus avant [feedStartedAt]), puis les autres ; dans
  /// chaque groupe, du plus fort `displayScore` au plus faible. Seuls les contenus enregistrés au plus tard à
  /// [feedStartedAt] en font partie, et [ContentDetailed.isViewed] ne compte que les vues antérieures : marquer un
  /// contenu comme vu ou en recevoir un pendant le défilement ne déplace rien d'une page à l'autre.
  ///
  /// - [feedStartedAt] : début de la session de lecture.
  /// - [after] : curseur de la page précédente, `null` pour la première page.
  /// - [limit] : nombre maximal de contenus de la page.
  Future<CursorPage<ContentDetailed>> getHomeFeedPage({
    required DateTime feedStartedAt,
    required String? after,
    required int limit,
  });

  /// Retourne une page des contenus dont le titre ou le flair contient [query], insensible à la casse, du plus fort
  /// `displayScore` au plus faible.
  ///
  /// - [query] : texte recherché, non vide.
  /// - [after] : curseur de la page précédente, `null` pour la première page.
  /// - [limit] : nombre maximal de contenus de la page.
  Future<CursorPage<ContentDetailed>> getPageMatchingTitleOrFlair(
    String query, {
    required String? after,
    required int limit,
  });

  /// Retourne une page des contenus rattachés exactement au flair [flair] (déjà normalisé), du plus fort
  /// `displayScore` au plus faible.
  ///
  /// - [flair] : flair recherché, normalisé.
  /// - [after] : curseur de la page précédente, `null` pour la première page.
  /// - [limit] : nombre maximal de contenus de la page.
  Future<CursorPage<ContentDetailed>> getPageByFlair(String flair, {required String? after, required int limit});

  /// Retourne une page des contenus dont la signature fait partie de [signatureIds], du plus fort `displayScore` au
  /// plus faible.
  ///
  /// - [signatureIds] : signatures dont on veut les contenus.
  /// - [after] : curseur de la page précédente, `null` pour la première page.
  /// - [limit] : nombre maximal de contenus de la page.
  Future<CursorPage<ContentDetailed>> getPageBySignatures(
    Set<String> signatureIds, {
    required String? after,
    required int limit,
  });

  /// Retourne tous les contenus de provenance [origin], détaillés, du plus récent (`createdAt`) au plus ancien.
  Future<List<ContentDetailed>> getAllDetailedByOrigin(ContentOrigin origin);

  /// Retourne le contenu d'identifiant [id], ou `null` s'il n'existe pas.
  Future<Content?> getById(String id);

  /// Retourne les contenus détaillés dont l'identifiant fait partie de [ids], dans l'ordre de [ids]. Les absents sont
  /// ignorés.
  Future<List<ContentDetailed>> getDetailedByIds(List<String> ids);

  /// Retourne, parmi [ids], les identifiants des contenus présents.
  Future<Set<String>> getExistingIds(Set<String> ids);

  /// Retourne le résumé des [limit] contenus de plus fort `broadcastScore`, du plus fort au plus faible.
  Future<List<ContentSummary>> getTopSummariesByBroadcastScore(int limit);

  /// Retourne le résumé d'au plus [limit] contenus tirés au hasard, en dehors de [excludedIds].
  ///
  /// - [limit] : nombre maximal de contenus.
  /// - [excludedIds] : contenus à ne pas tirer.
  /// - [random] : générateur du tirage, injecté pour qu'un même générateur donne toujours le même tirage.
  Future<List<ContentSummary>> getRandomSummariesExcluding(int limit, Set<String> excludedIds, Random random);

  /// Retourne le résumé des contenus présents parmi [ids], sans ordre garanti.
  Future<List<ContentSummary>> getSummariesByIds(Set<String> ids);

  /// Retourne le résumé d'au plus [limit] contenus reçus (pas ceux de l'utilisateur), dans leur ordre de suppression :
  /// du plus faible `survivalScore` au plus fort, le plus ancien d'abord à score égal.
  Future<List<ContentSummary>> getReceivedSummariesBySurvival(int limit);

  /// Supprime les contenus dont l'identifiant fait partie de [ids], et les mémorise comme déjà vus à [seenAt].
  ///
  /// Les deux écritures sont atomiques : un contenu supprimé sans être mémorisé serait retéléchargé au prochain
  /// échange. Ses réactions, commentaires et trace d'affichage partent avec lui.
  ///
  /// - [ids] : contenus à supprimer.
  /// - [seenAt] : date de la suppression, point de départ de la rétention de la trace.
  Future<void> deleteManyAsSeen(List<String> ids, DateTime seenAt);

  /// Retourne le flair de chaque contenu dont le flair commence par [prefix] (déjà normalisé), un par contenu.
  ///
  /// Un même flair revient autant de fois que de contenus le portent : le regroupement et le classement reviennent
  /// à l'appelant.
  Future<List<String>> getFlairsStartingWith(String prefix);
}
