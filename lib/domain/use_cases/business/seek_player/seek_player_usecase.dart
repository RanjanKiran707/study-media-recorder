import 'package:study_recorder/core/errors/result.dart';
import 'package:study_recorder/data/player/player_repository_interface.dart';

/// Moves to a position in the current recording.
class SeekPlayerUsecase {
  final PlayerRepositoryInterface _player;

  SeekPlayerUsecase(this._player);

  Future<Result<void>> call(int positionMs) => _player.seekTo(positionMs);
}
