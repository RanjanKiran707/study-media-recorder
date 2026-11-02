import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:study_recorder/core/storage/media_storage.dart';

class MediaStoragePlatform implements MediaStorage {
  final Directory? _customDir;

  MediaStoragePlatform([this._customDir]);

  Directory get mediaDir => _customDir!;

  static Future<MediaStorage> create() async {
    final documents = await getApplicationDocumentsDirectory();
    final mediaDir = Directory(p.join(documents.path, 'recordings'));
    final storage = MediaStoragePlatform(mediaDir);
    await storage.init();
    return storage;
  }

  @override
  Future<void> init() async {
    if (_customDir != null) {
      await _customDir.create(recursive: true);
    }
  }

  @override
  Future<String> saveMedia({
    required String id,
    required String sourcePath,
  }) async {
    final dir = _customDir!;
    await dir.create(recursive: true);
    final relativePath = '$id${p.extension(sourcePath)}';
    final destination = File(p.join(dir.path, relativePath));
    final source = File(sourcePath);
    try {
      await source.rename(destination.path);
    } catch (_) {
      await source.copy(destination.path);
      try {
        if (await source.exists()) await source.delete();
      } catch (_) {}
    }
    return relativePath;
  }

  @override
  Future<void> deleteMedia(String relativePath) async {
    final dir = _customDir!;
    final file = File(p.join(dir.path, relativePath));
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<void> deleteMediaFiles(List<String> relativePaths) async {
    for (final rel in relativePaths) {
      await deleteMedia(rel);
    }
  }

  @override
  String resolveUri(String relativePath) =>
      p.join(_customDir!.path, relativePath);
}
