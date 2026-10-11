import 'package:flutter_test/flutter_test.dart';
import 'package:study_recorder/core/errors/failure.dart';
import 'package:study_recorder/core/errors/result.dart';
import 'package:study_recorder/data/recording/recording_model.dart';
import 'package:study_recorder/domain/use_cases/ui/get_folder_path/get_folder_path_return_model.dart';
import 'package:study_recorder/domain/use_cases/ui/get_folder_path/get_folder_path_usecase.dart';
import 'package:study_recorder/domain/use_cases/ui/get_playable_recording/get_playable_recording_usecase.dart';
import 'package:study_recorder/domain/use_cases/ui/get_playlist/get_playlist_return_model.dart';
import 'package:study_recorder/domain/use_cases/ui/get_playlist/get_playlist_usecase.dart';
import 'package:study_recorder/domain/use_cases/ui/list_subfolders/list_subfolders_return_model.dart';
import 'package:study_recorder/domain/use_cases/ui/list_subfolders/list_subfolders_usecase.dart';

import '../fakes/fake_folder_repository.dart';
import '../fakes/fake_recording_repository.dart';
import '../fakes/test_models.dart';

void main() {
  late FakeFolderRepository folders;
  late FakeRecordingRepository recordings;

  setUp(() {
    folders = FakeFolderRepository()
      ..folders.addAll([
        folderOf('physics', name: 'Physics'),
        folderOf('mechanics', name: 'Mechanics', parentId: 'physics'),
        folderOf('chemistry', name: 'Chemistry'),
      ]);
    recordings = FakeRecordingRepository();
  });

  group('ListSubfoldersUsecase', () {
    test('lists only the folders under the parent', () async {
      final result = await ListSubfoldersUsecase(folders)('physics').first;

      final names = (result as Ok<ListSubfoldersReturnModel>).value.folders.map(
        (f) => f.id,
      );
      expect(names, ['mechanics']);
    });

    test('null lists the top level', () async {
      final result = await ListSubfoldersUsecase(folders)(null).first;

      final ids = (result as Ok<ListSubfoldersReturnModel>).value.folders.map(
        (f) => f.id,
      );
      expect(ids, ['physics', 'chemistry']);
    });

    test('passes a repository failure on', () async {
      folders.failure = const StorageFailure('disk');

      final result = await ListSubfoldersUsecase(folders)(null).first;

      expect(result, isA<Err<ListSubfoldersReturnModel>>());
    });
  });

  group('GetFolderPathUsecase', () {
    test('goes from the top level down', () async {
      final result = await GetFolderPathUsecase(folders)('mechanics');

      final path = (result as Ok<GetFolderPathReturnModel>).value;
      expect(path.folders.map((f) => f.id), ['physics', 'mechanics']);
      expect(path.label, 'Physics / Mechanics');
    });

    test('a top-level folder is a path of one', () async {
      final result = await GetFolderPathUsecase(folders)('chemistry');

      expect((result as Ok<GetFolderPathReturnModel>).value.label, 'Chemistry');
    });

    test('unknown folder is rejected', () async {
      final result = await GetFolderPathUsecase(folders)('missing');

      expect((result as Err).failure.message, 'folder_not_found');
    });

    test('passes a repository failure on', () async {
      folders.failure = const StorageFailure('disk');

      final result = await GetFolderPathUsecase(folders)('physics');

      expect((result as Err).failure, isA<StorageFailure>());
    });
  });

  group('GetPlaylistUsecase', () {
    test(
      'lists the folder recordings with full paths, skipping subfolders',
      () async {
        recordings.recordings.addAll([
          recordingOf(
            'r1',
            'physics',
            title: 'Newton',
            type: RecordingType.video,
          ),
          recordingOf('r2', 'physics', title: 'Energy'),
          recordingOf('r3', 'mechanics'),
        ]);

        final result = await GetPlaylistUsecase(folders, recordings)('physics');

        final items = (result as Ok<GetPlaylistReturnModel>).value.items;
        expect(items.map((i) => i.recordingId), ['r1', 'r2']);
        expect(items[0].title, 'Newton');
        expect(items[0].folderName, 'Physics');
        expect(items[0].type, RecordingType.video);
        expect(items[0].filePath, '/storage/r1.m4a');
      },
    );

    test('an empty folder gives an empty playlist', () async {
      final result = await GetPlaylistUsecase(folders, recordings)('chemistry');

      expect((result as Ok<GetPlaylistReturnModel>).value.items, isEmpty);
    });

    test('unknown folder is rejected', () async {
      final result = await GetPlaylistUsecase(folders, recordings)('missing');

      expect((result as Err).failure.message, 'folder_not_found');
    });

    test('passes a repository failure on', () async {
      recordings.failure = const StorageFailure('disk');

      final result = await GetPlaylistUsecase(folders, recordings)('physics');

      expect((result as Err).failure, isA<StorageFailure>());
    });
  });

  group('GetPlayableRecordingUsecase', () {
    test('returns the recording with its folder name and path', () async {
      recordings.recordings.add(recordingOf('r1', 'mechanics', title: 'Force'));

      final result = await GetPlayableRecordingUsecase(folders, recordings)(
        'r1',
      );

      final item = (result as Ok<PlayableItem>).value;
      expect(item.title, 'Force');
      expect(item.folderName, 'Mechanics');
      expect(item.filePath, '/storage/r1.m4a');
    });

    test('unknown recording is rejected', () async {
      final result = await GetPlayableRecordingUsecase(folders, recordings)(
        'missing',
      );

      expect((result as Err).failure.message, 'recording_not_found');
    });

    test('a recording whose folder is gone is rejected', () async {
      recordings.recordings.add(recordingOf('r1', 'gone'));

      final result = await GetPlayableRecordingUsecase(folders, recordings)(
        'r1',
      );

      expect((result as Err).failure.message, 'folder_not_found');
    });
  });
}
