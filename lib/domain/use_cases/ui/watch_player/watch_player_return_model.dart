import 'package:study_recorder/data/recording/recording_model.dart';

/// One recording of the playlist, for the "Up next" list.
class QueueEntry {
  final String title;
  final RecordingType type;
  final int durationMs;

  const QueueEntry({
    required this.title,
    required this.type,
    required this.durationMs,
  });
}

/// What the full-screen player and the mini player show.
class WatchPlayerReturnModel {
  /// False when nothing is loaded: the mini player is hidden.
  final bool isActive;

  /// The recording that is current, to mark its row in the folder list.
  final String? recordingId;
  final String title;
  final String folderName;
  final RecordingType type;
  final bool playing;
  final bool repeatAll;
  final int positionMs;
  final int durationMs;

  /// 1-based number of the current recording and the size of the playlist.
  final int number;
  final int count;

  /// The whole playlist, in order.
  final List<QueueEntry> queue;

  const WatchPlayerReturnModel({
    required this.isActive,
    this.recordingId,
    required this.title,
    required this.folderName,
    required this.type,
    required this.playing,
    required this.repeatAll,
    required this.positionMs,
    required this.durationMs,
    required this.number,
    required this.count,
    this.queue = const [],
  });

  static const inactive = WatchPlayerReturnModel(
    isActive: false,
    title: '',
    folderName: '',
    type: RecordingType.audio,
    playing: false,
    repeatAll: false,
    positionMs: 0,
    durationMs: 0,
    number: 0,
    count: 0,
  );

  /// 0 to 1, for the progress line.
  double get progress {
    if (durationMs <= 0) return 0;
    return (positionMs / durationMs).clamp(0.0, 1.0);
  }

  bool get hasNext => isActive && (number < count || repeatAll);
}
