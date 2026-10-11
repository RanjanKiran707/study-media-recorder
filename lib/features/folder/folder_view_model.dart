import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:study_recorder/core/errors/failure.dart';
import 'package:study_recorder/core/errors/result.dart';
import 'package:study_recorder/core/utils/generate_id.dart';
import 'package:study_recorder/core/utils/view_state.dart';
import 'package:study_recorder/domain/use_cases/business/create_folder/create_folder_argument_model.dart';
import 'package:study_recorder/domain/use_cases/business/create_folder/create_folder_usecase.dart';
import 'package:study_recorder/domain/use_cases/business/delete_folder/delete_folder_usecase.dart';
import 'package:study_recorder/domain/use_cases/business/delete_recording/delete_recording_usecase.dart';
import 'package:study_recorder/domain/use_cases/business/play_recording/play_recording_usecase.dart';
import 'package:study_recorder/domain/use_cases/business/rename_folder/rename_folder_usecase.dart';
import 'package:study_recorder/domain/use_cases/business/rename_recording/rename_recording_usecase.dart';
import 'package:study_recorder/domain/use_cases/business/save_order/ordered_item.dart';
import 'package:study_recorder/domain/use_cases/business/save_order/save_order_usecase.dart';
import 'package:study_recorder/domain/use_cases/ui/get_folder_path/get_folder_path_return_model.dart';
import 'package:study_recorder/domain/use_cases/ui/get_folder_path/get_folder_path_usecase.dart';
import 'package:study_recorder/domain/use_cases/ui/list_folder_items/list_folder_items_return_model.dart';
import 'package:study_recorder/domain/use_cases/ui/list_folder_items/list_folder_items_usecase.dart';
import 'package:study_recorder/domain/use_cases/ui/watch_player/watch_player_return_model.dart';
import 'package:study_recorder/domain/use_cases/ui/watch_player/watch_player_usecase.dart';

/// [folderId] null is the Home screen (top-level folders only).
class FolderBundle {
  final String? folderId;
  const FolderBundle({this.folderId});
}

class FolderViewModel {
  final FolderBundle bundle;
  final CreateFolderUsecase _createFolder;
  final RenameFolderUsecase _renameFolder;
  final DeleteFolderUsecase _deleteFolder;
  final RenameRecordingUsecase _renameRecording;
  final DeleteRecordingUsecase _deleteRecording;
  final SaveOrderUsecase _saveOrder;
  final PlayRecordingUsecase _playRecording;
  final GetFolderPathUsecase _getFolderPath;
  final ListFolderItemsUsecase _listFolderItems;
  final WatchPlayerUsecase _watchPlayer;
  final String Function() _newId;

  /// The list of this folder. Live: it changes when the data changes.
  final ValueNotifier<ViewState<ListFolderItemsReturnModel>> state =
      ValueNotifier(const ViewStateLoading());

  /// The breadcrumb ("Physics / Mechanics"). Idle on Home.
  final ValueNotifier<ViewState<GetFolderPathReturnModel>> pathState =
      ValueNotifier(const ViewStateIdle());

  /// State of the last action: create, rename, delete or save order.
  final ValueNotifier<ViewState<void>> actionState = ValueNotifier(
    const ViewStateIdle(),
  );

  /// State of starting playback of a tapped recording. Loaded means the player
  /// is playing, and the View opens it.
  final ValueNotifier<ViewState<void>> playState = ValueNotifier(
    const ViewStateIdle(),
  );

  /// The recording that is playing now, to mark its row. Null when none.
  final ValueNotifier<String?> playingRecordingId = ValueNotifier(null);

  /// The list being rearranged, or null when not in rearrange mode.
  final ValueNotifier<List<FolderItem>?> rearrangeItems = ValueNotifier(null);

  StreamSubscription<Result<ListFolderItemsReturnModel>>? _subscription;
  StreamSubscription<Result<WatchPlayerReturnModel>>? _playerSubscription;
  bool _disposed = false;

  FolderViewModel({
    required this.bundle,
    required CreateFolderUsecase createFolder,
    required RenameFolderUsecase renameFolder,
    required DeleteFolderUsecase deleteFolder,
    required RenameRecordingUsecase renameRecording,
    required DeleteRecordingUsecase deleteRecording,
    required SaveOrderUsecase saveOrder,
    required PlayRecordingUsecase playRecording,
    required GetFolderPathUsecase getFolderPath,
    required ListFolderItemsUsecase listFolderItems,
    required WatchPlayerUsecase watchPlayer,
    String Function() newId = generateId,
  }) : _createFolder = createFolder,
       _renameFolder = renameFolder,
       _deleteFolder = deleteFolder,
       _renameRecording = renameRecording,
       _deleteRecording = deleteRecording,
       _saveOrder = saveOrder,
       _playRecording = playRecording,
       _getFolderPath = getFolderPath,
       _listFolderItems = listFolderItems,
       _watchPlayer = watchPlayer,
       _newId = newId {
    _subscription = _listFolderItems(bundle.folderId).listen((result) {
      state.value = result.fold(
        (failure) => ViewStateError(failure),
        (data) => ViewStateLoaded(data),
      );
    });
    _playerSubscription = _watchPlayer().listen((result) {
      result.fold((_) {}, (player) {
        final id = player.isActive && player.playing
            ? player.recordingId
            : null;
        if (playingRecordingId.value != id) playingRecordingId.value = id;
      });
    });
    _loadPath();
  }

