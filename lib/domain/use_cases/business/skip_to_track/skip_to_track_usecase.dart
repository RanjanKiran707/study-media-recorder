import 'package:study_recorder/core/errors/result.dart';
import 'package:study_recorder/data/player/player_repository_interface.dart';

/// Jumps to a recording of the playlist ("Up next") and plays it.
class SkipToTrackUsecase {
  final PlayerRepositoryInterface _player;

  SkipToTrackUsecase(this._player);

  Future<Result<void>> call(int index) => _player.skipTo(index);
}
