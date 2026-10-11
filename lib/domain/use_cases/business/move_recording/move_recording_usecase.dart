import 'package:study_recorder/core/errors/failure.dart';
import 'package:study_recorder/core/errors/result.dart';
import 'package:study_recorder/data/folder/folder_repository_interface.dart';
import 'package:study_recorder/data/recording/recording_repository_interface.dart';

/// Moves a recording into another folder. The top level is not a folder, so
/// it can never be the destination.
class MoveRecordingUsecase {
  final RecordingRepositoryInterface _recordings;
  final FolderRepositoryInterface _folders;

  MoveRecordingUsecase(this._recordings, this._folders);

  Future<Result<void>> call(
    String recordingId,
    String destinationFolderId,
  ) async {
    final recording = await _recordings.getRecording(recordingId);
    switch (recording) {
      case Err(:final failure):
        return Err(failure);
      case Ok(:final value) when value == null:
        return const Err(ValidationFailure('recording_not_found'));
      case Ok(:final value) when value!.folderId == destinationFolderId:
        return const Err(ValidationFailure('same_folder'));
      case Ok():
        break;
    }

    final destination = await _folders.getFolder(destinationFolderId);
    switch (destination) {
      case Err(:final failure):
        return Err(failure);
      case Ok(:final value) when value == null:
        return const Err(ValidationFailure('folder_not_found'));
      case Ok():
        break;
    }

    return _recordings.moveRecording(recordingId, destinationFolderId);
  }
}
