abstract interface class MediaStorage {
  /// Initializes the storage engine (e.g. creating directories or opening DB).
  Future<void> init();

  /// Persists a media file from [sourcePath] into storage for recording [id].
  /// Returns the relative path/identifier of the saved media.
  Future<String> saveMedia({
    required String id,
    required String sourcePath,
  });

  /// Deletes a single media file by its relative path.
  Future<void> deleteMedia(String relativePath);

  /// Deletes multiple media files by their relative paths.
  Future<void> deleteMediaFiles(List<String> relativePaths);

  /// Resolves the playback URI (file path on native, blob URL on web).
  String resolveUri(String relativePath);
}
