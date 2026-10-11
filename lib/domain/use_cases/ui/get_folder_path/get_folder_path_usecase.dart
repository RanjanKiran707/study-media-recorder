import 'package:study_recorder/core/errors/failure.dart';
import 'package:study_recorder/core/errors/result.dart';
import 'package:study_recorder/data/folder/folder_model.dart';
import 'package:study_recorder/data/folder/folder_repository_interface.dart';
import 'package:study_recorder/domain/use_cases/ui/get_folder_path/get_folder_path_return_model.dart';

/// The chain of folders from the top level down to [folderId].
class GetFolderPathUsecase {
  final FolderRepositoryInterface _folders;

  GetFolderPathUsecase(this._folders);

  Future<Result<GetFolderPathReturnModel>> call(String folderId) async {
    final path = <FolderModel>[];
    String? currentId = folderId;

    while (currentId != null) {
      final result = await _folders.getFolder(currentId);
      switch (result) {
        case Err(:final failure):
          return Err(failure);
        case Ok(:final value) when value == null:
          return const Err(ValidationFailure('folder_not_found'));
        case Ok(:final value):
          path.insert(0, value!);
          currentId = value.parentId;
      }
    }
    return Ok(GetFolderPathReturnModel(folders: path));
  }
}
