import 'package:study_recorder/core/errors/result.dart';
import 'package:study_recorder/data/recorder/recorder_repository_interface.dart';

/// Switches between the front and back camera.
class SwitchCameraUsecase {
  final RecorderRepositoryInterface _recorder;

  SwitchCameraUsecase(this._recorder);

  Future<Result<void>> call() => _recorder.switchCamera();
}
