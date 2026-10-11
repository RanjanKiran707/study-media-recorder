import 'package:study_recorder/core/errors/result.dart';
import 'package:study_recorder/data/folder/folder_repository_interface.dart';
import 'package:study_recorder/domain/use_cases/ui/list_subfolders/list_subfolders_return_model.dart';

/// Only the subfolders of [parentId] (null = top level), for the Move to
/// folder picker, which shows no recordings.
class ListSubfoldersUsecase {
  final FolderRepositoryInterface _folders;

  ListSubfoldersUsecase(this._folders);

  Stream<Result<ListSubfoldersReturnModel>> call(String? parentId) {
    return _folders
        .watchFolders(parentId)
        .map(
          (result) => result.map(
            (folders) => ListSubfoldersReturnModel(folders: folders),
          ),
        );
  }
}
