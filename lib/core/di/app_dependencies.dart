import 'dart:io';

import 'package:drift_flutter/drift_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:study_recorder/data/database/app_database.dart';
import 'package:study_recorder/data/folder/folder_repository.dart';
import 'package:study_recorder/data/folder/folder_repository_interface.dart';
import 'package:study_recorder/data/recording/recording_repository.dart';
import 'package:study_recorder/data/recording/recording_repository_interface.dart';
import 'package:study_recorder/domain/use_cases/business/create_folder/create_folder_usecase.dart';
import 'package:study_recorder/domain/use_cases/business/delete_folder/delete_folder_usecase.dart';
import 'package:study_recorder/domain/use_cases/business/delete_recording/delete_recording_usecase.dart';
import 'package:study_recorder/domain/use_cases/business/move_recording/move_recording_usecase.dart';
import 'package:study_recorder/domain/use_cases/business/rename_folder/rename_folder_usecase.dart';
import 'package:study_recorder/domain/use_cases/business/rename_recording/rename_recording_usecase.dart';
import 'package:study_recorder/domain/use_cases/business/save_order/save_order_usecase.dart';
import 'package:study_recorder/domain/use_cases/business/save_recording/save_recording_usecase.dart';
import 'package:study_recorder/domain/use_cases/ui/get_folder_path/get_folder_path_usecase.dart';
import 'package:study_recorder/domain/use_cases/ui/get_playable_recording/get_playable_recording_usecase.dart';
import 'package:study_recorder/domain/use_cases/ui/get_playlist/get_playlist_usecase.dart';
import 'package:study_recorder/domain/use_cases/ui/list_folder_items/list_folder_items_usecase.dart';
import 'package:study_recorder/domain/use_cases/ui/list_subfolders/list_subfolders_usecase.dart';

class AppDependencies {
  // Set once in main() before runApp. Tests can replace it.
  static late AppDependencies instance;

  // Business use cases.
  final CreateFolderUsecase createFolder;
  final RenameFolderUsecase renameFolder;
  final DeleteFolderUsecase deleteFolder;
  final SaveRecordingUsecase saveRecording;
  final RenameRecordingUsecase renameRecording;
  final MoveRecordingUsecase moveRecording;
  final DeleteRecordingUsecase deleteRecording;
  final SaveOrderUsecase saveOrder;

  // UI use cases.
  final ListFolderItemsUsecase listFolderItems;
  final ListSubfoldersUsecase listSubfolders;
  final GetFolderPathUsecase getFolderPath;
  final GetPlaylistUsecase getPlaylist;
  final GetPlayableRecordingUsecase getPlayableRecording;

  AppDependencies({
    required this.createFolder,
    required this.renameFolder,
    required this.deleteFolder,
    required this.saveRecording,
    required this.renameRecording,
    required this.moveRecording,
    required this.deleteRecording,
    required this.saveOrder,
    required this.listFolderItems,
    required this.listSubfolders,
    required this.getFolderPath,
    required this.getPlaylist,
    required this.getPlayableRecording,
  });

  /// Builds the use cases on top of the given repositories. Used by [init]
  /// and by tests that want the real use cases on fake repositories.
  factory AppDependencies.fromRepositories(
    FolderRepositoryInterface folders,
    RecordingRepositoryInterface recordings,
  ) {
    return AppDependencies(
      createFolder: CreateFolderUsecase(folders),
      renameFolder: RenameFolderUsecase(folders),
      deleteFolder: DeleteFolderUsecase(folders),
      saveRecording: SaveRecordingUsecase(recordings, folders),
      renameRecording: RenameRecordingUsecase(recordings),
      moveRecording: MoveRecordingUsecase(recordings, folders),
      deleteRecording: DeleteRecordingUsecase(recordings),
      saveOrder: SaveOrderUsecase(folders, recordings),
      listFolderItems: ListFolderItemsUsecase(folders, recordings),
      listSubfolders: ListSubfoldersUsecase(folders),
      getFolderPath: GetFolderPathUsecase(folders),
      getPlaylist: GetPlaylistUsecase(folders, recordings),
      getPlayableRecording: GetPlayableRecordingUsecase(folders, recordings),
    );
  }

  static Future<void> init() async {
    // 1. Data layer (the only place that knows the real implementations).
    final database = AppDatabase(driftDatabase(name: 'study_recorder'));
    final documents = await getApplicationDocumentsDirectory();
    final mediaDir = Directory(p.join(documents.path, 'recordings'));

    final FolderRepositoryInterface folders = FolderRepository(
      database,
      mediaDir,
    );
    final RecordingRepositoryInterface recordings = RecordingRepository(
      database,
      mediaDir,
    );

    // 2. Domain layer.
    instance = AppDependencies.fromRepositories(folders, recordings);
  }
}
