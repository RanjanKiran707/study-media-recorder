class CreateFolderArgumentModel {
  final String folderId;

  /// Null creates a top-level folder.
  final String? parentId;
  final String name;

  const CreateFolderArgumentModel({
    required this.folderId,
    required this.parentId,
    required this.name,
  });
}
