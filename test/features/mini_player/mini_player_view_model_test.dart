import 'package:flutter_test/flutter_test.dart';
import 'package:study_recorder/core/errors/failure.dart';
import 'package:study_recorder/core/utils/view_state.dart';
import 'package:study_recorder/data/player/player_model.dart';
import 'package:study_recorder/data/recording/recording_model.dart';
import 'package:study_recorder/domain/use_cases/ui/watch_player/watch_player_return_model.dart';
import 'package:study_recorder/features/mini_player/mini_player_view_model.dart';

import '../../domain/fakes/test_env.dart';

const _track = PlayerTrack(
  recordingId: 'a',
  title: 'Newton',
  folderName: 'Physics',
  type: RecordingType.audio,
  durationMs: 100000,
  filePath: '/a.m4a',
);

void main() {
  late TestEnv env;
  late MiniPlayerViewModel vm;

  MiniPlayerViewModel build() {
    final d = env.deps;
    return MiniPlayerViewModel(
      watchPlayer: d.watchPlayer,
      play: d.playPlayer,
      pause: d.pausePlayer,
      stop: d.stopPlayback,
    );
  }

  WatchPlayerReturnModel data() =>
      (vm.state.value as ViewStateLoaded<WatchPlayerReturnModel>).data;

  setUp(() async {
    env = TestEnv();
    vm = build();
    await pumpEventQueue();
  });

  tearDown(() => vm.dispose());

  void startPlaying() => env.player.emit(
    const PlayerStateModel(
      queue: [_track],
      index: 0,
      playing: true,
      repeatAll: false,
      positionMs: 25000,
      durationMs: 100000,
    ),
  );

  test('is inactive when nothing is playing', () {
    expect(data().isActive, isFalse);
  });

  test('shows the title, folder and progress when playing', () async {
    startPlaying();
    await pumpEventQueue();

    expect(data().isActive, isTrue);
    expect(data().title, 'Newton');
    expect(data().folderName, 'Physics');
    expect(data().progress, 0.25);
  });

  test('play/pause toggles', () async {
    startPlaying();
    await pumpEventQueue();

    await vm.onPlayPause();
    await pumpEventQueue();
    expect(data().playing, isFalse);

    await vm.onPlayPause();
    await pumpEventQueue();
    expect(data().playing, isTrue);
  });

  test('play/pause does nothing when inactive', () async {
    await vm.onPlayPause();

    expect(env.player.calls, isEmpty);
  });

  test('stop makes the mini player inactive', () async {
    startPlaying();
    await pumpEventQueue();

    await vm.onStop();
    await pumpEventQueue();

    expect(data().isActive, isFalse);
  });

  test('a second action while one is running is ignored', () async {
    startPlaying();
    await pumpEventQueue();

    await Future.wait([vm.onStop(), vm.onStop()]);

    expect(env.player.calls, ['stop']);
  });

  test('a player failure becomes an Error action state', () async {
    startPlaying();
    await pumpEventQueue();
    env.player.failure = const UnexpectedFailure('boom');

    await vm.onPlayPause();

    expect(vm.actionState.value, isA<ViewStateError>());
  });

  test('dispose cancels the subscription', () async {
    vm.dispose();

    startPlaying();
    await pumpEventQueue();

    vm = build(); // for tearDown
  });
}
