import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:study_recorder/core/errors/result.dart';
import 'package:study_recorder/core/utils/view_state.dart';
import 'package:study_recorder/domain/use_cases/business/move_recording/move_recording_usecase.dart';
import 'package:study_recorder/domain/use_cases/ui/get_folder_path/get_folder_path_return_model.dart';
import 'package:study_recorder/domain/use_cases/ui/get_folder_path/get_folder_path_usecase.dart';
import 'package:study_recorder/domain/use_cases/ui/list_subfolders/list_subfolders_return_model.dart';
import 'package:study_recorder/domain/use_cases/ui/list_subfolders/list_subfolders_usecase.dart';

/// The recording to move, and the folder it is in now.
class MoveToBundle {
  final String recordingId;
  final String currentFolderId;

  const MoveToBundle({
    required this.recordingId,
    required this.currentFolderId,
  });
}

/// The folder picker: starts at the top level, tapping a folder opens it,
/// "up" goes one level back.
class MoveToViewModel {
  final MoveToBundle bundle;
  final MoveRecordingUsecase _moveRecording;
  final ListSubfoldersUsecase _listSubfolders;
  final GetFolderPathUsecase _getFolderPath;

  /// The folder being looked at. Null is the top level.
  final ValueNotifier<String?> currentFolderId = ValueNotifier(null);

  /// The subfolders of [currentFolderId].
  final ValueNotifier<ViewState<ListSubfoldersReturnModel>> state =
      ValueNotifier(const ViewStateLoading());

  /// The path of [currentFolderId], for the title. Idle at the top level.
  final ValueNotifier<ViewState<GetFolderPathReturnModel>> pathState =
      ValueNotifier(const ViewStateIdle());

  /// State of the move. Loaded means the screen can close.
  final ValueNotifier<ViewState<void>> actionState = ValueNotifier(
    const ViewStateIdle(),
  );

  final List<String?> _history = [];
  StreamSubscription<Result<ListSubfoldersReturnModel>>? _subscription;
  bool _disposed = false;

  MoveToViewModel({
    required this.bundle,
    required MoveRecordingUsecase moveRecording,
    required ListSubfoldersUsecase listSubfolders,
    required GetFolderPathUsecase getFolderPath,
  }) : _moveRecording = moveRecording,
       _listSubfolders = listSubfolders,
       _getFolderPath = getFolderPath {
    _show(null);
  }

  /// Name of the folder being looked at, for the message after moving.
  String? get currentFolderName {
    final path = pathState.value;
    return path is ViewStateLoaded<GetFolderPathReturnModel>
        ? path.data.folders.last.name
        : null;
  }

  bool get isTopLevel => currentFolderId.value == null;

  /// Selecting is not allowed at the top level, or in the folder the
  /// recording is already in.
  bool get canSelect =>
      !isTopLevel &&
      currentFolderId.value != bundle.currentFolderId &&
      !actionState.value.isLoading;

  void _show(String? folderId) {
    currentFolderId.value = folderId;
    state.value = const ViewStateLoading();
    _subscription?.cancel();
    _subscription = _listSubfolders(folderId).listen((result) {
      state.value = result.fold(
        (failure) => ViewStateError(failure),
        (data) => ViewStateLoaded(data),
      );
    });
    _loadPath(folderId);
  }

  Future<void> _loadPath(String? folderId) async {
    if (folderId == null) {
      pathState.value = const ViewStateIdle();
      return;
    }
    pathState.value = const ViewStateLoading();
    final result = await _getFolderPath(folderId);
    // A later navigation or dispose makes this answer stale.
    if (_disposed || currentFolderId.value != folderId) return;
    pathState.value = result.fold(
      (failure) => ViewStateError(failure),
      (path) => ViewStateLoaded(path),
    );
  }

  /// Tapping a folder.
  void onOpenFolder(String folderId) {
    if (actionState.value.isLoading) return;
    _history.add(currentFolderId.value);
    _show(folderId);
  }

  /// The back arrow. Returns true when it went up one level, false when
  /// already at the top level (the View then closes the screen).
  bool onUp() {
    if (actionState.value.isLoading) return true; // blocked, stay here
    if (_history.isEmpty) return false;
    _show(_history.removeLast());
    return true;
  }

  Future<void> onSelect() async {
    if (!canSelect) return;
    actionState.value = const ViewStateLoading();
    final result = await _moveRecording(
      bundle.recordingId,
      currentFolderId.value!,
    );
    actionState.value = result.fold<ViewState<void>>(
      (failure) => ViewStateError(failure),
      (_) => const ViewStateLoaded(null),
    );
  }

  /// Clears an error after the View has shown it.
  void onErrorShown() {
    if (actionState.value is ViewStateError) {
      actionState.value = const ViewStateIdle();
    }
  }

  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    currentFolderId.dispose();
    state.dispose();
    pathState.dispose();
    actionState.dispose();
  }
}
