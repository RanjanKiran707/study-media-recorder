import 'package:study_recorder/core/errors/result.dart';
import 'package:study_recorder/data/recorder/recorder_repository_interface.dart';
import 'package:study_recorder/data/recording/recording_model.dart';

/// Asks for the permissions and opens the camera or microphone.
class PrepareRecorderUsecase {
  final RecorderRepositoryInterface _recorder;

  PrepareRecorderUsecase(this._recorder);

  Future<Result<void>> call(RecordingType type) =>
      _recorder.prepare(type: type);
}
