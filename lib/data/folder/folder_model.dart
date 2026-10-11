/// What a folder holds: direct subfolders and all recordings inside it.
class FolderCounts {
  /// Direct subfolders only.
  final int subfolders;

  /// All recordings inside, including those in nested subfolders.
  final int recordings;

  const FolderCounts({required this.subfolders, required this.recordings});
}

class FolderModel {
  final String id;

  /// Null means a top-level folder (shown on Home).
  final String? parentId;
  final String name;
  final DateTime createdAt;

  /// Null means the folder was never rearranged.
  final int? sortIndex;

  const FolderModel({
    required this.id,
    required this.parentId,
    required this.name,
    required this.createdAt,
    this.sortIndex,
  });
}
