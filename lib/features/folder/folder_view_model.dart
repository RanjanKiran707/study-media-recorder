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
import 'package:study_recorder/domain/use_cases/business/rename_folder/rename_folder_usecase.dart';
import 'package:study_recorder/domain/use_cases/business/rename_recording/rename_recording_usecase.dart';
import 'package:study_recorder/domain/use_cases/business/save_order/ordered_item.dart';
import 'package:study_recorder/domain/use_cases/business/save_order/save_order_usecase.dart';
import 'package:study_recorder/domain/use_cases/ui/get_folder_path/get_folder_path_return_model.dart';
import 'package:study_recorder/domain/use_cases/ui/get_folder_path/get_folder_path_usecase.dart';
import 'package:study_recorder/domain/use_cases/ui/list_folder_items/list_folder_items_return_model.dart';
import 'package:study_recorder/domain/use_cases/ui/list_folder_items/list_folder_items_usecase.dart';

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
  final GetFolderPathUsecase _getFolderPath;
  final ListFolderItemsUsecase _listFolderItems;
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

  /// The list being rearranged, or null when not in rearrange mode.
  final ValueNotifier<List<FolderItem>?> rearrangeItems = ValueNotifier(null);

  StreamSubscription<Result<ListFolderItemsReturnModel>>? _subscription;
  bool _disposed = false;

  FolderViewModel({
    required this.bundle,
    required CreateFolderUsecase createFolder,
    required RenameFolderUsecase renameFolder,
    required DeleteFolderUsecase deleteFolder,
    required RenameRecordingUsecase renameRecording,
    required DeleteRecordingUsecase deleteRecording,
    required SaveOrderUsecase saveOrder,
    required GetFolderPathUsecase getFolderPath,
    required ListFolderItemsUsecase listFolderItems,
    String Function() newId = generateId,
  }) : _createFolder = createFolder,
       _renameFolder = renameFolder,
       _deleteFolder = deleteFolder,
       _renameRecording = renameRecording,
       _deleteRecording = deleteRecording,
       _saveOrder = saveOrder,
       _getFolderPath = getFolderPath,
       _listFolderItems = listFolderItems,
       _newId = newId {
    _subscription = _listFolderItems(bundle.folderId).listen((result) {
      state.value = result.fold(
        (failure) => ViewStateError(failure),
        (data) => ViewStateLoaded(data),
      );
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

  Future<void> onCreateFolder(String name) {
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

  Future<void> onRenameFolder(String folderId, String name) =>
      _run(() => _renameFolder(folderId, name));

  Future<void> onDeleteFolder(String folderId) =>
      _run(() => _deleteFolder(folderId));

  Future<void> onRenameRecording(String recordingId, String title) =>
      _run(() => _renameRecording(recordingId, title));

  Future<void> onDeleteRecording(String recordingId) =>
      _run(() => _deleteRecording(recordingId));

  /// Clears an error after the View has shown it.
  void onErrorShown() {
    if (actionState.value is ViewStateError) {
      actionState.value = const ViewStateIdle();
    }
  }

  // Rearranging.

  /// Starts rearranging a copy of the current list. Not available on Home.
  void onStartRearrange() {
    if (isHome || isRearranging || actionState.value.isLoading) return;
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

  Future<void> onSaveRearrange() async {
    final items = rearrangeItems.value;
    if (items == null) return;
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
  }

  /// Runs one action under the blocking rule. Returns true when it succeeded.
  Future<bool> _run(Future<Result<void>> Function() action) async {
    if (actionState.value.isLoading) return false; // ignore re-entry
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
    state.dispose();
    pathState.dispose();
    actionState.dispose();
    rearrangeItems.dispose();
  }
}
