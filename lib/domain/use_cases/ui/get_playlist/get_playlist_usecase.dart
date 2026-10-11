import 'package:study_recorder/core/errors/failure.dart';
import 'package:study_recorder/core/errors/result.dart';
import 'package:study_recorder/data/folder/folder_repository_interface.dart';
import 'package:study_recorder/data/recording/recording_repository_interface.dart';
import 'package:study_recorder/domain/use_cases/ui/get_playlist/get_playlist_return_model.dart';

/// The playlist of a folder: its recordings, in the order shown in the list.
/// A snapshot taken when playing starts. It is not kept up to date.
class GetPlaylistUsecase {
  final FolderRepositoryInterface _folders;
  final RecordingRepositoryInterface _recordings;

  GetPlaylistUsecase(this._folders, this._recordings);

  Future<Result<GetPlaylistReturnModel>> call(String folderId) async {
    final folder = await _folders.getFolder(folderId);
    final String folderName;
    switch (folder) {
      case Err(:final failure):
        return Err(failure);
      case Ok(:final value) when value == null:
        return const Err(ValidationFailure('folder_not_found'));
      case Ok(:final value):
        folderName = value!.name;
    }

    final recordings = await _recordings.watchRecordings(folderId).first;
    return recordings.map(
      (list) => GetPlaylistReturnModel(
        items: [
          for (final r in list)
            PlayableItem(
              recordingId: r.id,
              folderId: folderId,
              title: r.title,
              folderName: folderName,
              type: r.type,
              durationMs: r.durationMs,
              filePath: _recordings.absolutePath(r),
            ),
        ],
      ),
    );
  }
}
