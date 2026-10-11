import 'package:flutter_test/flutter_test.dart';
import 'package:study_recorder/core/errors/failure.dart';
import 'package:study_recorder/core/errors/result.dart';
import 'package:study_recorder/data/recorder/recorder_repository_interface.dart';
import 'package:study_recorder/data/recording/recording_model.dart';

import '../fakes/test_env.dart';

void main() {
  late TestEnv env;

  setUp(() => env = TestEnv());

  test('prepare opens the recorder for the chosen type', () async {
    final result = await env.deps.prepareRecorder(RecordingType.video);

    expect(result, isA<Ok<void>>());
    expect(env.recorder.prepared, RecordingType.video);
  });

  test('start, pause, resume and switch camera reach the recorder', () async {
    await env.deps.startRecording();
    await env.deps.pauseRecording();
    await env.deps.resumeRecording();
    await env.deps.switchCamera();

    expect(env.recorder.calls, ['start', 'pause', 'resume', 'switchCamera']);
  });

  test('stop returns the temporary file', () async {
    await env.deps.prepareRecorder(RecordingType.audio);

    final result = await env.deps.stopRecording();

    final file = (result as Ok<RecordedFile>).value;
    expect(file.durationMs, 90000);
    expect(file.type, RecordingType.audio);
  });

  test('a permission failure is passed on', () async {
    env.recorder.failure = const ValidationFailure('permission_denied');

    final result = await env.deps.prepareRecorder(RecordingType.audio);

    expect((result as Err).failure.message, 'permission_denied');
  });

  test('discard deletes the take and release closes the recorder', () async {
    await env.deps.discardTake('/cache/take.m4a');
    await env.deps.releaseRecorder();

    expect(env.recorder.discarded, ['/cache/take.m4a']);
    expect(env.recorder.released, isTrue);
  });

  test('the preview and the elapsed time come from the recorder', () async {
    await env.deps.prepareRecorder(RecordingType.video);
    env.recorder.elapsedValue = const Duration(seconds: 5);

    expect(env.deps.getRecorderPreview(), isNotNull);
    expect(env.deps.getRecordingElapsed(), const Duration(seconds: 5));
  });

  test('audio has no preview', () async {
    await env.deps.prepareRecorder(RecordingType.audio);

    expect(env.deps.getRecorderPreview(), isNull);
  });
}
