import 'package:study_recorder/core/errors/result.dart';
import 'package:study_recorder/data/player/player_repository_interface.dart';

/// Pauses playback.
class PausePlayerUsecase {
  final PlayerRepositoryInterface _player;

  PausePlayerUsecase(this._player);

  Future<Result<void>> call() => _player.pause();
}
