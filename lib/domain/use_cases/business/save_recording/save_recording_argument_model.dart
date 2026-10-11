import 'package:study_recorder/data/recording/recording_model.dart';

class SaveRecordingArgumentModel {
  final String recordingId;
  final String folderId;
  final String title;
  final RecordingType type;

  /// The file written by the recorder, before it is moved into storage.
  final String sourcePath;
  final int durationMs;

  const SaveRecordingArgumentModel({
    required this.recordingId,
    required this.folderId,
    required this.title,
    required this.type,
    required this.sourcePath,
    required this.durationMs,
  });
}
