import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:study_recorder/core/errors/result.dart';
import 'package:study_recorder/core/utils/view_state.dart';
import 'package:study_recorder/domain/use_cases/business/pause_player/pause_player_usecase.dart';
import 'package:study_recorder/domain/use_cases/business/play_player/play_player_usecase.dart';
import 'package:study_recorder/domain/use_cases/business/stop_playback/stop_playback_usecase.dart';
import 'package:study_recorder/domain/use_cases/ui/watch_player/watch_player_return_model.dart';
import 'package:study_recorder/domain/use_cases/ui/watch_player/watch_player_usecase.dart';

/// The small player at the bottom of Home and the folder screens. It shows
/// the title and folder, play or pause, a progress line and a stop button.
/// There is no next or previous.
class MiniPlayerViewModel {
  final WatchPlayerUsecase _watchPlayer;
  final PlayPlayerUsecase _play;
  final PausePlayerUsecase _pause;
  final StopPlaybackUsecase _stop;

  final ValueNotifier<ViewState<WatchPlayerReturnModel>> state = ValueNotifier(
    const ViewStateLoading(),
  );

  final ValueNotifier<ViewState<void>> actionState = ValueNotifier(
    const ViewStateIdle(),
  );

  StreamSubscription<Result<WatchPlayerReturnModel>>? _subscription;

  MiniPlayerViewModel({
    required WatchPlayerUsecase watchPlayer,
    required PlayPlayerUsecase play,
    required PausePlayerUsecase pause,
    required StopPlaybackUsecase stop,
  }) : _watchPlayer = watchPlayer,
       _play = play,
       _pause = pause,
       _stop = stop {
    _subscription = _watchPlayer().listen((result) {
      state.value = result.fold(
        (failure) => ViewStateError(failure),
        (data) => ViewStateLoaded(data),
      );
    });
  }

  Future<void> onPlayPause() async {
    final s = state.value;
    if (s is! ViewStateLoaded<WatchPlayerReturnModel> || !s.data.isActive) {
      return;
    }
    await _run(s.data.playing ? _pause.call : _play.call);
  }

  Future<void> onStop() => _run(_stop.call);

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
  }
}
