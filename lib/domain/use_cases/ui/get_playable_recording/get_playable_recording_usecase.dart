import 'package:study_recorder/core/errors/failure.dart';
import 'package:study_recorder/core/errors/result.dart';
import 'package:study_recorder/data/folder/folder_repository_interface.dart';
import 'package:study_recorder/data/recording/recording_model.dart';
import 'package:study_recorder/data/recording/recording_repository_interface.dart';
import 'package:study_recorder/domain/use_cases/ui/get_playlist/get_playlist_return_model.dart';

/// A single recording ready for the player (tapping one recording).
class GetPlayableRecordingUsecase {
  final FolderRepositoryInterface _folders;
  final RecordingRepositoryInterface _recordings;

  GetPlayableRecordingUsecase(this._folders, this._recordings);

  Future<Result<PlayableItem>> call(String recordingId) async {
    final recording = await _recordings.getRecording(recordingId);
    final RecordingModel found;
    switch (recording) {
      case Err(:final failure):
        return Err(failure);
      case Ok(:final value) when value == null:
        return const Err(ValidationFailure('recording_not_found'));
      case Ok(:final value):
        found = value!;
    }

    final folder = await _folders.getFolder(found.folderId);
    return folder.flatMap((f) {
      if (f == null) return const Err(ValidationFailure('folder_not_found'));
      return Ok(
        PlayableItem(
          recordingId: found.id,
          folderId: found.folderId,
          title: found.title,
          folderName: f.name,
          type: found.type,
          durationMs: found.durationMs,
          filePath: _recordings.absolutePath(found),
        ),
      );
    });
  }
}
