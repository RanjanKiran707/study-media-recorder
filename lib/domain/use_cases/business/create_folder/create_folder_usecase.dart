import 'package:study_recorder/core/errors/failure.dart';
import 'package:study_recorder/core/errors/result.dart';
import 'package:study_recorder/data/folder/folder_model.dart';
import 'package:study_recorder/data/folder/folder_repository_interface.dart';
import 'package:study_recorder/domain/use_cases/business/create_folder/create_folder_argument_model.dart';

class CreateFolderUsecase {
  final FolderRepositoryInterface _folders;
  final DateTime Function() _now;

  CreateFolderUsecase(this._folders, {DateTime Function() now = DateTime.now})
    : _now = now;

  Future<Result<void>> call(CreateFolderArgumentModel model) {
    final name = model.name.trim();
    if (name.isEmpty) {
      return Future.value(const Err(ValidationFailure('name_required')));
    }

    return _folders.createFolder(
      FolderModel(
        id: model.folderId,
        parentId: model.parentId,
        name: name,
        createdAt: _now(),
      ),
    );
  }
}
