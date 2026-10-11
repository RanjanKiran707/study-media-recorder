import 'package:study_recorder/core/errors/result.dart';
import 'package:study_recorder/data/recorder/recorder_repository_interface.dart';

/// Deletes the temporary file of a take that is not saved.
class DiscardTakeUsecase {
  final RecorderRepositoryInterface _recorder;

  DiscardTakeUsecase(this._recorder);

  Future<Result<void>> call(String path) => _recorder.discard(path);
}
