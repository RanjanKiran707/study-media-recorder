import 'package:flutter/widgets.dart';
import 'package:study_recorder/data/recorder/recorder_repository_interface.dart';

/// The camera preview for the Record screen, or null for audio.
class GetRecorderPreviewUsecase {
  final RecorderRepositoryInterface _recorder;

  GetRecorderPreviewUsecase(this._recorder);

  Widget? call() => _recorder.buildPreview();
}
