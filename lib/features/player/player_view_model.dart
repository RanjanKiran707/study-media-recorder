import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:study_recorder/core/errors/result.dart';
import 'package:study_recorder/core/utils/view_state.dart';
import 'package:study_recorder/domain/use_cases/business/next_track/next_track_usecase.dart';
import 'package:study_recorder/domain/use_cases/business/pause_player/pause_player_usecase.dart';
import 'package:study_recorder/domain/use_cases/business/play_player/play_player_usecase.dart';
import 'package:study_recorder/domain/use_cases/business/previous_track/previous_track_usecase.dart';
import 'package:study_recorder/domain/use_cases/business/seek_player/seek_player_usecase.dart';
import 'package:study_recorder/domain/use_cases/business/set_repeat_all/set_repeat_all_usecase.dart';
import 'package:study_recorder/domain/use_cases/business/skip_to_track/skip_to_track_usecase.dart';
import 'package:study_recorder/domain/use_cases/business/stop_playback/stop_playback_usecase.dart';
import 'package:study_recorder/domain/use_cases/ui/get_player_video/get_player_video_usecase.dart';
import 'package:study_recorder/domain/use_cases/ui/watch_player/watch_player_return_model.dart';
import 'package:study_recorder/domain/use_cases/ui/watch_player/watch_player_usecase.dart';

/// The full-screen player. It has no arguments: it shows whatever the
/// app-wide player is playing.
class PlayerViewModel {
  final WatchPlayerUsecase _watchPlayer;
  final PlayPlayerUsecase _play;
  final PausePlayerUsecase _pause;
  final NextTrackUsecase _next;
  final PreviousTrackUsecase _previous;
  final SeekPlayerUsecase _seek;
  final SetRepeatAllUsecase _setRepeatAll;
  final SkipToTrackUsecase _skipTo;
  final StopPlaybackUsecase _stop;
  final GetPlayerVideoUsecase _getVideo;

  final ValueNotifier<ViewState<WatchPlayerReturnModel>> state = ValueNotifier(
    const ViewStateLoading(),
  );

  /// State of the last control action (an Error is shown, then cleared).
  final ValueNotifier<ViewState<void>> actionState = ValueNotifier(
    const ViewStateIdle(),
  );

  /// Where the slider is while the user drags it (0 to 1), otherwise null.
  final ValueNotifier<double?> seekPreview = ValueNotifier(null);

  StreamSubscription<Result<WatchPlayerReturnModel>>? _subscription;

  PlayerViewModel({
    required WatchPlayerUsecase watchPlayer,
    required PlayPlayerUsecase play,
    required PausePlayerUsecase pause,
    required NextTrackUsecase next,
    required PreviousTrackUsecase previous,
    required SeekPlayerUsecase seek,
    required SetRepeatAllUsecase setRepeatAll,
    required SkipToTrackUsecase skipTo,
    required StopPlaybackUsecase stop,
    required GetPlayerVideoUsecase getVideo,
  }) : _watchPlayer = watchPlayer,
       _play = play,
       _pause = pause,
       _next = next,
       _previous = previous,
       _seek = seek,
       _setRepeatAll = setRepeatAll,
       _skipTo = skipTo,
       _stop = stop,
       _getVideo = getVideo {
    _subscription = _watchPlayer().listen((result) {
      state.value = result.fold(
        (failure) => ViewStateError(failure),
        (data) => ViewStateLoaded(data),
      );
    });
  }

  WatchPlayerReturnModel? get _current {
    final s = state.value;
    return s is ViewStateLoaded<WatchPlayerReturnModel> ? s.data : null;
  }

  /// The video of the current recording. Null for audio.
  Widget? buildVideo() => _getVideo();

  Future<void> onPlayPause() async {
    final current = _current;
    if (current == null || !current.isActive) return;
    await _run(current.playing ? _pause.call : _play.call);
  }

  Future<void> onNext() => _run(_next.call);

  Future<void> onPrevious() => _run(_previous.call);

  Future<void> onToggleRepeat() async {
    final current = _current;
    if (current == null) return;
    await _run(() => _setRepeatAll(!current.repeatAll));
  }

  /// The user is dragging the slider.
  void onSeekChanged(double fraction) {
    seekPreview.value = fraction.clamp(0.0, 1.0);
  }

  /// The user let go of the slider.
  Future<void> onSeekEnd(double fraction) async {
    final current = _current;
    seekPreview.value = null;
    if (current == null || current.durationMs <= 0) return;
    final position = (fraction.clamp(0.0, 1.0) * current.durationMs).round();
    await _run(() => _seek(position));
  }

  /// Tapping a recording in "Up next".
  Future<void> onSkipTo(int index) => _run(() => _skipTo(index));

  /// The ✕ button: stops playback. The View closes when the player is idle.
  Future<void> onStop() => _run(_stop.call);

  /// Clears an error after the View has shown it.
  void onErrorShown() {
    if (actionState.value is ViewStateError) {
      actionState.value = const ViewStateIdle();
    }
  }

  Future<void> _run(Future<Result<void>> Function() action) async {
    if (actionState.value.isLoading) return; // ignore re-entry
    actionState.value = const ViewStateLoading();
    final result = await action();
    actionState.value = result.fold<ViewState<void>>(
      (failure) => ViewStateError(failure),
      (_) => const ViewStateIdle(),
    );
  }

  void dispose() {
    _subscription?.cancel();
    state.dispose();
    actionState.dispose();
    seekPreview.dispose();
  }
}
