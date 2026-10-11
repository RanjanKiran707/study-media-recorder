import 'package:study_recorder/core/errors/result.dart';
import 'package:study_recorder/core/utils/combine_latest.dart';
import 'package:study_recorder/data/folder/folder_repository_interface.dart';
import 'package:study_recorder/domain/use_cases/ui/list_subfolders/list_subfolders_return_model.dart';

/// Only the subfolders of [parentId] (null = top level), for the Move to
/// folder picker, which shows no recordings. Each folder comes with the
/// number of recordings inside it.
class ListSubfoldersUsecase {
  final FolderRepositoryInterface _folders;

  ListSubfoldersUsecase(this._folders);

  Stream<Result<ListSubfoldersReturnModel>> call(String? parentId) {
    return combineLatest2(
      _folders.watchFolders(parentId),
      _folders.watchFolderCounts(),
      (folders, counts) => folders.flatMap(
        (list) => counts.map(
          (byId) => ListSubfoldersReturnModel(
            folders: list,
            recordingCounts: {
              for (final entry in byId.entries)
                entry.key: entry.value.recordings,
            },
          ),
        ),
      ),
    );
  }
}
