import 'package:study_recorder/core/errors/result.dart';
import 'package:study_recorder/data/player/player_repository_interface.dart';

/// Resumes playback.
class PlayPlayerUsecase {
  final PlayerRepositoryInterface _player;

  PlayPlayerUsecase(this._player);

  Future<Result<void>> call() => _player.play();
}
