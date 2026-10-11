import 'package:study_recorder/core/errors/result.dart';
import 'package:study_recorder/data/folder/folder_repository_interface.dart';

/// Deletes the folder with everything inside it.
class DeleteFolderUsecase {
  final FolderRepositoryInterface _folders;

  DeleteFolderUsecase(this._folders);

  Future<Result<void>> call(String folderId) => _folders.deleteFolder(folderId);
}
