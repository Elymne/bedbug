import 'package:bedbug/features/content/domain/entities/content.dart';
import 'package:bedbug/features/content/domain/entities/text_content.dart';
import 'package:bedbug/features/content/domain/enums/content_origin.dart';
import 'package:bedbug/features/content/domain/repositories/content_repository.dart';
import 'package:bedbug/features/content/domain/usecases/recalculate_survival_scores_usecase.dart';
import 'package:bedbug/shared/domain/params.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fake [ContentRepository] gardant les contenus en mémoire, pour tester le
/// use case sans dépendre de Hive : seule la logique de calcul du score
/// nous intéresse ici, pas la persistance.
class _FakeContentRepository implements ContentRepository {
  _FakeContentRepository(List<Content> contents) : _contents = List.of(contents);

  final List<Content> _contents;

  /// Dernier appel à [updateMany], capturé pour vérifier ce que le use case
  /// a effectivement tenté de persister.
  List<Content>? lastUpdateManyCall;

  @override
  Future<List<Content>> getAll() async => List.of(_contents);

  @override
  Future<void> updateMany(List<Content> entities) async {
    lastUpdateManyCall = entities;
  }

  @override
  Future<Content> addOne(Content entity) => throw UnimplementedError();

  @override
  Future<void> addMany(List<Content> entities) => throw UnimplementedError();

  @override
  Future<Content> updateOne(Content entity) => throw UnimplementedError();

  @override
  Future<Content?> getUnique(String id) => throw UnimplementedError();

  @override
  Stream<List<Content>> watchAll() => throw UnimplementedError();

  @override
  Future<void> deleteOne(String id) => throw UnimplementedError();

  @override
  Future<void> deleteMany(List<String> ids) => throw UnimplementedError();

  @override
  Future<void> deleteAll() => throw UnimplementedError();

  @override
  Future<List<Content>> findMany(ContentRepositoryParams params) => throw UnimplementedError();

  @override
  Stream<List<Content>> watchMany(ContentRepositoryParams params) => throw UnimplementedError();
}

/// Construit un [TextContent] minimal pour les besoins du test, avec un
/// `survivalScore` de départ neutre pour bien observer le recalcul.
TextContent _buildContent({
  required String id,
  required ContentOrigin origin,
  required DateTime createdAt,
  int bounce = 0,
}) {
  return TextContent(
    id: id,
    createdAt: createdAt,
    updatedAt: createdAt,
    authorId: 'author',
    senderId: 'sender',
    origin: origin,
    broadcastScore: 0,
    survivalScore: 0,
    bounce: bounce,
    sizeInBytes: 10,
    title: 'Titre $id',
    body: 'Corps $id',
  );
}

double _survivalScoreOf(_FakeContentRepository repository, String id) {
  return repository.lastUpdateManyCall!.firstWhere((content) => content.id == id).survivalScore;
}

void main() {
  final now = DateTime(2026, 6, 15);

  test('ne modifie jamais le survivalScore des contenus owned, quel que soit leur âge', () async {
    final owned = _buildContent(id: 'owned', origin: ContentOrigin.owned, createdAt: now.subtract(const Duration(days: 3650)));
    final repository = _FakeContentRepository([owned]);
    final usecase = RecalculateSurvivalScoresUsecase(repository);

    final result = await usecase(const NoParams());

    expect(result.isSuccess, isTrue);
    expect(repository.lastUpdateManyCall, isNull, reason: 'aucun contenu owned ne doit déclencher de mise à jour');
  });

  test('le survivalScore reste toujours dans [0.0, 1.0]', () async {
    final contents = [
      _buildContent(id: 'ancient', origin: ContentOrigin.public, createdAt: now.subtract(const Duration(days: 3650))),
      _buildContent(id: 'fresh', origin: ContentOrigin.favorited, createdAt: now, bounce: 1000000),
    ];
    final repository = _FakeContentRepository(contents);
    final usecase = RecalculateSurvivalScoresUsecase(repository);

    await usecase(const NoParams());

    for (final content in repository.lastUpdateManyCall!) {
      expect(content.survivalScore, inInclusiveRange(0.0, 1.0));
    }
  });

  test('le survivalScore décroît strictement quand le contenu est plus vieux, pour une origin donnée', () async {
    final recent = _buildContent(id: 'recent', origin: ContentOrigin.public, createdAt: now.subtract(const Duration(days: 1)));
    final old = _buildContent(id: 'old', origin: ContentOrigin.public, createdAt: now.subtract(const Duration(days: 30)));
    final repository = _FakeContentRepository([recent, old]);
    final usecase = RecalculateSurvivalScoresUsecase(repository);

    await usecase(const NoParams());

    final recentScore = _survivalScoreOf(repository, 'recent');
    final oldScore = _survivalScoreOf(repository, 'old');
    expect(recentScore, greaterThan(oldScore));
  });

  test('à âge égal, favorited résiste au moins autant que subscribed, lui-même au moins autant que public', () async {
    final age = now.subtract(const Duration(days: 14));
    final contents = [
      _buildContent(id: 'favorited', origin: ContentOrigin.favorited, createdAt: age),
      _buildContent(id: 'subscribed', origin: ContentOrigin.subscribed, createdAt: age),
      _buildContent(id: 'public', origin: ContentOrigin.public, createdAt: age),
    ];
    final repository = _FakeContentRepository(contents);
    final usecase = RecalculateSurvivalScoresUsecase(repository);

    await usecase(const NoParams());

    final favoritedScore = _survivalScoreOf(repository, 'favorited');
    final subscribedScore = _survivalScoreOf(repository, 'subscribed');
    final publicScore = _survivalScoreOf(repository, 'public');
    expect(favoritedScore, greaterThanOrEqualTo(subscribedScore));
    expect(subscribedScore, greaterThanOrEqualTo(publicScore));
  });

  test('augmenter le bounce ne peut jamais faire baisser le survivalScore', () async {
    final lowBounce = _buildContent(
      id: 'lowBounce',
      origin: ContentOrigin.public,
      createdAt: now.subtract(const Duration(days: 10)),
    );
    final highBounce = _buildContent(
      id: 'highBounce',
      origin: ContentOrigin.public,
      createdAt: now.subtract(const Duration(days: 10)),
      bounce: 50,
    );
    final repository = _FakeContentRepository([lowBounce, highBounce]);
    final usecase = RecalculateSurvivalScoresUsecase(repository);

    await usecase(const NoParams());

    final lowBounceScore = _survivalScoreOf(repository, 'lowBounce');
    final highBounceScore = _survivalScoreOf(repository, 'highBounce');
    expect(highBounceScore, greaterThanOrEqualTo(lowBounceScore));
  });
}