  bool get isHome => bundle.folderId == null;

  bool get isRearranging => rearrangeItems.value != null;

  Future<void> _loadPath() async {
    final folderId = bundle.folderId;
    if (folderId == null) return;
    pathState.value = const ViewStateLoading();
    final result = await _getFolderPath(folderId);
    if (_disposed) return; // the path load does not block leaving the screen
    pathState.value = result.fold(
      (failure) => ViewStateError(failure),
      (path) => ViewStateLoaded(path),
    );
  }

  Future<bool> onCreateFolder(String name) {
    return _run(
      () => _createFolder(
        CreateFolderArgumentModel(
          folderId: _newId(),
          parentId: bundle.folderId,
          name: name,
        ),
      ),
    );
  }

  Future<bool> onRenameFolder(String folderId, String name) =>
      _run(() => _renameFolder(folderId, name));

  Future<bool> onDeleteFolder(String folderId) =>
      _run(() => _deleteFolder(folderId));

  Future<bool> onRenameRecording(String recordingId, String title) =>
      _run(() => _renameRecording(recordingId, title));

  Future<bool> onDeleteRecording(String recordingId) =>
      _run(() => _deleteRecording(recordingId));

  /// True while any action or play request is running (blocking rule).
  bool get isBusy => actionState.value.isLoading || playState.value.isLoading;

  /// Tapping a recording plays it, with the whole folder as the queue.
  Future<void> onPlayRecording(String recordingId) =>
      _play(() => _playRecording(recordingId));

  Future<void> _play(Future<Result<void>> Function() action) async {
    if (isBusy) return; // ignore re-entry
    playState.value = const ViewStateLoading();
    final result = await action();
    playState.value = result.fold<ViewState<void>>(
      (failure) => ViewStateError(failure),
      (_) => const ViewStateLoaded(null),
    );
  }

  /// Clears an error after the View has shown it, and the play request after
  /// the player was opened.
  void onErrorShown() {
    if (actionState.value is ViewStateError) {
      actionState.value = const ViewStateIdle();
    }
  }

  void onPlayHandled() {
    if (!playState.value.isLoading) playState.value = const ViewStateIdle();
  }

  // Rearranging.

  /// Starts rearranging a copy of the current list. Not available on Home.
  void onStartRearrange() {
    if (isHome || isRearranging || isBusy) return;
    final current = state.value;
    if (current is! ViewStateLoaded<ListFolderItemsReturnModel>) return;
    rearrangeItems.value = List.of(current.data.items);
  }

  /// [newIndex] is the index given by `ReorderableListView.onReorder`.
  void onReorder(int oldIndex, int newIndex) {
    final items = rearrangeItems.value;
    if (items == null || actionState.value.isLoading) return;
    final target = newIndex > oldIndex ? newIndex - 1 : newIndex;
    final moved = List.of(items);
    moved.insert(target, moved.removeAt(oldIndex));
    rearrangeItems.value = moved;
  }

  void onCancelRearrange() {
    if (actionState.value.isLoading) return;
    rearrangeItems.value = null;
  }

  Future<bool> onSaveRearrange() async {
    final items = rearrangeItems.value;
    if (items == null) return false;
    final saved = await _run(
      () => _saveOrder([
        for (final item in items)
          OrderedItem(
            id: item.id,
            kind: item is FolderListItem
                ? OrderedItemKind.folder
                : OrderedItemKind.recording,
          ),
      ]),
    );
    if (saved) rearrangeItems.value = null;
    return saved;
  }

  /// Runs one action under the blocking rule. Returns true when it succeeded.
  Future<bool> _run(Future<Result<void>> Function() action) async {
    if (isBusy) return false; // ignore re-entry
    actionState.value = const ViewStateLoading();
    final result = await action();
    actionState.value = result.fold<ViewState<void>>(
      (Failure failure) => ViewStateError(failure),
      (_) => const ViewStateLoaded(null),
    );
    return result is Ok<void>;
  }

  void dispose() {
    _disposed = true;
    _subscription?.cancel(); // first, so no event arrives after dispose
    _playerSubscription?.cancel();
    playingRecordingId.dispose();
    state.dispose();
    pathState.dispose();
    actionState.dispose();
    playState.dispose();
    rearrangeItems.dispose();
  }
}
