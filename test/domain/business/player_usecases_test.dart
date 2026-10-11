import 'package:flutter_test/flutter_test.dart';
import 'package:study_recorder/core/errors/failure.dart';
import 'package:study_recorder/core/errors/result.dart';
import 'package:study_recorder/data/recording/recording_model.dart';

import '../fakes/test_env.dart';
import '../fakes/test_models.dart';

void main() {
  late TestEnv env;

  setUp(() {
    env = TestEnv();
    env.folders.folders.add(folderOf('physics', name: 'Physics'));
    env.recordings.recordings.addAll([
      recordingOf('r1', 'physics', title: 'Newton', createdAt: 1),
      recordingOf(
        'r2',
        'physics',
        title: 'Energy',
        createdAt: 2,
        type: RecordingType.video,
      ),
    ]);
  });

  group('PlayRecordingUsecase', () {
    test('plays that recording with the whole folder as the queue', () async {
      final result = await env.deps.playRecording('r2');

      expect(result, isA<Ok<void>>());
      expect(env.player.state.queue.map((t) => t.recordingId), ['r1', 'r2']);
      expect(env.player.state.index, 1);
      expect(env.player.state.current!.recordingId, 'r2');
      expect(env.player.state.current!.type, RecordingType.video);
    });

    test('the queue is the folder of that recording, named after it', () async {
      await env.deps.playRecording('r1');

      expect(env.player.state.queue.first.folderName, 'Physics');
      expect(env.player.state.playing, isTrue);
    });

    test('a player failure is passed on', () async {
      env.player.failure = const UnexpectedFailure('boom');

      final result = await env.deps.playRecording('r1');

      expect(result, isA<Err<void>>());
    });

    test('an unknown recording is rejected', () async {
      final result = await env.deps.playRecording('missing');

      expect((result as Err).failure.message, 'recording_not_found');
    });
  });

  test('controls reach the player', () async {
    await env.deps.playRecording('r1');

    await env.deps.pausePlayer();
    await env.deps.playPlayer();
    await env.deps.nextTrack();
    await env.deps.previousTrack();
    await env.deps.seekPlayer(5000);
    await env.deps.setRepeatAll(true);
    await env.deps.stopPlayback();

    expect(env.player.calls, [
      'start',
      'pause',
      'play',
      'next',
      'previous',
      'seekTo',
      'setRepeatAll',
      'stop',
    ]);
    expect(env.player.state.isActive, isFalse);
  });
}
