import 'package:study_recorder/core/errors/result.dart';
import 'package:study_recorder/data/player/player_repository_interface.dart';
import 'package:study_recorder/domain/use_cases/ui/get_playable_recording/get_playable_recording_usecase.dart';
import 'package:study_recorder/domain/use_cases/ui/get_playlist/get_playlist_return_model.dart';
import 'package:study_recorder/domain/use_cases/ui/get_playlist/get_playlist_usecase.dart';

/// Plays the tapped recording, with the whole folder as the queue, so Next
/// and Previous move through its other recordings.
class PlayRecordingUsecase {
  final GetPlayableRecordingUsecase _getPlayable;
  final GetPlaylistUsecase _getPlaylist;
  final PlayerRepositoryInterface _player;

  PlayRecordingUsecase(this._getPlayable, this._getPlaylist, this._player);

  Future<Result<void>> call(String recordingId) async {
    final item = await _getPlayable(recordingId);
    final PlayableItem tapped;
    switch (item) {
      case Err(:final failure):
        return Err(failure);
      case Ok(:final value):
        tapped = value;
    }

    final playlist = await _getPlaylist(tapped.folderId);
    switch (playlist) {
      case Err(:final failure):
        return Err(failure);
      case Ok<GetPlaylistReturnModel>(:final value):
        final index = value.items.indexWhere(
          (i) => i.recordingId == recordingId,
        );
        if (index < 0) return _player.start([tapped.toTrack()], 0);
        return _player.start([for (final i in value.items) i.toTrack()], index);
    }
  }
}
