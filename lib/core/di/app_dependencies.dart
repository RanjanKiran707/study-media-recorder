import 'package:drift_flutter/drift_flutter.dart';
import 'package:study_recorder/core/storage/media_storage_provider.dart';
import 'package:study_recorder/data/database/app_database.dart';
import 'package:study_recorder/data/folder/folder_repository.dart';
import 'package:study_recorder/data/folder/folder_repository_interface.dart';
import 'package:study_recorder/data/player/player_repository.dart';
import 'package:study_recorder/data/player/player_repository_interface.dart';
import 'package:study_recorder/data/recorder/recorder_repository.dart';
import 'package:study_recorder/data/recorder/recorder_repository_interface.dart';
import 'package:study_recorder/data/recording/recording_repository.dart';
import 'package:study_recorder/data/recording/recording_repository_interface.dart';
import 'package:study_recorder/domain/use_cases/business/create_folder/create_folder_usecase.dart';
import 'package:study_recorder/domain/use_cases/business/delete_folder/delete_folder_usecase.dart';
import 'package:study_recorder/domain/use_cases/business/delete_recording/delete_recording_usecase.dart';
import 'package:study_recorder/domain/use_cases/business/discard_take/discard_take_usecase.dart';
import 'package:study_recorder/domain/use_cases/business/move_recording/move_recording_usecase.dart';
import 'package:study_recorder/domain/use_cases/business/next_track/next_track_usecase.dart';
import 'package:study_recorder/domain/use_cases/business/pause_player/pause_player_usecase.dart';
import 'package:study_recorder/domain/use_cases/business/pause_recording/pause_recording_usecase.dart';
import 'package:study_recorder/domain/use_cases/business/play_player/play_player_usecase.dart';
import 'package:study_recorder/domain/use_cases/business/play_recording/play_recording_usecase.dart';
import 'package:study_recorder/domain/use_cases/business/prepare_recorder/prepare_recorder_usecase.dart';
import 'package:study_recorder/domain/use_cases/business/previous_track/previous_track_usecase.dart';
import 'package:study_recorder/domain/use_cases/business/release_recorder/release_recorder_usecase.dart';
import 'package:study_recorder/domain/use_cases/business/rename_folder/rename_folder_usecase.dart';
import 'package:study_recorder/domain/use_cases/business/rename_recording/rename_recording_usecase.dart';
import 'package:study_recorder/domain/use_cases/business/resume_recording/resume_recording_usecase.dart';
import 'package:study_recorder/domain/use_cases/business/save_order/save_order_usecase.dart';
import 'package:study_recorder/domain/use_cases/business/save_recording/save_recording_usecase.dart';
import 'package:study_recorder/domain/use_cases/business/seek_player/seek_player_usecase.dart';
import 'package:study_recorder/domain/use_cases/business/set_repeat_all/set_repeat_all_usecase.dart';
import 'package:study_recorder/domain/use_cases/business/start_recording/start_recording_usecase.dart';
import 'package:study_recorder/domain/use_cases/business/skip_to_track/skip_to_track_usecase.dart';
import 'package:study_recorder/domain/use_cases/business/stop_playback/stop_playback_usecase.dart';
import 'package:study_recorder/domain/use_cases/business/stop_recording/stop_recording_usecase.dart';
import 'package:study_recorder/domain/use_cases/business/switch_camera/switch_camera_usecase.dart';
import 'package:study_recorder/domain/use_cases/ui/get_folder_path/get_folder_path_usecase.dart';
import 'package:study_recorder/domain/use_cases/ui/get_playable_recording/get_playable_recording_usecase.dart';
import 'package:study_recorder/domain/use_cases/ui/get_player_video/get_player_video_usecase.dart';
import 'package:study_recorder/domain/use_cases/ui/get_playlist/get_playlist_usecase.dart';
import 'package:study_recorder/domain/use_cases/ui/get_recorder_preview/get_recorder_preview_usecase.dart';
import 'package:study_recorder/domain/use_cases/ui/get_recording_elapsed/get_recording_elapsed_usecase.dart';
import 'package:study_recorder/domain/use_cases/ui/list_folder_items/list_folder_items_usecase.dart';
import 'package:study_recorder/domain/use_cases/ui/list_subfolders/list_subfolders_usecase.dart';
import 'package:study_recorder/domain/use_cases/ui/watch_player/watch_player_usecase.dart';

class AppDependencies {
  // Set once in main() before runApp. Tests can replace it.
  static late AppDependencies instance;

  // Folder and recording use cases.
  final CreateFolderUsecase createFolder;
  final RenameFolderUsecase renameFolder;
  final DeleteFolderUsecase deleteFolder;
  final SaveRecordingUsecase saveRecording;
  final RenameRecordingUsecase renameRecording;
  final MoveRecordingUsecase moveRecording;
  final DeleteRecordingUsecase deleteRecording;
  final SaveOrderUsecase saveOrder;

