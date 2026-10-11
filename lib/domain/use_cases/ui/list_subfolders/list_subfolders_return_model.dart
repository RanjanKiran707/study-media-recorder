import 'package:study_recorder/data/folder/folder_model.dart';

class ListSubfoldersReturnModel {
  final List<FolderModel> folders;

  /// Recordings inside each folder (including nested), by folder id. A folder
  /// that is missing has none.
  final Map<String, int> recordingCounts;

  const ListSubfoldersReturnModel({
    required this.folders,
    this.recordingCounts = const {},
  });
}
