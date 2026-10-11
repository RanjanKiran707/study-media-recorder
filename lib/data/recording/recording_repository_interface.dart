import 'package:study_recorder/core/errors/result.dart';
import 'package:study_recorder/data/recording/recording_model.dart';

abstract interface class RecordingRepositoryInterface {
  /// Moves the file at [sourcePath] into the recordings directory and saves
  /// the recording. Returns the saved model (with its relative file path).
  Future<Result<RecordingModel>> addRecording({
    required String id,
    required String folderId,
    required String title,
    required RecordingType type,
    required String sourcePath,
    required int durationMs,
    required DateTime createdAt,
  });

  Future<Result<void>> renameRecording(String recordingId, String title);

  /// Moves the recording to the end of [folderId].
  Future<Result<void>> moveRecording(String recordingId, String folderId);

  /// Deletes the recording and its file.
  Future<Result<void>> deleteRecording(String recordingId);

  /// Ok(null) when the recording does not exist.
  Future<Result<RecordingModel?>> getRecording(String recordingId);

  /// Recordings of [folderId], ordered by sort index (nulls last), then
  /// created time. Emits again whenever they change.
  Stream<Result<List<RecordingModel>>> watchRecordings(String folderId);

  /// Sets the sort index of the given recordings (id -> index).
  Future<Result<void>> updateSortOrder(Map<String, int> sortIndexById);

  /// Full path of the recording's file on this device.
  String absolutePath(RecordingModel recording);
}
