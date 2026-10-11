import 'package:study_recorder/core/errors/failure.dart';
import 'package:study_recorder/core/errors/result.dart';
import 'package:study_recorder/data/folder/folder_repository_interface.dart';

class RenameFolderUsecase {
  final FolderRepositoryInterface _folders;

  RenameFolderUsecase(this._folders);

  Future<Result<void>> call(String folderId, String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return Future.value(const Err(ValidationFailure('name_required')));
    }

    return _folders.renameFolder(folderId, trimmed);
  }
}
