import 'package:flutter/widgets.dart';
import 'package:study_recorder/core/errors/result.dart';
import 'package:study_recorder/data/player/player_model.dart';

/// The one app-wide player. Audio tracks use `just_audio` (they keep playing
/// in the background), video tracks use `video_player`.
abstract class PlayerRepositoryInterface {
  /// Emits the current state when listened to, and again on every change
  /// (including the position, a few times a second while playing).
  Stream<Result<PlayerStateModel>> watchState();

  /// The video of the current track, or null when it is audio or nothing is
  /// loaded.
  Widget? buildVideo();

  /// Replaces the queue and starts playing [queue] at [index].
  Future<Result<void>> start(List<PlayerTrack> queue, int index);

  Future<Result<void>> play();

  Future<Result<void>> pause();

  /// Goes to the next track. At the last track it goes to the first when
  /// repeat all is on, and does nothing otherwise.
  Future<Result<void>> next();

  /// Restarts the current track when it is past the first few seconds,
  /// otherwise goes to the previous track.
  Future<Result<void>> previous();

  /// Jumps to the track at [index] of the queue and plays it.
  Future<Result<void>> skipTo(int index);

  Future<Result<void>> seekTo(int positionMs);

  Future<Result<void>> setRepeatAll(bool repeatAll);

  /// Stops playback and clears the queue.
  Future<Result<void>> stop();
}
