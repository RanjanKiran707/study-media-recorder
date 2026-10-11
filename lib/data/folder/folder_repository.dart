import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:study_recorder/core/errors/failure.dart';
import 'package:study_recorder/core/errors/result.dart';
import 'package:study_recorder/data/database/app_database.dart';
import 'package:study_recorder/data/database/result_stream.dart';
import 'package:study_recorder/data/folder/folder_model.dart';
import 'package:study_recorder/data/folder/folder_repository_interface.dart';

class FolderRepository implements FolderRepositoryInterface {
  final AppDatabase _db;
  final Directory _mediaDir;

  FolderRepository(this._db, this._mediaDir);

  @override
  Future<Result<void>> createFolder(FolderModel folder) async {
    try {
      await _db
          .into(_db.folderTable)
          .insert(
            FolderTableCompanion.insert(
              id: folder.id,
              parentId: Value(folder.parentId),
              name: folder.name,
              createdAt: folder.createdAt.millisecondsSinceEpoch,
              sortIndex: Value(folder.sortIndex),
            ),
          );
      return const Ok(null);
    } catch (e) {
      return Err(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> renameFolder(String folderId, String name) async {
    try {
      final updated =
          await (_db.update(_db.folderTable)
                ..where((t) => t.id.equals(folderId)))
              .write(FolderTableCompanion(name: Value(name)));
      if (updated == 0) return const Err(StorageFailure('folder_not_found'));
      return const Ok(null);
    } catch (e) {
      return Err(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteFolder(String folderId) async {
    try {
      // Collect the folder and all its descendants, then their file paths.
      final all = await _db.select(_db.folderTable).get();
      final ids = <String>{folderId};
      var grew = true;
      while (grew) {
        grew = false;
        for (final f in all) {
          if (f.parentId != null && ids.contains(f.parentId) && ids.add(f.id)) {
            grew = true;
          }
        }
      }
      final recordings = await (_db.select(
        _db.recordingTable,
      )..where((t) => t.folderId.isIn(ids))).get();

      // Subfolders and recordings go with it through ON DELETE CASCADE.
      final deleted = await (_db.delete(
        _db.folderTable,
      )..where((t) => t.id.equals(folderId))).go();
      if (deleted == 0) return const Err(StorageFailure('folder_not_found'));

      // The data is gone, so a file that cannot be removed is only left over.
      for (final r in recordings) {
        try {
          final file = File(p.join(_mediaDir.path, r.filePath));
          if (await file.exists()) await file.delete();
        } catch (_) {}
      }
      return const Ok(null);
    } catch (e) {
      return Err(StorageFailure(e.toString()));
    }
  }

  @override
  Future<Result<FolderModel?>> getFolder(String folderId) async {
    try {
      final row = await (_db.select(
        _db.folderTable,
      )..where((t) => t.id.equals(folderId))).getSingleOrNull();
      return Ok(row == null ? null : _toModel(row));
    } catch (e) {
      return Err(StorageFailure(e.toString()));
    }
  }

  @override
  Stream<Result<List<FolderModel>>> watchFolders(String? parentId) {
    final query = _db.select(_db.folderTable)
      ..where(
        (t) => parentId == null
            ? t.parentId.isNull()
            : t.parentId.equals(parentId),
      )
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
          await (_db.update(_db.folderTable)
                ..where((t) => t.id.equals(entry.key)))
              .write(FolderTableCompanion(sortIndex: Value(entry.value)));
        }
      });
      return const Ok(null);
    } catch (e) {
      return Err(StorageFailure(e.toString()));
    }
  }

  @override
  Stream<Result<Map<String, FolderCounts>>> watchFolderCounts() {
    final query = _db.customSelect(
      'SELECT f.id AS id, '
      '(SELECT COUNT(*) FROM folder c WHERE c.parent_id = f.id) AS subfolders, '
      '(SELECT COUNT(*) FROM recording r WHERE r.folder_id = f.id) AS recordings '
      'FROM folder f',
      readsFrom: {_db.folderTable, _db.recordingTable},
    );
    return toResultStream(
      query.watch().map(
        (rows) => {
          for (final row in rows)
            row.read<String>('id'): FolderCounts(
              subfolders: row.read<int>('subfolders'),
              recordings: row.read<int>('recordings'),
            ),
        },
      ),
    );
  }

  FolderModel _toModel(FolderRow row) => FolderModel(
    id: row.id,
    parentId: row.parentId,
    name: row.name,
    createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
    sortIndex: row.sortIndex,
  );
}
