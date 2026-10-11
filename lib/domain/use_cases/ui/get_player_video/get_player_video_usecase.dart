import 'package:flutter/widgets.dart';
import 'package:study_recorder/data/player/player_repository_interface.dart';

/// The video of the current recording, or null for audio.
class GetPlayerVideoUsecase {
  final PlayerRepositoryInterface _player;

  GetPlayerVideoUsecase(this._player);

  Widget? call() => _player.buildVideo();
}
