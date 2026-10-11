import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:study_recorder/core/errors/failure.dart';
import 'package:study_recorder/core/errors/result.dart';
import 'package:study_recorder/data/folder/folder_model.dart';

import '../repository_test_helpers.dart';

void main() {
  late DataTestEnv env;

  setUp(() async => env = await DataTestEnv.create());
  tearDown(() => env.dispose());

  Future<List<String>> topLevelIds() async {
    final result = await env.folders.watchFolders(null).first;
    return (result as Ok<List<FolderModel>>).value.map((f) => f.id).toList();
  }

  group('createFolder / watchFolders', () {
    test('top-level and child folders are separated', () async {
      await env.addFolder('physics');
      await env.addFolder('mechanics', parentId: 'physics');

      expect(await topLevelIds(), ['physics']);
      final children = await env.folders.watchFolders('physics').first;
      expect((children as Ok<List<FolderModel>>).value.single.id, 'mechanics');
    });

    test('orders by created time when nothing was rearranged', () async {
      await env.addFolder('b', createdAt: 20);
      await env.addFolder('a', createdAt: 10);
      await env.addFolder('c', createdAt: 30);

      expect(await topLevelIds(), ['a', 'b', 'c']);
    });

    test('sort index comes first, folders without one come last', () async {
      await env.addFolder('old', createdAt: 1);
      await env.addFolder('x', createdAt: 2, sortIndex: 1);
      await env.addFolder('y', createdAt: 3, sortIndex: 0);

      expect(await topLevelIds(), ['y', 'x', 'old']);
    });

    test('emits again when a folder is added', () async {
      final emissions = <List<String>>[];
      final sub = env.folders.watchFolders(null).listen((r) {
        emissions.add(
          (r as Ok<List<FolderModel>>).value.map((f) => f.id).toList(),
        );
      });

      await pumpEventQueue();
      await env.addFolder('one');
      await pumpEventQueue();
      await sub.cancel();

      expect(emissions.first, isEmpty);
      expect(emissions.last, ['one']);
    });

    test('duplicate id returns Err(StorageFailure)', () async {
      await env.addFolder('dup');
      final result = await env.folders.createFolder(
        FolderModel(
          id: 'dup',
          parentId: null,
          name: 'again',
          createdAt: DateTime.now(),
        ),
      );

      expect(result, isA<Err<void>>());
      expect((result as Err).failure, isA<StorageFailure>());
    });

    test('unknown parent returns Err (foreign key is enforced)', () async {
      final result = await env.folders.createFolder(
        FolderModel(
          id: 'orphan',
          parentId: 'missing',
          name: 'orphan',
          createdAt: DateTime.now(),
        ),
      );

      expect(result, isA<Err<void>>());
    });
  });

  group('renameFolder', () {
    test('changes the name', () async {
      await env.addFolder('f');
      expectOk(await env.folders.renameFolder('f', 'Renamed'));

      final folder = await env.folders.getFolder('f');
      expect((folder as Ok<FolderModel?>).value!.name, 'Renamed');
    });

    test('unknown id returns Err', () async {
      final result = await env.folders.renameFolder('nope', 'x');
      expect(result, isA<Err<void>>());
    });
  });

  group('getFolder', () {
    test('returns Ok(null) when missing', () async {
      final result = await env.folders.getFolder('nope');
      expect((result as Ok<FolderModel?>).value, isNull);
    });
  });

  group('deleteFolder', () {
    test('removes subfolders, recordings and their files', () async {
      await env.addFolder('physics');
      await env.addFolder('mechanics', parentId: 'physics');
      await env.addFolder('other');
      final r1 = await env.addRecording('r1', 'physics');
      final r2 = await env.addRecording('r2', 'mechanics');
      final keep = await env.addRecording('keep', 'other');

      expectOk(await env.folders.deleteFolder('physics'));

      expect(await topLevelIds(), ['other']);
      expect((await env.recordings.getRecording('r1') as Ok).value, isNull);
      expect((await env.recordings.getRecording('r2') as Ok).value, isNull);
      expect(File(env.recordings.absolutePath(r1)).existsSync(), isFalse);
      expect(File(env.recordings.absolutePath(r2)).existsSync(), isFalse);
      expect(File(env.recordings.absolutePath(keep)).existsSync(), isTrue);
    });

    test('unknown id returns Err', () async {
      final result = await env.folders.deleteFolder('nope');
      expect(result, isA<Err<void>>());
    });
  });

  group('updateSortOrder', () {
    test('rearranges the folders', () async {
      await env.addFolder('parent');
      await env.addFolder('a', parentId: 'parent', createdAt: 1);
      await env.addFolder('b', parentId: 'parent', createdAt: 2);

      expectOk(await env.folders.updateSortOrder({'b': 0, 'a': 1}));

      final result = await env.folders.watchFolders('parent').first;
      expect((result as Ok<List<FolderModel>>).value.map((f) => f.id), [
        'b',
        'a',
      ]);
    });
  });

  group('watchFolderCounts', () {
    test(
      'counts direct subfolders, and all recordings including nested ones',
      () async {
        await env.addFolder('physics');
        await env.addFolder('mechanics', parentId: 'physics');
        await env.addFolder('optics', parentId: 'physics');
        await env.addRecording('r1', 'physics');
        await env.addRecording('r2', 'mechanics');

        final result = await env.folders.watchFolderCounts().first;
        final counts = (result as Ok<Map<String, FolderCounts>>).value;

        expect(counts['physics']!.subfolders, 2);
        expect(counts['physics']!.recordings, 2); // r1 and r2 in mechanics
        expect(counts['mechanics']!.subfolders, 0);
        expect(counts['mechanics']!.recordings, 1);
        expect(counts['optics']!.recordings, 0);
      },
    );

    test('emits again when a recording is added', () async {
      await env.addFolder('f');
      final emissions = <int>[];
      final sub = env.folders.watchFolderCounts().listen((r) {
        emissions.add(
          (r as Ok<Map<String, FolderCounts>>).value['f']!.recordings,
        );
      });

      await pumpEventQueue();
      await env.addRecording('r1', 'f');
      await pumpEventQueue();
      await sub.cancel();

      expect(emissions.first, 0);
      expect(emissions.last, 1);
    });
  });

  group('storage errors', () {
    test('one-shot calls return Err instead of throwing', () async {
      await env.db.customStatement('DROP TABLE recording');
      await env.db.customStatement('DROP TABLE folder');

      expect(await env.folders.getFolder('x'), isA<Err<FolderModel?>>());
      expect(await env.folders.renameFolder('x', 'y'), isA<Err<void>>());
      expect(await env.folders.deleteFolder('x'), isA<Err<void>>());
    });
  });
}
