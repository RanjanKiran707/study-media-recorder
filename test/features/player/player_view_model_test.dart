import 'package:flutter_test/flutter_test.dart';
import 'package:study_recorder/core/errors/failure.dart';
import 'package:study_recorder/core/utils/view_state.dart';
import 'package:study_recorder/data/player/player_model.dart';
import 'package:study_recorder/data/recording/recording_model.dart';
import 'package:study_recorder/domain/use_cases/ui/watch_player/watch_player_return_model.dart';
import 'package:study_recorder/features/player/player_view_model.dart';

import '../../domain/fakes/test_env.dart';

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

PlayerStateModel playing(List<PlayerTrack> queue, {bool isPlaying = true}) {
  return PlayerStateModel(
    queue: queue,
    index: 0,
    playing: isPlaying,
    repeatAll: false,
    positionMs: 0,
    durationMs: 100000,
  );
}

void main() {
  late TestEnv env;
  late PlayerViewModel vm;

  PlayerViewModel build() {
    final d = env.deps;
    return PlayerViewModel(
      watchPlayer: d.watchPlayer,
      play: d.playPlayer,
      pause: d.pausePlayer,
      next: d.nextTrack,
      previous: d.previousTrack,
      seek: d.seekPlayer,
      setRepeatAll: d.setRepeatAll,
      skipTo: d.skipToTrack,
      stop: d.stopPlayback,
      getVideo: d.getPlayerVideo,
    );
  }

  WatchPlayerReturnModel data() =>
      (vm.state.value as ViewStateLoaded<WatchPlayerReturnModel>).data;

  setUp(() async {
    env = TestEnv();
    env.player.emit(playing([track('a'), track('b')]));
    vm = build();
    await pumpEventQueue();
  });

  tearDown(() => vm.dispose());

  test('shows the current track', () {
    expect(data().title, 'Title a');
    expect(data().number, 1);
    expect(data().count, 2);
  });

  test('follows the player as it changes', () async {
    await env.deps.nextTrack();
    await pumpEventQueue();

    expect(data().title, 'Title b');
  });

  test('play/pause toggles', () async {
    await vm.onPlayPause();
    await pumpEventQueue();
    expect(data().playing, isFalse);

    await vm.onPlayPause();
    await pumpEventQueue();
    expect(data().playing, isTrue);
    expect(env.player.calls, ['pause', 'play']);
  });

  test('next and previous reach the player', () async {
    await vm.onNext();
    await vm.onPrevious();

    expect(env.player.calls, ['next', 'previous']);
  });

  test('tapping Up next jumps to that recording', () async {
    await vm.onSkipTo(1);
    await pumpEventQueue();

    expect(data().title, 'Title b');
    expect(data().queue.map((q) => q.title), ['Title a', 'Title b']);
  });

  test('repeat all toggles', () async {
    await vm.onToggleRepeat();
    await pumpEventQueue();
    expect(data().repeatAll, isTrue);

    await vm.onToggleRepeat();
    await pumpEventQueue();
    expect(data().repeatAll, isFalse);
  });

  test('dragging the slider only previews, letting go seeks', () async {
    vm.onSeekChanged(0.5);
    expect(vm.seekPreview.value, 0.5);
    expect(env.player.calls, isEmpty);

    await vm.onSeekEnd(0.5);

    expect(vm.seekPreview.value, isNull);
    expect(env.player.state.positionMs, 50000);
  });

  test('stop clears the player: the state becomes inactive', () async {
    await vm.onStop();
    await pumpEventQueue();

    expect(data().isActive, isFalse);
  });

  test('a failing control becomes an Error that can be cleared', () async {
    env.player.failure = const UnexpectedFailure('boom');

    await vm.onNext();

    expect(vm.actionState.value, isA<ViewStateError>());
    vm.onErrorShown();
    expect(vm.actionState.value, isA<ViewStateIdle>());
  });

  test('a second control while one is running is ignored', () async {
    await Future.wait([vm.onNext(), vm.onNext()]);

    expect(env.player.calls, ['next']);
  });

  test('a video track gives a video widget', () async {
    env.player.emit(playing([track('v', type: RecordingType.video)]));
    await pumpEventQueue();

    expect(vm.buildVideo(), isNotNull);
  });

  test('dispose cancels the subscription', () async {
    vm.dispose();

    env.player.emit(playing([track('c')])); // must not reach a disposed VM
    await pumpEventQueue();

    vm = build(); // for tearDown
  });
}
