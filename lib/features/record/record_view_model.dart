import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:study_recorder/core/errors/result.dart';
import 'package:study_recorder/core/utils/view_state.dart';
import 'package:study_recorder/data/recorder/recorder_repository_interface.dart';
import 'package:study_recorder/data/recording/recording_model.dart';
import 'package:study_recorder/domain/use_cases/business/discard_take/discard_take_usecase.dart';
import 'package:study_recorder/domain/use_cases/business/pause_recording/pause_recording_usecase.dart';
import 'package:study_recorder/domain/use_cases/business/prepare_recorder/prepare_recorder_usecase.dart';
import 'package:study_recorder/domain/use_cases/business/release_recorder/release_recorder_usecase.dart';
import 'package:study_recorder/domain/use_cases/business/resume_recording/resume_recording_usecase.dart';
import 'package:study_recorder/domain/use_cases/business/start_recording/start_recording_usecase.dart';
import 'package:study_recorder/domain/use_cases/business/stop_recording/stop_recording_usecase.dart';
import 'package:study_recorder/domain/use_cases/business/switch_camera/switch_camera_usecase.dart';
import 'package:study_recorder/domain/use_cases/ui/get_recorder_preview/get_recorder_preview_usecase.dart';
import 'package:study_recorder/domain/use_cases/ui/get_recording_elapsed/get_recording_elapsed_usecase.dart';

/// The recording goes into [folderId].
class RecordBundle {
  final String folderId;
  const RecordBundle({required this.folderId});
}

enum RecordPhase { ready, recording, paused }

/// What the Record screen shows besides the camera: one immutable object.
class RecordSession {
  final RecordingType type;
  final RecordPhase phase;
  final Duration elapsed;

  const RecordSession({
    required this.type,
    required this.phase,
    this.elapsed = Duration.zero,
  });

  bool get isRecording => phase == RecordPhase.recording;
  bool get isPaused => phase == RecordPhase.paused;
  bool get isStarted => phase != RecordPhase.ready;

  RecordSession copyWith({
    RecordingType? type,
    RecordPhase? phase,
    Duration? elapsed,
  }) {
    return RecordSession(
      type: type ?? this.type,
      phase: phase ?? this.phase,
      elapsed: elapsed ?? this.elapsed,
    );
  }
}

class RecordViewModel {
  final RecordBundle bundle;
  final PrepareRecorderUsecase _prepare;
  final StartRecordingUsecase _start;
  final PauseRecordingUsecase _pause;
  final ResumeRecordingUsecase _resume;
  final StopRecordingUsecase _stop;
  final SwitchCameraUsecase _switchCamera;
  final DiscardTakeUsecase _discardTake;
  final ReleaseRecorderUsecase _release;
  final GetRecorderPreviewUsecase _getPreview;
  final GetRecordingElapsedUsecase _getElapsed;
  final Duration _tick;

  /// Opening the camera or microphone (and asking for permission).
  final ValueNotifier<ViewState<void>> prepareState = ValueNotifier(
    const ViewStateIdle(),
  );

  final ValueNotifier<RecordSession> session = ValueNotifier(
    const RecordSession(type: RecordingType.video, phase: RecordPhase.ready),
  );

  /// State of start, pause, resume, done and switch camera.
  final ValueNotifier<ViewState<void>> actionState = ValueNotifier(
    const ViewStateIdle(),
  );

  /// Set when the take was stopped. The View then opens the Save screen.
  final ValueNotifier<RecordedFile?> finished = ValueNotifier(null);

  Timer? _timer;

  RecordViewModel({
    required this.bundle,
    required PrepareRecorderUsecase prepare,
    required StartRecordingUsecase start,
    required PauseRecordingUsecase pause,
    required ResumeRecordingUsecase resume,
    required StopRecordingUsecase stop,
    required SwitchCameraUsecase switchCamera,
    required DiscardTakeUsecase discardTake,
    required ReleaseRecorderUsecase release,
    required GetRecorderPreviewUsecase getPreview,
    required GetRecordingElapsedUsecase getElapsed,
    Duration tick = const Duration(milliseconds: 250),
  }) : _prepare = prepare,
       _start = start,
       _pause = pause,
       _resume = resume,
       _stop = stop,
       _switchCamera = switchCamera,
       _discardTake = discardTake,
       _release = release,
       _getPreview = getPreview,
       _getElapsed = getElapsed,
       _tick = tick {
    _prepareFor(session.value.type);
  }

