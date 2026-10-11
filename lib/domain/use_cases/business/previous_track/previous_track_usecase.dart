import 'package:study_recorder/core/errors/result.dart';
import 'package:study_recorder/data/player/player_repository_interface.dart';

/// Restarts the recording, or goes to the previous one.
class PreviousTrackUsecase {
  final PlayerRepositoryInterface _player;

  PreviousTrackUsecase(this._player);

  Future<Result<void>> call() => _player.previous();
}
