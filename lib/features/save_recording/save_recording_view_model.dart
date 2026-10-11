import 'package:flutter/foundation.dart';
import 'package:study_recorder/core/utils/generate_id.dart';
import 'package:study_recorder/core/utils/view_state.dart';
import 'package:study_recorder/data/recorder/recorder_repository_interface.dart';
import 'package:study_recorder/domain/use_cases/business/discard_take/discard_take_usecase.dart';
import 'package:study_recorder/domain/use_cases/business/save_recording/save_recording_argument_model.dart';
import 'package:study_recorder/domain/use_cases/business/save_recording/save_recording_usecase.dart';
import 'package:study_recorder/domain/use_cases/ui/get_folder_path/get_folder_path_return_model.dart';
import 'package:study_recorder/domain/use_cases/ui/get_folder_path/get_folder_path_usecase.dart';

/// The take to save, and the folder the user started recording from.
class SaveRecordingBundle {
  final String folderId;
  final RecordedFile file;

  const SaveRecordingBundle({required this.folderId, required this.file});
}

class SaveRecordingViewModel {
  final SaveRecordingBundle bundle;
  final SaveRecordingUsecase _save;
  final DiscardTakeUsecase _discardTake;
  final GetFolderPathUsecase _getFolderPath;
  final String Function() _newId;
  bool _disposed = false;

  /// "Saving to Physics / Mechanics".
  final ValueNotifier<ViewState<GetFolderPathReturnModel>> pathState =
      ValueNotifier(const ViewStateLoading());

  /// State of Save or Discard. Loaded means the screen can close.
  final ValueNotifier<ViewState<void>> actionState = ValueNotifier(
    const ViewStateIdle(),
  );

  SaveRecordingViewModel({
    required this.bundle,
    required SaveRecordingUsecase save,
    required DiscardTakeUsecase discardTake,
    required GetFolderPathUsecase getFolderPath,
    String Function() newId = generateId,
  }) : _save = save,
       _discardTake = discardTake,
       _getFolderPath = getFolderPath,
       _newId = newId {
    _loadPath();
  }

  Future<void> _loadPath() async {
    final result = await _getFolderPath(bundle.folderId);
    if (_disposed) return; // the path load does not block leaving
    pathState.value = result.fold(
      (failure) => ViewStateError(failure),
      (path) => ViewStateLoaded(path),
    );
  }

  Future<void> onSave(String title) async {
    if (actionState.value.isLoading) return; // blocking rule: ignore re-entry
    actionState.value = const ViewStateLoading();
    final result = await _save(
      SaveRecordingArgumentModel(
        recordingId: _newId(),
        folderId: bundle.folderId,
        title: title,
        type: bundle.file.type,
        sourcePath: bundle.file.path,
        durationMs: bundle.file.durationMs,
      ),
    );
    actionState.value = result.fold<ViewState<void>>(
      (failure) => ViewStateError(failure),
      (_) => const ViewStateLoaded(null),
    );
  }

  /// Deletes the temporary file. The take is gone for good.
  Future<void> onDiscard() async {
    if (actionState.value.isLoading) return;
    actionState.value = const ViewStateLoading();
    final result = await _discardTake(bundle.file.path);
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
    pathState.dispose();
    actionState.dispose();
  }
}
