import 'package:flutter_test/flutter_test.dart';
import 'package:study_recorder/core/errors/failure.dart';
import 'package:study_recorder/core/errors/result.dart';
import 'package:study_recorder/data/recording/recording_model.dart';
import 'package:study_recorder/domain/use_cases/business/delete_recording/delete_recording_usecase.dart';
import 'package:study_recorder/domain/use_cases/business/move_recording/move_recording_usecase.dart';
import 'package:study_recorder/domain/use_cases/business/rename_recording/rename_recording_usecase.dart';
import 'package:study_recorder/domain/use_cases/business/save_recording/save_recording_argument_model.dart';
import 'package:study_recorder/domain/use_cases/business/save_recording/save_recording_usecase.dart';

import '../fakes/fake_folder_repository.dart';
import '../fakes/fake_recording_repository.dart';
import '../fakes/test_models.dart';

void main() {
  late FakeFolderRepository folders;
  late FakeRecordingRepository recordings;

  setUp(() {
    folders = FakeFolderRepository()
      ..folders.addAll([folderOf('f1'), folderOf('f2')]);
    recordings = FakeRecordingRepository();
  });

  group('SaveRecordingUsecase', () {
    final fixedNow = DateTime(2026, 1, 1);

    SaveRecordingArgumentModel args({
      String title = 'Newton',
      String folderId = 'f1',
      int durationMs = 90000,
    }) {
      return SaveRecordingArgumentModel(
        recordingId: 'r1',
        folderId: folderId,
        title: title,
        type: RecordingType.video,
        sourcePath: '/cache/take.mp4',
        durationMs: durationMs,
      );
    }

    test(
      'saves into the folder with a trimmed title and current time',
      () async {
        final usecase = SaveRecordingUsecase(
          recordings,
          folders,
          now: () => fixedNow,
        );

        final result = await usecase(args(title: ' Newton '));

        expect(result, isA<Ok<void>>());
        final saved = recordings.added.single;
        expect(saved.id, 'r1');
        expect(saved.folderId, 'f1');
        expect(saved.title, 'Newton');
        expect(saved.type, RecordingType.video);
        expect(saved.durationMs, 90000);
        expect(saved.createdAt, fixedNow);
      },
    );

    test('blank title is rejected', () async {
      final result = await SaveRecordingUsecase(recordings, folders)(
        args(title: ' '),
      );

      expect((result as Err).failure.message, 'title_required');
      expect(recordings.added, isEmpty);
    });

    test('zero duration is rejected', () async {
      final result = await SaveRecordingUsecase(recordings, folders)(
        args(durationMs: 0),
      );

      expect((result as Err).failure.message, 'duration_invalid');
      expect(recordings.added, isEmpty);
    });

    test('unknown folder is rejected', () async {
      final result = await SaveRecordingUsecase(recordings, folders)(
        args(folderId: 'missing'),
      );

      expect((result as Err).failure.message, 'folder_not_found');
      expect(recordings.added, isEmpty);
    });

    test('passes a repository failure on', () async {
      recordings.failure = const StorageFailure('disk');

      final result = await SaveRecordingUsecase(recordings, folders)(args());

      expect((result as Err).failure, isA<StorageFailure>());
    });
  });

  group('RenameRecordingUsecase', () {
    test('saves the trimmed title', () async {
      final result = await RenameRecordingUsecase(recordings)('r1', ' New ');

      expect(result, isA<Ok<void>>());
      expect(recordings.renamed, {'r1': 'New'});
    });

    test('blank title is rejected', () async {
      final result = await RenameRecordingUsecase(recordings)('r1', '');

      expect((result as Err).failure.message, 'title_required');
      expect(recordings.renamed, isEmpty);
    });
  });

  group('MoveRecordingUsecase', () {
    setUp(() => recordings.recordings.add(recordingOf('r1', 'f1')));

    test('moves to another folder', () async {
      final result = await MoveRecordingUsecase(recordings, folders)(
        'r1',
        'f2',
      );

      expect(result, isA<Ok<void>>());
      expect(recordings.moved, {'r1': 'f2'});
    });

    test('the folder it is already in is rejected', () async {
      final result = await MoveRecordingUsecase(recordings, folders)(
        'r1',
        'f1',
      );

      expect((result as Err).failure.message, 'same_folder');
      expect(recordings.moved, isEmpty);
    });

    test('unknown destination is rejected', () async {
      final result = await MoveRecordingUsecase(recordings, folders)(
        'r1',
        'missing',
      );

      expect((result as Err).failure.message, 'folder_not_found');
      expect(recordings.moved, isEmpty);
    });

    test('unknown recording is rejected', () async {
      final result = await MoveRecordingUsecase(recordings, folders)(
        'missing',
        'f2',
      );

      expect((result as Err).failure.message, 'recording_not_found');
      expect(recordings.moved, isEmpty);
    });

    test('passes a repository failure on', () async {
      recordings.failure = const StorageFailure('disk');

      final result = await MoveRecordingUsecase(recordings, folders)(
        'r1',
        'f2',
      );

      expect((result as Err).failure, isA<StorageFailure>());
    });
  });

  group('DeleteRecordingUsecase', () {
    test('deletes the recording', () async {
      final result = await DeleteRecordingUsecase(recordings)('r1');

      expect(result, isA<Ok<void>>());
      expect(recordings.deleted, ['r1']);
    });

    test('passes a repository failure on', () async {
      recordings.failure = const StorageFailure('disk');

      expect(await DeleteRecordingUsecase(recordings)('r1'), isA<Err<void>>());
    });
  });
}
