import 'dart:io';

import 'package:drift/native.dart';
import 'package:study_recorder/core/errors/result.dart';
import 'package:study_recorder/data/database/app_database.dart';
import 'package:study_recorder/data/folder/folder_model.dart';
import 'package:study_recorder/data/folder/folder_repository.dart';
import 'package:study_recorder/data/recording/recording_model.dart';
import 'package:study_recorder/data/recording/recording_repository.dart';

/// In-memory database plus a temp directory for the media files.
class DataTestEnv {
  final AppDatabase db;
  final Directory mediaDir;
  final Directory cacheDir;
  final FolderRepository folders;
  final RecordingRepository recordings;

  DataTestEnv._(this.db, this.mediaDir, this.cacheDir)
    : folders = FolderRepository(db, mediaDir),
      recordings = RecordingRepository(db, mediaDir);

  static Future<DataTestEnv> create() async {
    final root = await Directory.systemTemp.createTemp('study_recorder_test_');
    final media = Directory('${root.path}/recordings');
    final cache = Directory('${root.path}/cache')..createSync();
    return DataTestEnv._(AppDatabase(NativeDatabase.memory()), media, cache);
  }

  Future<void> dispose() async {
    await db.close();
    await mediaDir.parent.delete(recursive: true);
  }

  /// A fake recorder output file in the cache directory.
  Future<String> cacheFile(String name) async {
    final file = File('${cacheDir.path}/$name');
    await file.writeAsString('data');
    return file.path;
  }

  Future<void> addFolder(
    String id, {
    String? parentId,
    int createdAt = 0,
    int? sortIndex,
  }) async {
    final result = await folders.createFolder(
      FolderModel(
        id: id,
        parentId: parentId,
        name: id,
        createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
        sortIndex: sortIndex,
      ),
    );
    expectOk(result);
  }

  Future<RecordingModel> addRecording(
    String id,
    String folderId, {
    int createdAt = 0,
    String fileName = 'rec.m4a',
    RecordingType type = RecordingType.audio,
  }) async {
    final result = await recordings.addRecording(
      id: id,
      folderId: folderId,
      title: id,
      type: type,
      sourcePath: await cacheFile('$id-$fileName'),
      durationMs: 1000,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
    );
    return (result as Ok<RecordingModel>).value;
  }
}

void expectOk(Result<Object?> result) {
  if (result is Err) {
    throw StateError('Expected Ok but got Err: ${result.failure.message}');
  }
}
