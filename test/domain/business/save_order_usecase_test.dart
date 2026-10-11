import 'package:flutter_test/flutter_test.dart';
import 'package:study_recorder/core/errors/failure.dart';
import 'package:study_recorder/core/errors/result.dart';
import 'package:study_recorder/domain/use_cases/business/save_order/ordered_item.dart';
import 'package:study_recorder/domain/use_cases/business/save_order/save_order_usecase.dart';

import '../fakes/fake_folder_repository.dart';
import '../fakes/fake_recording_repository.dart';

void main() {
  late FakeFolderRepository folders;
  late FakeRecordingRepository recordings;
  late SaveOrderUsecase usecase;

  setUp(() {
    folders = FakeFolderRepository();
    recordings = FakeRecordingRepository();
    usecase = SaveOrderUsecase(folders, recordings);
  });

  const folderA = OrderedItem(id: 'a', kind: OrderedItemKind.folder);
  const recordingB = OrderedItem(id: 'b', kind: OrderedItemKind.recording);
  const folderC = OrderedItem(id: 'c', kind: OrderedItemKind.folder);
  const recordingD = OrderedItem(id: 'd', kind: OrderedItemKind.recording);

  test('one shared position counter across folders and recordings', () async {
    final result = await usecase([recordingB, folderA, recordingD, folderC]);

    expect(result, isA<Ok<void>>());
    expect(folders.sortOrders.single, {'a': 1, 'c': 3});
    expect(recordings.sortOrders.single, {'b': 0, 'd': 2});
  });

  test('a list with only recordings does not touch the folders', () async {
    await usecase([recordingB, recordingD]);

    expect(folders.sortOrders, isEmpty);
    expect(recordings.sortOrders.single, {'b': 0, 'd': 1});
  });

  test('an empty list is a successful no-op', () async {
    final result = await usecase([]);

    expect(result, isA<Ok<void>>());
    expect(folders.sortOrders, isEmpty);
    expect(recordings.sortOrders, isEmpty);
  });

  test('duplicate ids are rejected and nothing is saved', () async {
    final result = await usecase([folderA, folderA]);

    expect((result as Err).failure.message, 'duplicate_items');
    expect(folders.sortOrders, isEmpty);
  });

  test('a folder failure stops before the recordings are saved', () async {
    folders.failure = const StorageFailure('disk');

    final result = await usecase([folderA, recordingB]);

    expect((result as Err).failure, isA<StorageFailure>());
    expect(recordings.sortOrders, isEmpty);
  });

  test('a recording failure is returned', () async {
    recordings.failure = const StorageFailure('disk');

    final result = await usecase([folderA, recordingB]);

    expect((result as Err).failure, isA<StorageFailure>());
  });
}
