import 'package:flutter_test/flutter_test.dart';
import 'package:study_recorder/core/errors/failure.dart';
import 'package:study_recorder/core/utils/view_state.dart';
import 'package:study_recorder/domain/use_cases/ui/list_subfolders/list_subfolders_return_model.dart';
import 'package:study_recorder/features/move_to/move_to_view_model.dart';

import '../../domain/fakes/test_env.dart';
import '../../domain/fakes/test_models.dart';

void main() {
  late TestEnv env;
  late MoveToViewModel vm;

  setUp(() {
    env = TestEnv();
    env.folders.folders.addAll([
      folderOf('physics', name: 'Physics', createdAt: 1),
      folderOf('chemistry', name: 'Chemistry', createdAt: 2),
      folderOf('mechanics', name: 'Mechanics', parentId: 'physics'),
    ]);
    env.recordings.recordings.add(recordingOf('r1', 'physics'));
    vm = MoveToViewModel(
      bundle: const MoveToBundle(recordingId: 'r1', currentFolderId: 'physics'),
      moveRecording: env.deps.moveRecording,
      listSubfolders: env.deps.listSubfolders,
      getFolderPath: env.deps.getFolderPath,
    );
  });

  tearDown(() => vm.dispose());

  List<String> idsShown() =>
      (vm.state.value as ViewStateLoaded<ListSubfoldersReturnModel>)
          .data
          .folders
          .map((f) => f.id)
          .toList();

  test('starts at the top level and lists the top folders', () async {
    vm.dispose();
    vm = MoveToViewModel(
      bundle: const MoveToBundle(recordingId: 'r1', currentFolderId: 'physics'),
      moveRecording: env.deps.moveRecording,
      listSubfolders: env.deps.listSubfolders,
      getFolderPath: env.deps.getFolderPath,
    ); // a fresh one: nothing has been delivered yet
    expect(vm.state.value, isA<ViewStateLoading>());

    await pumpEventQueue();

    expect(vm.isTopLevel, isTrue);
    expect(idsShown(), ['physics', 'chemistry']);
    expect(vm.pathState.value, isA<ViewStateIdle>());
  });

  test('selecting is not allowed at the top level', () async {
    await pumpEventQueue();

    expect(vm.canSelect, isFalse);
    await vm.onSelect();

    expect(env.recordings.moved, isEmpty);
  });

  test('tapping a folder opens it and shows its path', () async {
    await pumpEventQueue();

    vm.onOpenFolder('physics');
    await pumpEventQueue();

    expect(vm.currentFolderId.value, 'physics');
    expect(idsShown(), ['mechanics']);
    final path = vm.pathState.value as ViewStateLoaded<dynamic>;
    expect(path.data.label, 'Physics');
  });

  test('the folder the recording is in cannot be selected', () async {
    await pumpEventQueue();
    vm.onOpenFolder('physics');

    expect(vm.canSelect, isFalse);
    await vm.onSelect();

    expect(env.recordings.moved, isEmpty);
  });

  test('another folder can be selected and the recording moves', () async {
    await pumpEventQueue();
    vm.onOpenFolder('chemistry');
    await pumpEventQueue();

    expect(vm.canSelect, isTrue);
    await vm.onSelect();

    expect(env.recordings.moved, {'r1': 'chemistry'});
    expect(vm.actionState.value, isA<ViewStateLoaded>());
  });

  test('a subfolder can be selected too', () async {
    await pumpEventQueue();
    vm.onOpenFolder('physics');
    vm.onOpenFolder('mechanics');
    await pumpEventQueue();

    await vm.onSelect();

    expect(env.recordings.moved, {'r1': 'mechanics'});
  });

  test('up goes back one level at a time, then reports the top', () async {
    await pumpEventQueue();
    vm.onOpenFolder('physics');
    vm.onOpenFolder('mechanics');

    expect(vm.onUp(), isTrue);
    expect(vm.currentFolderId.value, 'physics');
    expect(vm.onUp(), isTrue);
    expect(vm.currentFolderId.value, isNull);
    expect(vm.onUp(), isFalse); // the View closes the screen
  });

  test('a failed move is an Error and stays on the screen', () async {
    await pumpEventQueue();
    vm.onOpenFolder('chemistry');
    env.recordings.failure = const StorageFailure('disk');

    await vm.onSelect();

    expect(vm.actionState.value, isA<ViewStateError>());
  });

  test('a repository failure while listing is an Error state', () async {
    env.folders.failure = const StorageFailure('disk');

    vm.onOpenFolder('physics');
    await pumpEventQueue();

    expect(vm.state.value, isA<ViewStateError>());
  });

  test('onErrorShown returns an error to Idle', () async {
    await pumpEventQueue();
    vm.onOpenFolder('chemistry');
    env.recordings.failure = const StorageFailure('disk');
    await vm.onSelect();

    vm.onErrorShown();

    expect(vm.actionState.value, isA<ViewStateIdle>());
  });

  test('dispose cancels the subscription', () async {
    await pumpEventQueue();
    vm.dispose();

    env.folders.notify();
    await pumpEventQueue();

    vm = MoveToViewModel(
      bundle: const MoveToBundle(recordingId: 'r1', currentFolderId: 'physics'),
      moveRecording: env.deps.moveRecording,
      listSubfolders: env.deps.listSubfolders,
      getFolderPath: env.deps.getFolderPath,
    ); // for tearDown
  });
}
