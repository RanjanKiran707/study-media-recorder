import 'package:flutter_test/flutter_test.dart';
import 'package:study_recorder/core/errors/result.dart';
import 'package:study_recorder/data/player/player_model.dart';
import 'package:study_recorder/data/recording/recording_model.dart';
import 'package:study_recorder/domain/use_cases/ui/watch_player/watch_player_return_model.dart';

import '../fakes/test_env.dart';

PlayerTrack track(String id, {RecordingType type = RecordingType.audio}) {
  return PlayerTrack(
    recordingId: id,
    title: 'Title $id',
    folderName: 'Physics',
    type: type,
    durationMs: 100000,
    filePath: '/$id.m4a',
  );
}

PlayerStateModel stateOf(
  List<PlayerTrack> queue, {
  int index = 0,
  bool playing = false,
  bool repeatAll = false,
  int positionMs = 0,
  int durationMs = 0,
}) {
  return PlayerStateModel(
    queue: queue,
    index: index,
    playing: playing,
    repeatAll: repeatAll,
    positionMs: positionMs,
    durationMs: durationMs,
  );
}

void main() {
  late TestEnv env;

  setUp(() => env = TestEnv());

  Future<WatchPlayerReturnModel> latest() async {
    final result = await env.deps.watchPlayer().first;
    return (result as Ok<WatchPlayerReturnModel>).value;
  }

  test('nothing loaded gives an inactive model', () async {
    final model = await latest();

    expect(model.isActive, isFalse);
    expect(model.hasNext, isFalse);
  });

  test('shapes the current track, number and progress', () async {
    env.player.emit(
      stateOf(
        [track('a'), track('b')],
        index: 1,
        playing: true,
        positionMs: 25000,
        durationMs: 100000,
      ),
    );

    final model = await latest();

    expect(model.isActive, isTrue);
    expect(model.title, 'Title b');
    expect(model.folderName, 'Physics');
    expect((model.number, model.count), (2, 2));
    expect(model.progress, 0.25);
    expect(model.hasNext, isFalse);
  });

  test('repeat all makes the last track have a next', () async {
    env.player.emit(stateOf([track('a')], repeatAll: true));

    final model = await latest();

    expect(model.hasNext, isTrue);
    expect(model.durationMs, 100000); // falls back to the stored duration
  });

  test('emits again when the player changes', () async {
    final playingFlags = <bool>[];
    final sub = env.deps.watchPlayer().listen(
      (r) => playingFlags.add((r as Ok<WatchPlayerReturnModel>).value.playing),
    );
    await pumpEventQueue();

    env.player.emit(stateOf([track('a')], playing: true));
    await pumpEventQueue();
    await sub.cancel();

    expect(playingFlags, [false, true]);
  });

  test('the video comes from the player', () async {
    env.player.emit(stateOf([track('v', type: RecordingType.video)]));

    expect(env.deps.getPlayerVideo(), isNotNull);
  });
}
