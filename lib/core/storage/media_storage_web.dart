import 'dart:async';
import 'dart:js_interop';

import 'package:path/path.dart' as p;
import 'package:study_recorder/core/storage/media_storage.dart';
import 'package:web/web.dart' as web;

class MediaStoragePlatform implements MediaStorage {
  web.IDBDatabase? _db;
  final Map<String, String> _blobUrls = {};

  MediaStoragePlatform([dynamic root]);

  static Future<MediaStorage> create() async {
    final storage = MediaStoragePlatform();
    await storage.init();
    return storage;
  }

  @override
  Future<void> init() async {
    final completer = Completer<web.IDBDatabase>();
    final request = web.window.indexedDB.open('study_recorder_media', 1);

    request.onupgradeneeded = (web.IDBVersionChangeEvent event) {
      final db = request.result as web.IDBDatabase;
      if (!db.objectStoreNames.contains('media')) {
        db.createObjectStore('media');
      }
    }.toJS;

    request.onsuccess = (web.Event event) {
      completer.complete(request.result as web.IDBDatabase);
    }.toJS;

    request.onerror = (web.Event event) {
      completer.completeError(Exception('Failed to open IndexedDB for media'));
    }.toJS;

    _db = await completer.future;
    await _loadExistingBlobUrls();
  }

  Future<void> _loadExistingBlobUrls() async {
    final db = _db;
    if (db == null) return;
    try {
      final tx = db.transaction('media'.toJS, 'readonly');
      final store = tx.objectStore('media');
      final keyReq = store.getAllKeys();
      final keysCompleter = Completer<JSArray<JSAny>>();

      keyReq.onsuccess = (web.Event event) {
        keysCompleter.complete(keyReq.result as JSArray<JSAny>);
      }.toJS;
      keyReq.onerror = (web.Event event) {
        keysCompleter.complete(<JSAny>[].toJS);
      }.toJS;

      final keys = await keysCompleter.future;
      for (var i = 0; i < keys.length; i++) {
        final keyStr = (keys[i] as JSString).toDart;
        final valReq = store.get(keys[i]);
        final valCompleter = Completer<web.Blob?>();
        valReq.onsuccess = (web.Event event) {
          valCompleter.complete(valReq.result as web.Blob?);
        }.toJS;
        valReq.onerror = (web.Event event) {
          valCompleter.complete(null);
        }.toJS;
        final blob = await valCompleter.future;
        if (blob != null) {
          _blobUrls[keyStr] = web.URL.createObjectURL(blob);
        }
      }
    } catch (_) {
      // Best-effort loading on startup
    }
  }

  @override
  Future<String> saveMedia({
    required String id,
    required String sourcePath,
  }) async {
    final ext = p.extension(sourcePath).isNotEmpty
        ? p.extension(sourcePath)
        : '.m4a';
    final relativePath = '$id$ext';

    // Fetch the blob from the temporary recording URL or path
    try {
      final response = await web.window.fetch(sourcePath.toJS).toDart;
      final blob = await response.blob().toDart;

      final db = _db;
      if (db != null) {
        final tx = db.transaction('media'.toJS, 'readwrite');
        final store = tx.objectStore('media');
        final putReq = store.put(blob, relativePath.toJS);
        final completer = Completer<void>();
        putReq.onsuccess = (web.Event event) {
          completer.complete();
        }.toJS;
        putReq.onerror = (web.Event event) {
          completer.complete();
        }.toJS;
        await completer.future;
      }

      // Generate a new URL or retain sourcePath
      final url = web.URL.createObjectURL(blob);
      _blobUrls[relativePath] = url;
    } catch (_) {
      // Fallback: cache current url
      _blobUrls[relativePath] = sourcePath;
    }

    return relativePath;
  }

  @override
  Future<void> deleteMedia(String relativePath) async {
    final existingUrl = _blobUrls.remove(relativePath);
    if (existingUrl != null) {
      try {
        web.URL.revokeObjectURL(existingUrl);
      } catch (_) {}
    }

    final db = _db;
    if (db == null) return;
    try {
      final tx = db.transaction('media'.toJS, 'readwrite');
      final store = tx.objectStore('media');
      final delReq = store.delete(relativePath.toJS);
      final completer = Completer<void>();
      delReq.onsuccess = (web.Event event) {
        completer.complete();
      }.toJS;
      delReq.onerror = (web.Event event) {
        completer.complete();
      }.toJS;
      await completer.future;
    } catch (_) {}
  }

  @override
  Future<void> deleteMediaFiles(List<String> relativePaths) async {
    for (final rel in relativePaths) {
      await deleteMedia(rel);
    }
  }

  @override
  String resolveUri(String relativePath) =>
      _blobUrls[relativePath] ?? relativePath;
}
