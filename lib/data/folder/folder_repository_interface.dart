import 'package:study_recorder/core/errors/result.dart';
import 'package:study_recorder/data/folder/folder_model.dart';

abstract interface class FolderRepositoryInterface {
  Future<Result<void>> createFolder(FolderModel folder);

  Future<Result<void>> renameFolder(String folderId, String name);

  /// Deletes the folder, its subfolders and every recording inside,
  /// including the recording files on disk.
  Future<Result<void>> deleteFolder(String folderId);

  /// Ok(null) when the folder does not exist.
  Future<Result<FolderModel?>> getFolder(String folderId);

  /// Child folders of [parentId] (null = top level), ordered by sort index
  /// (nulls last), then created time. Emits again whenever they change.
  Stream<Result<List<FolderModel>>> watchFolders(String? parentId);

  /// Direct subfolder and recording counts of every folder, by folder id.
  /// Emits again whenever a folder or a recording is added, moved or deleted.
  Stream<Result<Map<String, FolderCounts>>> watchFolderCounts();

  /// Sets the sort index of the given folders (id -> index).
  Future<Result<void>> updateSortOrder(Map<String, int> sortIndexById);
}
