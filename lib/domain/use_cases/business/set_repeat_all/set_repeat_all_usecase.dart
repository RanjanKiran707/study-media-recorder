import 'package:study_recorder/core/errors/result.dart';
import 'package:study_recorder/data/player/player_repository_interface.dart';

/// Turns repeat all on or off.
class SetRepeatAllUsecase {
  final PlayerRepositoryInterface _player;

  SetRepeatAllUsecase(this._player);

  Future<Result<void>> call(bool repeatAll) => _player.setRepeatAll(repeatAll);
}
