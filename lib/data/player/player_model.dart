import 'package:study_recorder/data/recording/recording_model.dart';

/// One recording in the play queue.
class PlayerTrack {
  final String recordingId;
  final String title;
  final String folderName;
  final RecordingType type;
  final int durationMs;

  /// Absolute path of the file.
  final String filePath;

  const PlayerTrack({
    required this.recordingId,
    required this.title,
    required this.folderName,
    required this.type,
    required this.durationMs,
    required this.filePath,
  });
}

/// What the player is doing now. An empty [queue] means nothing is loaded.
class PlayerStateModel {
  final List<PlayerTrack> queue;
  final int index;
  final bool playing;
  final bool repeatAll;
  final int positionMs;

  /// Length of the current track as reported by the player (0 until known).
  final int durationMs;

  const PlayerStateModel({
    required this.queue,
    required this.index,
    required this.playing,
    required this.repeatAll,
    required this.positionMs,
    required this.durationMs,
  });

  /// Repeat all is on by default, so a night of revision keeps playing.
  static const idle = PlayerStateModel(
    queue: [],
    index: 0,
    playing: false,
    repeatAll: true,
    positionMs: 0,
    durationMs: 0,
  );

  bool get isActive => queue.isNotEmpty;

  PlayerTrack? get current => isActive ? queue[index] : null;

  PlayerStateModel copyWith({
    List<PlayerTrack>? queue,
    int? index,
    bool? playing,
    bool? repeatAll,
    int? positionMs,
    int? durationMs,
  }) {
    return PlayerStateModel(
      queue: queue ?? this.queue,
      index: index ?? this.index,
      playing: playing ?? this.playing,
      repeatAll: repeatAll ?? this.repeatAll,
      positionMs: positionMs ?? this.positionMs,
      durationMs: durationMs ?? this.durationMs,
    );
  }
}
