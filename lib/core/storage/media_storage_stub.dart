import 'package:study_recorder/core/storage/media_storage.dart';

class MediaStoragePlatform implements MediaStorage {
  MediaStoragePlatform([dynamic root]);

  static Future<MediaStorage> create() async => MediaStoragePlatform();

  @override
  Future<void> init() async {}

  @override
  Future<String> saveMedia({
    required String id,
    required String sourcePath,
  }) async =>
      '$id.m4a';

  @override
  Future<void> deleteMedia(String relativePath) async {}

  @override
  Future<void> deleteMediaFiles(List<String> relativePaths) async {}

  @override
  String resolveUri(String relativePath) => relativePath;
}
