import 'package:study_recorder/data/folder/folder_model.dart';

class GetFolderPathReturnModel {
  /// From the top-level folder down to the requested folder.
  final List<FolderModel> folders;

  const GetFolderPathReturnModel({required this.folders});

  /// For example "Physics / Mechanics".
  String get label => folders.map((f) => f.name).join(' / ');
}
