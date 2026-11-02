import 'dart:io';

import 'package:bedbug/resources/content/viewed_content/viewed_content.config.dart';
import 'package:bedbug/resources/content/viewed_content/viewed_content.model.hive.dart';
import 'package:bedbug/resources/hive.initializer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import '../helpers/hive_test_helper.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await openTestHive();
  });

  tearDown(() async {
    await closeTestHive(tempDir);
  });

  test('recopie les contenus vus de l\'ancienne box puis la supprime', () async {
    final viewedAt = DateTime(2026, 10, 31, 12);
    final legacyBox = await Hive.openBox<int>(legacyViewedContentBoxName);
    await legacyBox.putAll({'content-a': viewedAt.millisecondsSinceEpoch, 'content-b': 0});

    await migrateLegacyViewedContents();

    final box = Hive.box<ViewedContentHiveModel>(viewedContentBoxName);
    expect(box.keys.toSet(), {'content-a', 'content-b'});
    expect(box.get('content-a')!.toEntity().createdAt, viewedAt);
    expect(await Hive.boxExists(legacyViewedContentBoxName), isFalse);
  });

  test('ne fait rien sans ancienne box', () async {
    await migrateLegacyViewedContents();

    expect(Hive.box<ViewedContentHiveModel>(viewedContentBoxName).isEmpty, isTrue);
  });
}
