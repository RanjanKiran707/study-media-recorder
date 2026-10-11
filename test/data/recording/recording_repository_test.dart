import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:study_recorder/core/errors/failure.dart';
import 'package:study_recorder/core/errors/result.dart';
import 'package:study_recorder/data/recording/recording_model.dart';

import '../repository_test_helpers.dart';

void main() {
  late DataTestEnv env;

  setUp(() async {
    env = await DataTestEnv.create();
    await env.addFolder('f1');
    await env.addFolder('f2');
  });
  tearDown(() => env.dispose());

  Future<List<String>> idsIn(String folderId) async {
    final result = await env.recordings.watchRecordings(folderId).first;
    return (result as Ok<List<RecordingModel>>).value.map((r) => r.id).toList();
  }

  group('addRecording', () {
    test('moves the file into the recordings directory', () async {
      final source = await env.cacheFile('take.mp4');

      final result = await env.recordings.addRecording(
        id: 'r1',
        folderId: 'f1',
        title: 'Newton',
        type: RecordingType.video,
        sourcePath: source,
        durationMs: 120000,
        createdAt: DateTime.fromMillisecondsSinceEpoch(5),
      );

      final saved = (result as Ok<RecordingModel>).value;
      expect(saved.filePath, 'r1.mp4');
      expect(saved.type, RecordingType.video);
      expect(saved.sortIndex, isNull);
      expect(File(env.recordings.absolutePath(saved)).existsSync(), isTrue);
      expect(File(source).existsSync(), isFalse);
      expect(await idsIn('f1'), ['r1']);
    });

    test('missing source file returns Err and saves nothing', () async {
      final result = await env.recordings.addRecording(
        id: 'r1',
        folderId: 'f1',
        title: 'x',
        type: RecordingType.audio,
        sourcePath: '${env.cacheDir.path}/does_not_exist.m4a',
        durationMs: 1,
        createdAt: DateTime.now(),
      );

      expect(result, isA<Err<RecordingModel>>());
      expect((result as Err).failure, isA<StorageFailure>());
      expect(await idsIn('f1'), isEmpty);
    });

    test('unknown folder returns Err and removes the moved file', () async {
      final source = await env.cacheFile('take.m4a');

      final result = await env.recordings.addRecording(
        id: 'r1',
        folderId: 'missing',
        title: 'x',
        type: RecordingType.audio,
        sourcePath: source,
        durationMs: 1,
        createdAt: DateTime.now(),
      );

      expect(result, isA<Err<RecordingModel>>());
      expect(File('${env.mediaDir.path}/r1.m4a').existsSync(), isFalse);
    });
  });

  group('watchRecordings', () {
    test('orders by created time, then by sort index when set', () async {
      await env.addRecording('b', 'f1', createdAt: 20);
      await env.addRecording('a', 'f1', createdAt: 10);
      await env.addRecording('c', 'f1', createdAt: 30);
      expect(await idsIn('f1'), ['a', 'b', 'c']);

      expectOk(await env.recordings.updateSortOrder({'c': 0, 'a': 1}));
      expect(await idsIn('f1'), ['c', 'a', 'b']);
    });

    test('only returns the recordings of that folder', () async {
      await env.addRecording('a', 'f1');
      await env.addRecording('b', 'f2');

      expect(await idsIn('f1'), ['a']);
      expect(await idsIn('f2'), ['b']);
    });
  });

  group('renameRecording', () {
    test('changes the title', () async {
      await env.addRecording('r1', 'f1');
      expectOk(await env.recordings.renameRecording('r1', 'New title'));

      final result = await env.recordings.getRecording('r1');
      expect((result as Ok<RecordingModel?>).value!.title, 'New title');
    });

    test('unknown id returns Err', () async {
      expect(
        await env.recordings.renameRecording('nope', 'x'),
        isA<Err<void>>(),
      );
    });
  });

  group('moveRecording', () {
    test('changes the folder only and clears the sort index', () async {
      await env.addRecording('r1', 'f1');
      await env.addRecording('r2', 'f2', createdAt: 1);
      expectOk(await env.recordings.updateSortOrder({'r1': 0}));

      expectOk(await env.recordings.moveRecording('r1', 'f2'));

      final moved =
          (await env.recordings.getRecording('r1') as Ok).value
              as RecordingModel;
      expect(moved.folderId, 'f2');
      expect(moved.filePath, 'r1.m4a');
      expect(moved.sortIndex, isNull);
      expect(await idsIn('f1'), isEmpty);
      // Not rearranged, so it sits by created time (r1 is older than r2).
      expect(await idsIn('f2'), ['r1', 'r2']);
    });

    test('unknown folder returns Err', () async {
      await env.addRecording('r1', 'f1');
      expect(
        await env.recordings.moveRecording('r1', 'missing'),
        isA<Err<void>>(),
      );
      expect(await idsIn('f1'), ['r1']);
    });
  });

  group('deleteRecording', () {
    test('removes the row and the file', () async {
      final saved = await env.addRecording('r1', 'f1');

      expectOk(await env.recordings.deleteRecording('r1'));

      expect(await idsIn('f1'), isEmpty);
      expect(File(env.recordings.absolutePath(saved)).existsSync(), isFalse);
    });

    test('still succeeds when the file is already gone', () async {
      final saved = await env.addRecording('r1', 'f1');
      File(env.recordings.absolutePath(saved)).deleteSync();

      expectOk(await env.recordings.deleteRecording('r1'));
    });

    test('unknown id returns Err', () async {
      expect(await env.recordings.deleteRecording('nope'), isA<Err<void>>());
    });
  });

  group('storage errors', () {
    test('one-shot calls return Err instead of throwing', () async {
      await env.db.customStatement('DROP TABLE recording');

      expect(await env.recordings.getRecording('x'), isA<Err>());
      expect(await env.recordings.renameRecording('x', 'y'), isA<Err<void>>());
      expect(await env.recordings.deleteRecording('x'), isA<Err<void>>());
      expect(await env.recordings.updateSortOrder({'x': 0}), isA<Err<void>>());
    });
  });
}
