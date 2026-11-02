import 'package:drift/drift.dart';
import 'package:study_recorder/core/errors/failure.dart';
import 'package:study_recorder/core/errors/result.dart';
import 'package:study_recorder/core/storage/media_storage.dart';
import 'package:study_recorder/data/database/app_database.dart';
import 'package:study_recorder/data/database/result_stream.dart';
import 'package:study_recorder/data/recording/recording_model.dart';
import 'package:study_recorder/data/recording/recording_repository_interface.dart';

class RecordingRepository implements RecordingRepositoryInterface {
  final AppDatabase _db;
  final MediaStorage _storage;

  RecordingRepository(this._db, this._storage);

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
    String? storedRelativePath;
    try {
      storedRelativePath = await _storage.saveMedia(
        id: id,
        sourcePath: sourcePath,
      );

      await _db
          .into(_db.recordingTable)
          .insert(
            RecordingTableCompanion.insert(
              id: id,
              folderId: folderId,
              title: title,
              type: type.name,
              filePath: storedRelativePath,
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
          filePath: storedRelativePath,
          durationMs: durationMs,
          createdAt: createdAt,
        ),
      );
    } catch (e) {
      // Do not leave a file behind that has no row.
      try {
        if (storedRelativePath != null) {
          await _storage.deleteMedia(storedRelativePath);
        }
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

      // The row is gone, so remove the media file.
      try {
        await _storage.deleteMedia(row.filePath);
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
      _storage.resolveUri(recording.filePath);

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
