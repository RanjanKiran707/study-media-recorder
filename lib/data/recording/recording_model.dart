enum RecordingType { audio, video }

class RecordingModel {
  final String id;
  final String folderId;
  final String title;
  final RecordingType type;

  /// Relative to the recordings directory.
  final String filePath;
  final int durationMs;
  final DateTime createdAt;

  /// Null means the recording was never rearranged.
  final int? sortIndex;

  const RecordingModel({
    required this.id,
    required this.folderId,
    required this.title,
    required this.type,
    required this.filePath,
    required this.durationMs,
    required this.createdAt,
    this.sortIndex,
  });
}
