import 'package:flutter_test/flutter_test.dart';
import 'package:study_recorder/core/errors/failure.dart';
import 'package:study_recorder/core/utils/view_state.dart';
import 'package:study_recorder/data/recorder/recorder_repository_interface.dart';
import 'package:study_recorder/data/recording/recording_model.dart';
import 'package:study_recorder/features/save_recording/save_recording_view_model.dart';

import '../../domain/fakes/test_env.dart';
import '../../domain/fakes/test_models.dart';

void main() {
  late TestEnv env;
  late SaveRecordingViewModel vm;

  setUp(() {
    env = TestEnv();
    env.folders.folders.add(folderOf('physics'));
    vm = SaveRecordingViewModel(
      bundle: const SaveRecordingBundle(
        folderId: 'physics',
        file: RecordedFile(
          path: '/cache/take.mp4',
          durationMs: 90000,
          type: RecordingType.video,
        ),
      ),
      save: env.deps.saveRecording,
      discardTake: env.deps.discardTake,
      getFolderPath: env.deps.getFolderPath,
      newId: () => 'new-id',
    );
  });

  tearDown(() => vm.dispose());

  test('loads the folder path for "Saving to ..."', () async {
    await pumpEventQueue();

    final path = vm.pathState.value as ViewStateLoaded<dynamic>;
    expect(path.data.label, 'physics');
  });

  test('save goes Idle -> Loading -> Loaded and stores the take', () async {
    expect(vm.actionState.value, isA<ViewStateIdle>());
    final seen = <ViewState<void>>[];
    vm.actionState.addListener(() => seen.add(vm.actionState.value));

    await vm.onSave(' Newton ');

    expect(seen.first, isA<ViewStateLoading>());
    expect(vm.actionState.value, isA<ViewStateLoaded>());
    final saved = env.recordings.added.single;
    expect(saved.id, 'new-id');
    expect(saved.folderId, 'physics');
    expect(saved.title, 'Newton');
    expect(saved.type, RecordingType.video);
    expect(saved.durationMs, 90000);
  });

  test('a blank title is an Error and nothing is stored', () async {
    await vm.onSave('  ');

    final state = vm.actionState.value as ViewStateError;
    expect(state.failure.message, 'title_required');
    expect(env.recordings.added, isEmpty);
  });

  test('a second save while saving is ignored', () async {
    await Future.wait([vm.onSave('A'), vm.onSave('B')]);

    expect(env.recordings.added, hasLength(1));
  });

  test('a storage failure is an Error and the take is kept', () async {
    env.recordings.failure = const StorageFailure('disk');

    await vm.onSave('Newton');

    expect(vm.actionState.value, isA<ViewStateError>());
    expect(env.recorder.discarded, isEmpty);
  });

  test('discard deletes the temporary file', () async {
    await vm.onDiscard();

    expect(env.recorder.discarded, ['/cache/take.mp4']);
    expect(vm.actionState.value, isA<ViewStateLoaded>());
  });

  test('discard failing is an Error', () async {
    env.recorder.failure = const UnexpectedFailure('boom');

    await vm.onDiscard();

    expect(vm.actionState.value, isA<ViewStateError>());
  });

  test('onErrorShown returns an error to Idle', () async {
    await vm.onSave('');
    vm.onErrorShown();

    expect(vm.actionState.value, isA<ViewStateIdle>());
  });
}
