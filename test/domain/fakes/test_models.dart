import 'package:study_recorder/data/folder/folder_model.dart';
import 'package:study_recorder/data/recording/recording_model.dart';

FolderModel folderOf(
  String id, {
  String? parentId,
  String? name,
  int createdAt = 0,
  int? sortIndex,
}) {
  return FolderModel(
    id: id,
    parentId: parentId,
    name: name ?? id,
    createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
    sortIndex: sortIndex,
  );
}

RecordingModel recordingOf(
  String id,
  String folderId, {
  String? title,
  int createdAt = 0,
  int? sortIndex,
  RecordingType type = RecordingType.audio,
}) {
  return RecordingModel(
    id: id,
    folderId: folderId,
    title: title ?? id,
    type: type,
    filePath: '$id.m4a',
    durationMs: 1000,
    createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
    sortIndex: sortIndex,
  );
}
