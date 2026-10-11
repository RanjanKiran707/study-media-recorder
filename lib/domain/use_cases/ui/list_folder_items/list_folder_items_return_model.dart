import 'package:study_recorder/data/folder/folder_model.dart';
import 'package:study_recorder/data/recording/recording_model.dart';

/// One row of a folder's list: either a subfolder or a recording.
sealed class FolderItem {
  const FolderItem();

  String get id;
}

class FolderListItem extends FolderItem {
  final FolderModel folder;
  final int subfolderCount;
  final int recordingCount;

  const FolderListItem({
    required this.folder,
    required this.subfolderCount,
    required this.recordingCount,
  });

  @override
  String get id => folder.id;
}

class RecordingListItem extends FolderItem {
  final RecordingModel recording;

  const RecordingListItem({required this.recording});

  @override
  String get id => recording.id;
}

class ListFolderItemsReturnModel {
  /// Subfolders and recordings together, in the order shown to the user.
  final List<FolderItem> items;

  const ListFolderItemsReturnModel({required this.items});
}
