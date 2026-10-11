import 'package:study_recorder/core/errors/failure.dart';
import 'package:study_recorder/core/errors/result.dart';
import 'package:study_recorder/data/folder/folder_repository_interface.dart';
import 'package:study_recorder/data/recording/recording_repository_interface.dart';
import 'package:study_recorder/domain/use_cases/business/save_recording/save_recording_argument_model.dart';

/// Saves a finished recording into the folder it was recorded from.
class SaveRecordingUsecase {
  final RecordingRepositoryInterface _recordings;
  final FolderRepositoryInterface _folders;
  final DateTime Function() _now;

  SaveRecordingUsecase(
    this._recordings,
    this._folders, {
    DateTime Function() now = DateTime.now,
  }) : _now = now;

  Future<Result<void>> call(SaveRecordingArgumentModel model) async {
    final title = model.title.trim();
    if (title.isEmpty) {
      return const Err(ValidationFailure('title_required'));
    }
    if (model.durationMs <= 0) {
      return const Err(ValidationFailure('duration_invalid'));
    }

    final folder = await _folders.getFolder(model.folderId);
    switch (folder) {
      case Err(:final failure):
        return Err(failure);
      case Ok(:final value) when value == null:
        return const Err(ValidationFailure('folder_not_found'));
      case Ok():
        break;
    }

    final saved = await _recordings.addRecording(
      id: model.recordingId,
      folderId: model.folderId,
      title: title,
      type: model.type,
      sourcePath: model.sourcePath,
      durationMs: model.durationMs,
      createdAt: _now(),
    );
    return saved.map((_) {});
  }
}
