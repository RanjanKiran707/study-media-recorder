import 'package:study_recorder/core/errors/result.dart';
import 'package:study_recorder/data/player/player_repository_interface.dart';

/// Goes to the next recording of the playlist.
class NextTrackUsecase {
  final PlayerRepositoryInterface _player;

  NextTrackUsecase(this._player);

  Future<Result<void>> call() => _player.next();
}
