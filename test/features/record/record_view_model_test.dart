import 'package:flutter_test/flutter_test.dart';
import 'package:study_recorder/core/errors/failure.dart';
import 'package:study_recorder/core/utils/view_state.dart';
import 'package:study_recorder/data/recording/recording_model.dart';
import 'package:study_recorder/features/record/record_view_model.dart';

import '../../domain/fakes/test_env.dart';

void main() {
  late TestEnv env;
  late RecordViewModel vm;

  RecordViewModel build() {
    final d = env.deps;
    return RecordViewModel(
      bundle: const RecordBundle(folderId: 'physics'),
      prepare: d.prepareRecorder,
      start: d.startRecording,
      pause: d.pauseRecording,
      resume: d.resumeRecording,
      stop: d.stopRecording,
      switchCamera: d.switchCamera,
      discardTake: d.discardTake,
      release: d.releaseRecorder,
      getPreview: d.getRecorderPreview,
      getElapsed: d.getRecordingElapsed,
      tick: const Duration(milliseconds: 10),
    );
  }

  setUp(() {
    env = TestEnv();
    vm = build();
  });

  tearDown(() => vm.dispose());

  test('prepares the camera on open: Loading, then Loaded', () async {
    vm.dispose();
    vm = build(); // a fresh one: setUp's has already finished preparing
    expect(vm.prepareState.value, isA<ViewStateLoading>());

    await pumpEventQueue();

    expect(vm.prepareState.value, isA<ViewStateLoaded>());
    expect(env.recorder.prepared, RecordingType.video);
    expect(vm.session.value.phase, RecordPhase.ready);
  });

  test('a refused permission becomes an Error, retry prepares again', () async {
    vm.dispose();
    env.recorder.failure = const ValidationFailure('permission_denied');
    vm = build();
    await pumpEventQueue();

    final state = vm.prepareState.value as ViewStateError;
    expect(state.failure.message, 'permission_denied');
    expect(vm.canRecord, isFalse);

    env.recorder.failure = null;
    await vm.onRetryPrepare();

    expect(vm.prepareState.value, isA<ViewStateLoaded>());
  });

  test('switching to audio prepares audio and hides the preview', () async {
    await pumpEventQueue();
    expect(vm.buildPreview(), isNotNull);

    await vm.onSelectType(RecordingType.audio);

    expect(env.recorder.prepared, RecordingType.audio);
    expect(vm.session.value.type, RecordingType.audio);
    expect(vm.buildPreview(), isNull);
  });

  test('the type cannot change once the take has started', () async {
    await pumpEventQueue();
    await vm.onStart();

    await vm.onSelectType(RecordingType.audio);

    expect(vm.session.value.type, RecordingType.video);
  });

  test('start moves to recording and the timer follows the recorder', () async {
    await pumpEventQueue();

    await vm.onStart();
    env.recorder.elapsedValue = const Duration(seconds: 7);
    await Future<void>.delayed(const Duration(milliseconds: 40));

    expect(vm.session.value.phase, RecordPhase.recording);
    expect(vm.session.value.elapsed, const Duration(seconds: 7));
    expect(vm.actionState.value, isA<ViewStateLoaded>());
  });

  test('start is ignored before the recorder is ready', () async {
    vm.dispose();
    env.recorder.calls.clear();
    vm = build();
    await vm.onStart(); // still preparing

    expect(env.recorder.calls, ['prepare']);
    expect(vm.session.value.phase, RecordPhase.ready);
  });

  test('a second start while starting is ignored', () async {
    await pumpEventQueue();

    await Future.wait([vm.onStart(), vm.onStart()]);

    expect(env.recorder.calls.where((c) => c == 'start'), hasLength(1));
  });

  test('a failed start stays ready and shows an Error', () async {
    await pumpEventQueue();
    env.recorder.failure = const UnexpectedFailure('boom');

    await vm.onStart();

    expect(vm.session.value.phase, RecordPhase.ready);
    expect(vm.actionState.value, isA<ViewStateError>());
  });

  test('pause freezes the timer, resume continues', () async {
    await pumpEventQueue();
    await vm.onStart();
    env.recorder.elapsedValue = const Duration(seconds: 3);

    await vm.onPauseResume();
    expect(vm.session.value.phase, RecordPhase.paused);
    expect(vm.session.value.elapsed, const Duration(seconds: 3));

    env.recorder.elapsedValue = const Duration(seconds: 9);
    await Future<void>.delayed(const Duration(milliseconds: 40));
    expect(vm.session.value.elapsed, const Duration(seconds: 3));

    await vm.onPauseResume();
    expect(vm.session.value.phase, RecordPhase.recording);
    expect(env.recorder.calls, containsAllInOrder(['pause', 'resume']));
  });

  test('done stops the take and publishes the file', () async {
    await pumpEventQueue();
    await vm.onStart();

    await vm.onDone();

    final file = vm.finished.value!;
    expect(file.durationMs, 90000);
    expect(file.type, RecordingType.video);
    expect(vm.actionState.value, isA<ViewStateLoaded>());
  });

  test('done before starting does nothing', () async {
    await pumpEventQueue();

    await vm.onDone();

    expect(vm.finished.value, isNull);
    expect(env.recorder.calls, ['prepare']);
  });

  test('a failed stop shows an Error and publishes nothing', () async {
    await pumpEventQueue();
    await vm.onStart();
    env.recorder.failure = const UnexpectedFailure('boom');

    await vm.onDone();

    expect(vm.finished.value, isNull);
    expect(vm.actionState.value, isA<ViewStateError>());
  });

  test('switch camera works for video, not for audio', () async {
    await pumpEventQueue();
    await vm.onSwitchCamera();
    await vm.onSelectType(RecordingType.audio);
    await vm.onSwitchCamera();

    expect(env.recorder.calls.where((c) => c == 'switchCamera'), hasLength(1));
  });

  test('discard stops a started take and deletes its file', () async {
    await pumpEventQueue();
    await vm.onStart();

    await vm.onDiscard();

    expect(env.recorder.discarded, ['/cache/take.mp4']);
    expect(vm.session.value.phase, RecordPhase.ready);
    expect(vm.finished.value, isNull);
  });

  test('discard before starting touches no file', () async {
    await pumpEventQueue();

    await vm.onDiscard();

    expect(env.recorder.discarded, isEmpty);
  });

  test('onErrorShown returns an error to Idle', () async {
    await pumpEventQueue();
    env.recorder.failure = const UnexpectedFailure('boom');
    await vm.onStart();

    vm.onErrorShown();

    expect(vm.actionState.value, isA<ViewStateIdle>());
  });

  test('dispose releases the recorder and stops the timer', () async {
    await pumpEventQueue();
    await vm.onStart();

    vm.dispose();
    await Future<void>.delayed(const Duration(milliseconds: 40));

    expect(env.recorder.released, isTrue);
    vm = build(); // for tearDown
  });
}
