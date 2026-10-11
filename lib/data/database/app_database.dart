import 'package:drift/drift.dart';

part 'app_database.g.dart';

@DataClassName('FolderRow')
class FolderTable extends Table {
  @override
  String get tableName => 'folder';

  TextColumn get id => text()();
  TextColumn get parentId => text()
      .named('parent_id')
      .nullable()
      .references(FolderTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  IntColumn get createdAt => integer().named('created_at')();
  IntColumn get sortIndex => integer().named('sort_index').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('RecordingRow')
class RecordingTable extends Table {
  @override
  String get tableName => 'recording';

  TextColumn get id => text()();
  TextColumn get folderId => text()
      .named('folder_id')
      .references(FolderTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text()();
  TextColumn get type => text()();
  TextColumn get filePath => text().named('file_path')();
  IntColumn get durationMs => integer().named('duration_ms')();
  IntColumn get createdAt => integer().named('created_at')();
  IntColumn get sortIndex => integer().named('sort_index').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [FolderTable, RecordingTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      // Needed for ON DELETE CASCADE.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
