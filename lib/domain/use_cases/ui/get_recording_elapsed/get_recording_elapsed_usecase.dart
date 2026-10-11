import 'package:study_recorder/data/recorder/recorder_repository_interface.dart';

/// The time recorded so far, for the running timer.
class GetRecordingElapsedUsecase {
  final RecorderRepositoryInterface _recorder;

  GetRecordingElapsedUsecase(this._recorder);

  Duration call() => _recorder.elapsed;
}
