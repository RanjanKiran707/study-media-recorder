import 'package:flutter_test/flutter_test.dart';
import 'package:study_recorder/core/errors/failure.dart';
import 'package:study_recorder/core/errors/result.dart';
import 'package:study_recorder/data/folder/folder_model.dart';
import 'package:study_recorder/domain/use_cases/ui/list_folder_items/list_folder_items_return_model.dart';
import 'package:study_recorder/domain/use_cases/ui/list_folder_items/list_folder_items_usecase.dart';

import '../fakes/fake_folder_repository.dart';
import '../fakes/fake_recording_repository.dart';
import '../fakes/test_models.dart';

void main() {
  late FakeFolderRepository folders;
  late FakeRecordingRepository recordings;
  late ListFolderItemsUsecase usecase;

  setUp(() {
    folders = FakeFolderRepository()..folders.add(folderOf('parent'));
    recordings = FakeRecordingRepository();
    usecase = ListFolderItemsUsecase(folders, recordings);
  });

  Future<List<String>> idsOf(String? folderId) async {
    final result = await usecase(folderId).first;
    return (result as Ok<ListFolderItemsReturnModel>).value.items
        .map((i) => i.id)
        .toList();
  }

  test('merges subfolders and recordings by created time', () async {
    folders.folders.addAll([
      folderOf('sub1', parentId: 'parent', createdAt: 10),
      folderOf('sub2', parentId: 'parent', createdAt: 30),
    ]);
    recordings.recordings.addAll([
      recordingOf('rec1', 'parent', createdAt: 20),
      recordingOf('rec2', 'parent', createdAt: 40),
    ]);

    expect(await idsOf('parent'), ['sub1', 'rec1', 'sub2', 'rec2']);
  });

  test('rearranged items come first, in sort index order', () async {
    folders.folders.addAll([
      folderOf('sub1', parentId: 'parent', createdAt: 10, sortIndex: 2),
      folderOf('sub2', parentId: 'parent', createdAt: 30),
    ]);
    recordings.recordings.addAll([
      recordingOf('rec1', 'parent', createdAt: 20, sortIndex: 0),
      recordingOf('rec2', 'parent', createdAt: 5, sortIndex: 1),
    ]);

    expect(await idsOf('parent'), ['rec1', 'rec2', 'sub1', 'sub2']);
  });

  test('items outside the folder are not listed', () async {
    folders.folders.add(folderOf('elsewhere', parentId: 'other'));
    recordings.recordings.add(recordingOf('rec', 'other'));

    expect(await idsOf('parent'), isEmpty);
  });

  test('Home lists the top-level folders only', () async {
    folders.folders.addAll([
      folderOf('top2', createdAt: 5),
      folderOf('sub', parentId: 'parent'),
    ]);
    recordings.recordings.add(recordingOf('rec', 'parent'));

    expect(await idsOf(null), ['parent', 'top2']);
  });

  test('folder rows carry their counts, zero when unknown', () async {
    folders.folders.addAll([
      folderOf('sub1', parentId: 'parent', createdAt: 1),
      folderOf('sub2', parentId: 'parent', createdAt: 2),
    ]);
    folders.counts = {'sub1': const FolderCounts(subfolders: 2, recordings: 4)};

    final result = await usecase('parent').first;
    final items = (result as Ok<ListFolderItemsReturnModel>).value.items;
    final sub1 = items[0] as FolderListItem;
    final sub2 = items[1] as FolderListItem;

    expect((sub1.subfolderCount, sub1.recordingCount), (2, 4));
    expect((sub2.subfolderCount, sub2.recordingCount), (0, 0));
  });

  test('emits a new Return Model when a recording is added', () async {
    final lengths = <int>[];
    final sub = usecase('parent').listen((result) {
      lengths.add(
        (result as Ok<ListFolderItemsReturnModel>).value.items.length,
      );
    });

    await pumpEventQueue();
    recordings.recordings.add(recordingOf('rec', 'parent'));
    recordings.notify();
    await pumpEventQueue();
    await sub.cancel();

    expect(lengths.first, 0);
    expect(lengths.last, 1);
  });

  test('passes a repository failure on', () async {
    recordings.failure = const StorageFailure('disk');

    final result = await usecase('parent').first;

    expect((result as Err).failure, isA<StorageFailure>());
  });

  test('cancelling stops listening to the repositories', () async {
    final sub = usecase('parent').listen((_) {});
    await pumpEventQueue();
    await sub.cancel();

    // Emitting after cancel must not throw or reach anyone.
    folders.notify();
    recordings.notify();
    await pumpEventQueue();
  });
}
