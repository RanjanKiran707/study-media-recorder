import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:study_recorder/core/errors/failure.dart';
import 'package:study_recorder/core/errors/result.dart';
import 'package:study_recorder/data/database/app_database.dart';
import 'package:study_recorder/data/database/result_stream.dart';
import 'package:study_recorder/data/recording/recording_model.dart';
import 'package:study_recorder/data/recording/recording_repository_interface.dart';

class RecordingRepository implements RecordingRepositoryInterface {
  final AppDatabase _db;
  final Directory _mediaDir;

  RecordingRepository(this._db, this._mediaDir);

  @override
  Future<Result<RecordingModel>> addRecording({
    required String id,
    required String folderId,
    required String title,
    required RecordingType type,
    required String sourcePath,
    required int durationMs,
    required DateTime createdAt,
  }) async {
    File? stored;
    try {
      await _mediaDir.create(recursive: true);
      final relativePath = '$id${p.extension(sourcePath)}';
      stored = await _moveFile(
        File(sourcePath),
        p.join(_mediaDir.path, relativePath),
      );

      await _db
          .into(_db.recordingTable)
          .insert(
            RecordingTableCompanion.insert(
              id: id,
              folderId: folderId,
              title: title,
              type: type.name,
              filePath: relativePath,
              durationMs: durationMs,
              createdAt: createdAt.millisecondsSinceEpoch,
            ),
          );
      return Ok(
        RecordingModel(
          id: id,
          folderId: folderId,
          title: title,
          type: type,
          filePath: relativePath,
          durationMs: durationMs,
          createdAt: createdAt,
        ),
      );
    } catch (e) {
      // Do not leave a file behind that has no row.
      try {
        if (stored != null && await stored.exists()) await stored.delete();
      } catch (_) {}
      return Err(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> renameRecording(String recordingId, String title) async {
    try {
      final updated =
          await (_db.update(_db.recordingTable)
                ..where((t) => t.id.equals(recordingId)))
              .write(RecordingTableCompanion(title: Value(title)));
      if (updated == 0) return const Err(StorageFailure('recording_not_found'));
      return const Ok(null);
    } catch (e) {
      return Err(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> moveRecording(
    String recordingId,
    String folderId,
  ) async {
    try {
      // Added at the end of the new folder, like a new item.
      final updated =
          await (_db.update(
            _db.recordingTable,
          )..where((t) => t.id.equals(recordingId))).write(
            RecordingTableCompanion(
              folderId: Value(folderId),
              sortIndex: const Value(null),
            ),
          );
      if (updated == 0) return const Err(StorageFailure('recording_not_found'));
      return const Ok(null);
    } catch (e) {
      return Err(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteRecording(String recordingId) async {
    try {
      final row = await (_db.select(
        _db.recordingTable,
      )..where((t) => t.id.equals(recordingId))).getSingleOrNull();
      if (row == null) return const Err(StorageFailure('recording_not_found'));

      await (_db.delete(
        _db.recordingTable,
      )..where((t) => t.id.equals(recordingId))).go();

      // The row is gone, so a file that cannot be removed is only left over.
      try {
        final file = File(p.join(_mediaDir.path, row.filePath));
        if (await file.exists()) await file.delete();
      } catch (_) {}
      return const Ok(null);
    } catch (e) {
      return Err(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<RecordingModel?>> getRecording(String recordingId) async {
    try {
      final row = await (_db.select(
        _db.recordingTable,
      )..where((t) => t.id.equals(recordingId))).getSingleOrNull();
      return Ok(row == null ? null : _toModel(row));
    } catch (e) {
      return Err(StorageFailure(e.toString()));
    }
  }

  @override
  Stream<Result<List<RecordingModel>>> watchRecordings(String folderId) {
    final query = _db.select(_db.recordingTable)
      ..where((t) => t.folderId.equals(folderId))
      ..orderBy([
        (t) => OrderingTerm(expression: t.sortIndex, nulls: NullsOrder.last),
        (t) => OrderingTerm(expression: t.createdAt),
      ]);
    return toResultStream(
      query.watch().map((rows) => rows.map(_toModel).toList()),
    );
  }

  @override
  Future<Result<void>> updateSortOrder(Map<String, int> sortIndexById) async {
    try {
      await _db.transaction(() async {
        for (final entry in sortIndexById.entries) {
          await (_db.update(_db.recordingTable)
                ..where((t) => t.id.equals(entry.key)))
              .write(RecordingTableCompanion(sortIndex: Value(entry.value)));
        }
      });
      return const Ok(null);
    } catch (e) {
      return Err(StorageFailure(e.toString()));
    }
  }

  @override
  String absolutePath(RecordingModel recording) =>
      p.join(_mediaDir.path, recording.filePath);

  /// Renames the file, or copies it when the two paths are on different
  /// volumes (the recorder writes to the cache directory).
  Future<File> _moveFile(File source, String targetPath) async {
    try {
      return await source.rename(targetPath);
    } on FileSystemException {
      final copy = await source.copy(targetPath);
      await source.delete();
      return copy;
    }
  }

  RecordingModel _toModel(RecordingRow row) => RecordingModel(
    id: row.id,
    folderId: row.folderId,
    title: row.title,
    type: RecordingType.values.byName(row.type),
    filePath: row.filePath,
    durationMs: row.durationMs,
    createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
    sortIndex: row.sortIndex,
  );
}
