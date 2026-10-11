import 'package:flutter_test/flutter_test.dart';
import 'package:study_recorder/core/di/app_dependencies.dart';
import 'package:study_recorder/core/errors/failure.dart';
import 'package:study_recorder/core/utils/view_state.dart';
import 'package:study_recorder/domain/use_cases/ui/list_folder_items/list_folder_items_return_model.dart';
import 'package:study_recorder/features/folder/folder_view_model.dart';

import '../../domain/fakes/fake_folder_repository.dart';
import '../../domain/fakes/fake_recording_repository.dart';
import '../../domain/fakes/test_env.dart';
import '../../domain/fakes/test_models.dart';

void main() {
  late TestEnv env;
  late FakeFolderRepository folders;
  late FakeRecordingRepository recordings;
  late AppDependencies deps;
  late FolderViewModel vm;

  FolderViewModel build(String? folderId) {
    return FolderViewModel(
      bundle: FolderBundle(folderId: folderId),
      createFolder: deps.createFolder,
      renameFolder: deps.renameFolder,
      deleteFolder: deps.deleteFolder,
      renameRecording: deps.renameRecording,
      deleteRecording: deps.deleteRecording,
      saveOrder: deps.saveOrder,
      playRecording: deps.playRecording,
      getFolderPath: deps.getFolderPath,
      listFolderItems: deps.listFolderItems,
      watchPlayer: deps.watchPlayer,
      newId: () => 'new-id',
    );
  }

  setUp(() {
    env = TestEnv();
    folders = env.folders
      ..folders.addAll([
        folderOf('physics', name: 'Physics'),
        folderOf('mechanics', name: 'Mechanics', parentId: 'physics'),
      ]);
    recordings = env.recordings
      ..recordings.addAll([
        recordingOf('r1', 'physics', createdAt: 20),
        recordingOf('r2', 'physics', createdAt: 30),
      ]);
    deps = env.deps;
  });

  tearDown(() => vm.dispose());

  List<String> idsOf(ViewState<ListFolderItemsReturnModel> state) =>
      (state as ViewStateLoaded<ListFolderItemsReturnModel>).data.items
          .map((i) => i.id)
          .toList();

  group('list', () {
    test('starts loading, then shows the folder items', () async {
      vm = build('physics');
      expect(vm.state.value, isA<ViewStateLoading>());

      await pumpEventQueue();

      expect(idsOf(vm.state.value), ['mechanics', 'r1', 'r2']);
    });

    test('Home lists the top-level folders and has no path', () async {
      vm = build(null);
      await pumpEventQueue();

      expect(vm.isHome, isTrue);
      expect(idsOf(vm.state.value), ['physics']);
      expect(vm.pathState.value, isA<ViewStateIdle>());
    });

    test('a new recording appears without any call', () async {
      vm = build('physics');
      await pumpEventQueue();

      recordings.recordings.add(recordingOf('r3', 'physics', createdAt: 40));
      recordings.notify();
      await pumpEventQueue();

      expect(idsOf(vm.state.value), ['mechanics', 'r1', 'r2', 'r3']);
    });

    test('a repository failure becomes an Error state', () async {
      recordings.failure = const StorageFailure('disk');
      vm = build('physics');
      await pumpEventQueue();

      expect(vm.state.value, isA<ViewStateError>());
    });

    test('loads the path of the folder', () async {
      vm = build('mechanics');
      await pumpEventQueue();

      final path = vm.pathState.value as ViewStateLoaded<dynamic>;
      expect(path.data.label, 'Physics / Mechanics');
    });

    test('a missing folder gives a path Error', () async {
      vm = build('missing');
      await pumpEventQueue();

      expect(vm.pathState.value, isA<ViewStateError>());
    });

    test('dispose cancels the subscription', () async {
      vm = build('physics');
      await pumpEventQueue();
      vm.dispose();

      // Must not throw "used after dispose".
      folders.notify();
      recordings.notify();
      await pumpEventQueue();

      vm = build('physics'); // for tearDown
    });
  });

  group('folder actions', () {
    setUp(() => vm = build('physics'));

    test('create goes Idle -> Loading -> Loaded', () async {
      final seen = <Type>[];
      vm.actionState.addListener(
        () => seen.add(vm.actionState.value.runtimeType),
      );

      await vm.onCreateFolder(' Waves ');

      expect(seen.first.toString(), startsWith('ViewStateLoading'));
      expect(vm.actionState.value, isA<ViewStateLoaded>());
      final created = folders.created.single;
      expect(created.id, 'new-id');
      expect(created.parentId, 'physics');
      expect(created.name, 'Waves');
    });

    test('a blank name gives an Error and creates nothing', () async {
      await vm.onCreateFolder('  ');

      final state = vm.actionState.value as ViewStateError;
      expect(state.failure.message, 'name_required');
      expect(folders.created, isEmpty);
    });

    test('a second call while loading is ignored', () async {
      final first = vm.onCreateFolder('A');
      final second = vm.onCreateFolder('B');
      await Future.wait([first, second]);

      expect(folders.created.map((f) => f.name), ['A']);
    });

    test('Home creates a top-level folder', () async {
      vm.dispose();
      vm = build(null);

      await vm.onCreateFolder('Chemistry');

      expect(folders.created.single.parentId, isNull);
    });

    test('rename and delete go to the use cases', () async {
      await vm.onRenameFolder('mechanics', 'Dynamics');
      await vm.onDeleteFolder('mechanics');

      expect(folders.renamed, {'mechanics': 'Dynamics'});
      expect(folders.deleted, ['mechanics']);
    });

    test('a storage failure becomes an Error', () async {
      folders.failure = const StorageFailure('disk');

      await vm.onDeleteFolder('mechanics');

      expect(vm.actionState.value, isA<ViewStateError>());
    });

    test('onErrorShown returns an error to Idle', () async {
      await vm.onCreateFolder('');
      vm.onErrorShown();

      expect(vm.actionState.value, isA<ViewStateIdle>());
    });
  });

  group('recording actions', () {
    setUp(() => vm = build('physics'));

    test('rename and delete go to the use cases', () async {
      await vm.onRenameRecording('r1', ' New title ');
      await vm.onDeleteRecording('r2');

      expect(recordings.renamed, {'r1': 'New title'});
      expect(recordings.deleted, ['r2']);
    });

    test('a blank title gives an Error', () async {
      await vm.onRenameRecording('r1', '');

      final state = vm.actionState.value as ViewStateError;
      expect(state.failure.message, 'title_required');
    });
  });

  group('rearranging', () {
    setUp(() async {
      vm = build('physics');
      await pumpEventQueue(); // list: mechanics, r1, r2
    });

    test('start copies the list, cancel throws the changes away', () {
      vm.onStartRearrange();
      vm.onReorder(0, 3);
      expect(vm.rearrangeItems.value!.map((i) => i.id), [
        'r1',
        'r2',
        'mechanics',
      ]);

      vm.onCancelRearrange();

      expect(vm.isRearranging, isFalse);
      expect(idsOf(vm.state.value), ['mechanics', 'r1', 'r2']);
      expect(folders.sortOrders, isEmpty);
    });

    test('dragging down and up uses the ReorderableListView indexes', () {
      vm.onStartRearrange();

      vm.onReorder(2, 0); // r2 to the top
      expect(vm.rearrangeItems.value!.map((i) => i.id), [
        'r2',
        'mechanics',
        'r1',
      ]);

      vm.onReorder(0, 2); // r2 below mechanics
      expect(vm.rearrangeItems.value!.map((i) => i.id), [
        'mechanics',
        'r2',
        'r1',
      ]);
    });

    test('save writes the shown order and leaves rearrange mode', () async {
      vm.onStartRearrange();
      vm.onReorder(2, 0); // r2, mechanics, r1

      await vm.onSaveRearrange();

      expect(vm.isRearranging, isFalse);
      expect(folders.sortOrders.single, {'mechanics': 1});
      expect(recordings.sortOrders.single, {'r2': 0, 'r1': 2});
    });

    test('a failed save stays in rearrange mode with an Error', () async {
      vm.onStartRearrange();
      folders.failure = const StorageFailure('disk');

      await vm.onSaveRearrange();

      expect(vm.isRearranging, isTrue);
      expect(vm.actionState.value, isA<ViewStateError>());
    });

    test('Home cannot be rearranged', () async {
      vm.dispose();
      vm = build(null);
      await pumpEventQueue();

      vm.onStartRearrange();

      expect(vm.isRearranging, isFalse);
    });

    test('live changes do not disturb the list being rearranged', () async {
      vm.onStartRearrange();
      recordings.recordings.add(recordingOf('r3', 'physics', createdAt: 40));
      recordings.notify();
      await pumpEventQueue();

      expect(vm.rearrangeItems.value!.map((i) => i.id), [
        'mechanics',
        'r1',
        'r2',
      ]);
    });
  });

  group('playing', () {
    setUp(() async {
      vm = build('physics');
      await pumpEventQueue();
    });

    test('tapping a recording: Loading, then Loaded', () async {
      final seen = <ViewState<void>>[];
      vm.playState.addListener(() => seen.add(vm.playState.value));

      await vm.onPlayRecording('r1');

      expect(seen.first, isA<ViewStateLoading>());
      expect(vm.playState.value, isA<ViewStateLoaded>());
    });

    test('tapping a recording plays it with the folder as the queue', () async {
      await vm.onPlayRecording('r2');

      expect(env.player.state.queue.map((t) => t.recordingId), ['r1', 'r2']);
      expect(env.player.state.current!.recordingId, 'r2');
      expect(vm.playState.value, isA<ViewStateLoaded>());
    });

    test('a second play while one is starting is ignored', () async {
      await Future.wait([vm.onPlayRecording('r1'), vm.onPlayRecording('r2')]);

      expect(env.player.calls, ['start']);
    });

    test('marks the recording that is playing', () async {
      await vm.onPlayRecording('r1');
      await pumpEventQueue();
      expect(vm.playingRecordingId.value, 'r1');

      await env.deps.pausePlayer();
      await pumpEventQueue();
      expect(vm.playingRecordingId.value, isNull);
    });

    test('onPlayHandled returns to Idle', () async {
      await vm.onPlayRecording('r1');

      vm.onPlayHandled();

      expect(vm.playState.value, isA<ViewStateIdle>());
    });
  });
}
