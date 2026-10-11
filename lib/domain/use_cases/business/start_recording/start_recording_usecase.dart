import 'package:study_recorder/core/errors/result.dart';
import 'package:study_recorder/data/recorder/recorder_repository_interface.dart';

/// Starts the take.
class StartRecordingUsecase {
  final RecorderRepositoryInterface _recorder;

  StartRecordingUsecase(this._recorder);

  Future<Result<void>> call() => _recorder.start();
}
