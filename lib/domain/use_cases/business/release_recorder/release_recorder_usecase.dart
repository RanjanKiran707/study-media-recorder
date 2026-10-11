import 'package:study_recorder/data/recorder/recorder_repository_interface.dart';

/// Closes the camera and microphone. Never fails.
class ReleaseRecorderUsecase {
  final RecorderRepositoryInterface _recorder;

  ReleaseRecorderUsecase(this._recorder);

  Future<void> call() => _recorder.release();
}