  // List and path use cases.
  final ListFolderItemsUsecase listFolderItems;
  final ListSubfoldersUsecase listSubfolders;
  final GetFolderPathUsecase getFolderPath;
  final GetPlaylistUsecase getPlaylist;
  final GetPlayableRecordingUsecase getPlayableRecording;

  // Recorder use cases.
  final PrepareRecorderUsecase prepareRecorder;
  final StartRecordingUsecase startRecording;
  final PauseRecordingUsecase pauseRecording;
  final ResumeRecordingUsecase resumeRecording;
  final StopRecordingUsecase stopRecording;
  final SwitchCameraUsecase switchCamera;
  final DiscardTakeUsecase discardTake;
  final ReleaseRecorderUsecase releaseRecorder;
  final GetRecorderPreviewUsecase getRecorderPreview;
  final GetRecordingElapsedUsecase getRecordingElapsed;

  // Player use cases.
  final PlayRecordingUsecase playRecording;
  final PlayPlayerUsecase playPlayer;
  final PausePlayerUsecase pausePlayer;
  final NextTrackUsecase nextTrack;
  final PreviousTrackUsecase previousTrack;
  final SeekPlayerUsecase seekPlayer;
  final SetRepeatAllUsecase setRepeatAll;
  final SkipToTrackUsecase skipToTrack;
  final StopPlaybackUsecase stopPlayback;
  final WatchPlayerUsecase watchPlayer;
  final GetPlayerVideoUsecase getPlayerVideo;

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
    required this.prepareRecorder,
    required this.startRecording,
    required this.pauseRecording,
    required this.resumeRecording,
    required this.stopRecording,
    required this.switchCamera,
    required this.discardTake,
    required this.releaseRecorder,
    required this.getRecorderPreview,
    required this.getRecordingElapsed,
    required this.playRecording,
    required this.playPlayer,
    required this.pausePlayer,
    required this.nextTrack,
    required this.previousTrack,
    required this.seekPlayer,
    required this.setRepeatAll,
    required this.skipToTrack,
    required this.stopPlayback,
    required this.watchPlayer,
    required this.getPlayerVideo,
  });

  /// Builds the use cases on top of the given repositories. Used by [init]
  /// and by tests that want the real use cases on fake repositories.
  factory AppDependencies.fromRepositories(
    FolderRepositoryInterface folders,
    RecordingRepositoryInterface recordings,
    RecorderRepositoryInterface recorder,
    PlayerRepositoryInterface player,
  ) {
    final getPlaylist = GetPlaylistUsecase(folders, recordings);
    final getPlayableRecording = GetPlayableRecordingUsecase(
      folders,
      recordings,
    );
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
      getPlaylist: getPlaylist,
      getPlayableRecording: getPlayableRecording,
      prepareRecorder: PrepareRecorderUsecase(recorder),
      startRecording: StartRecordingUsecase(recorder),
      pauseRecording: PauseRecordingUsecase(recorder),
      resumeRecording: ResumeRecordingUsecase(recorder),
      stopRecording: StopRecordingUsecase(recorder),
      switchCamera: SwitchCameraUsecase(recorder),
      discardTake: DiscardTakeUsecase(recorder),
      releaseRecorder: ReleaseRecorderUsecase(recorder),
      getRecorderPreview: GetRecorderPreviewUsecase(recorder),
      getRecordingElapsed: GetRecordingElapsedUsecase(recorder),
      playRecording: PlayRecordingUsecase(
        getPlayableRecording,
        getPlaylist,
        player,
      ),
      playPlayer: PlayPlayerUsecase(player),
      pausePlayer: PausePlayerUsecase(player),
      nextTrack: NextTrackUsecase(player),
      previousTrack: PreviousTrackUsecase(player),
      seekPlayer: SeekPlayerUsecase(player),
      setRepeatAll: SetRepeatAllUsecase(player),
      skipToTrack: SkipToTrackUsecase(player),
      stopPlayback: StopPlaybackUsecase(player),
      watchPlayer: WatchPlayerUsecase(player),
      getPlayerVideo: GetPlayerVideoUsecase(player),
    );
  }

  static Future<void> init() async {
    // 1. Data layer (the only place that knows the real implementations).
    final database = AppDatabase(
      driftDatabase(
        name: 'study_recorder',
        web: DriftWebOptions(
          sqlite3Wasm: Uri.parse('sqlite3.wasm'),
          driftWorker: Uri.parse('drift_worker.js'),
        ),
      ),
    );
    final storage = await MediaStoragePlatform.create();

    final FolderRepositoryInterface folders = FolderRepository(
      database,
      storage,
    );
    final RecordingRepositoryInterface recordings = RecordingRepository(
      database,
      storage,
    );
    final RecorderRepositoryInterface recorder = RecorderRepository();
    final PlayerRepositoryInterface player = PlayerRepository();

    // 2. Domain layer.
    instance = AppDependencies.fromRepositories(
      folders,
      recordings,
      recorder,
      player,
    );
  }
}
