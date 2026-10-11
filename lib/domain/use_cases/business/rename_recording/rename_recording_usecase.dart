import 'package:study_recorder/core/errors/failure.dart';
import 'package:study_recorder/core/errors/result.dart';
import 'package:study_recorder/data/recording/recording_repository_interface.dart';

class RenameRecordingUsecase {
  final RecordingRepositoryInterface _recordings;

  RenameRecordingUsecase(this._recordings);

  Future<Result<void>> call(String recordingId, String title) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      return Future.value(const Err(ValidationFailure('title_required')));
    }

    return _recordings.renameRecording(recordingId, trimmed);
  }
}