  bool get isBusy =>
      prepareState.value.isLoading || actionState.value.isLoading;

  /// The camera preview. Null for audio.
  Widget? buildPreview() => _getPreview();

  Future<void> _prepareFor(RecordingType type) async {
    if (prepareState.value.isLoading) return;
    prepareState.value = const ViewStateLoading();
    final result = await _prepare(type);
    prepareState.value = result.fold<ViewState<void>>(
      (failure) => ViewStateError(failure),
      (_) => const ViewStateLoaded(null),
    );
  }

  /// Try again after the preparation failed (for example after allowing the
  /// permission).
  Future<void> onRetryPrepare() => _prepareFor(session.value.type);

  /// Video or Audio. Only before the take has started.
  Future<void> onSelectType(RecordingType type) async {
    if (isBusy || session.value.isStarted) return;
    if (type == session.value.type) return;
    session.value = session.value.copyWith(type: type);
    await _prepareFor(type);
  }

  bool get canRecord => prepareState.value is ViewStateLoaded<void> && !isBusy;

  Future<void> onStart() async {
    if (!canRecord || session.value.isStarted) return;
    final ok = await _run(_start.call);
    if (!ok) return;
    session.value = session.value.copyWith(phase: RecordPhase.recording);
    _startTimer();
  }

  Future<void> onPauseResume() async {
    if (isBusy || !session.value.isStarted) return;
    if (session.value.isRecording) {
      final ok = await _run(_pause.call);
      if (!ok) return;
      _stopTimer();
      session.value = session.value.copyWith(
        phase: RecordPhase.paused,
        elapsed: _getElapsed(),
      );
    } else {
      final ok = await _run(_resume.call);
      if (!ok) return;
      session.value = session.value.copyWith(phase: RecordPhase.recording);
      _startTimer();
    }
  }

  /// "Done": stops the take. [finished] is set on success.
  Future<void> onDone() async {
    if (isBusy || !session.value.isStarted) return;
    _stopTimer();
    if (actionState.value.isLoading) return;
    actionState.value = const ViewStateLoading();
    final result = await _stop();
    actionState.value = result.fold<ViewState<void>>(
      (failure) => ViewStateError(failure),
      (_) => const ViewStateLoaded(null),
    );
    if (result is Ok<RecordedFile>) {
      await _release(); // the take is in a file now: free the camera
      finished.value = result.value;
    }
  }

  Future<void> onSwitchCamera() async {
    if (isBusy || session.value.type != RecordingType.video) return;
    await _run(_switchCamera.call);
  }

  /// Throws the take away (if one was started) and leaves it to the View to
  /// close the screen.
  Future<void> onDiscard() async {
    if (actionState.value.isLoading) return;
    _stopTimer();
    if (session.value.isStarted) {
      actionState.value = const ViewStateLoading();
      final result = await _stop();
      if (result is Ok<RecordedFile>) await _discardTake(result.value.path);
      session.value = session.value.copyWith(
        phase: RecordPhase.ready,
        elapsed: Duration.zero,
      );
      actionState.value = const ViewStateIdle();
    }
  }

  /// Clears an error after the View has shown it.
  void onErrorShown() {
    if (actionState.value is ViewStateError) {
      actionState.value = const ViewStateIdle();
    }
  }

  Future<bool> _run(Future<Result<void>> Function() action) async {
    if (actionState.value.isLoading) return false; // ignore re-entry
    actionState.value = const ViewStateLoading();
    final result = await action();
    actionState.value = result.fold<ViewState<void>>(
      (failure) => ViewStateError(failure),
      (_) => const ViewStateLoaded(null),
    );
    return result is Ok<void>;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(_tick, (_) {
      session.value = session.value.copyWith(elapsed: _getElapsed());
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    _stopTimer();
    _release(); // the temporary file stays: Save or Discard handles it
    prepareState.dispose();
    session.dispose();
    actionState.dispose();
    finished.dispose();
  }
}
