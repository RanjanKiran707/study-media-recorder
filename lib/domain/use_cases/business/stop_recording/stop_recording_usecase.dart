import 'package:study_recorder/core/errors/result.dart';
import 'package:study_recorder/data/recorder/recorder_repository_interface.dart';

/// Stops the take and returns the temporary file.
class StopRecordingUsecase {
  final RecorderRepositoryInterface _recorder;

  StopRecordingUsecase(this._recorder);

  Future<Result<RecordedFile>> call() => _recorder.stop();
}
