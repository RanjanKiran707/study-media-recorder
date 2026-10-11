import 'package:study_recorder/core/errors/result.dart';
import 'package:study_recorder/data/player/player_model.dart';
import 'package:study_recorder/data/player/player_repository_interface.dart';
import 'package:study_recorder/domain/use_cases/ui/watch_player/watch_player_return_model.dart';

/// The live state of the player, shaped for the player screens.
class WatchPlayerUsecase {
  final PlayerRepositoryInterface _player;

  WatchPlayerUsecase(this._player);

  Stream<Result<WatchPlayerReturnModel>> call() {
    return _player.watchState().map((result) => result.map(_shape));
  }

  WatchPlayerReturnModel _shape(PlayerStateModel state) {
    final track = state.current;
    if (track == null) return WatchPlayerReturnModel.inactive;
    return WatchPlayerReturnModel(
      isActive: true,
      recordingId: track.recordingId,
      title: track.title,
      folderName: track.folderName,
      type: track.type,
      playing: state.playing,
      repeatAll: state.repeatAll,
      positionMs: state.positionMs,
      durationMs: state.durationMs > 0 ? state.durationMs : track.durationMs,
      number: state.index + 1,
      count: state.queue.length,
      queue: [
        for (final t in state.queue)
          QueueEntry(title: t.title, type: t.type, durationMs: t.durationMs),
      ],
    );
  }
}
