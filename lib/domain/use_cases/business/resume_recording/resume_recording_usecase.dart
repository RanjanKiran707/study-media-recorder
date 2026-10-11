import 'package:study_recorder/core/errors/result.dart';
import 'package:study_recorder/data/recorder/recorder_repository_interface.dart';

/// Resumes a paused take.
class ResumeRecordingUsecase {
  final RecorderRepositoryInterface _recorder;

  ResumeRecordingUsecase(this._recorder);

  Future<Result<void>> call() => _recorder.resume();
}
