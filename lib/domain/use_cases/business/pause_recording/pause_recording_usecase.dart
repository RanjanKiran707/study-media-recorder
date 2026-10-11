import 'package:study_recorder/core/errors/result.dart';
import 'package:study_recorder/data/recorder/recorder_repository_interface.dart';

/// Pauses the take.
class PauseRecordingUsecase {
  final RecorderRepositoryInterface _recorder;

  PauseRecordingUsecase(this._recorder);

  Future<Result<void>> call() => _recorder.pause();
}
