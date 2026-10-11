import 'package:study_recorder/core/errors/result.dart';
import 'package:study_recorder/data/player/player_repository_interface.dart';

/// Stops playback and clears the playlist. The mini player goes away.
class StopPlaybackUsecase {
  final PlayerRepositoryInterface _player;

  StopPlaybackUsecase(this._player);

  Future<Result<void>> call() => _player.stop();
}
