import 'package:study_recorder/core/errors/result.dart';
import 'package:study_recorder/data/recording/recording_repository_interface.dart';

/// Deletes the recording and its file.
class DeleteRecordingUsecase {
  final RecordingRepositoryInterface _recordings;

  DeleteRecordingUsecase(this._recordings);

  Future<Result<void>> call(String recordingId) =>
      _recordings.deleteRecording(recordingId);
}
