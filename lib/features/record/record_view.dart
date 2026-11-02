import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:flutter/widgets.dart';
import 'package:study_recorder/core/di/app_dependencies.dart';
import 'package:study_recorder/core/utils/failure_message.dart';
import 'package:study_recorder/core/utils/chrome_controller.dart';
import 'package:study_recorder/core/utils/format.dart';
import 'package:study_recorder/core/utils/view_state.dart';
import 'package:study_recorder/core/widgets/app_buttons.dart';
import 'package:study_recorder/core/widgets/app_chrome.dart';
import 'package:study_recorder/core/widgets/app_controls.dart';
import 'package:study_recorder/core/widgets/app_route.dart';
import 'package:study_recorder/core/widgets/app_sheet.dart';
import 'package:study_recorder/core/widgets/app_theme.dart';
import 'package:study_recorder/core/widgets/app_toast.dart';
import 'package:study_recorder/core/widgets/obx_value.dart';
import 'package:study_recorder/data/recording/recording_model.dart';
import 'package:study_recorder/features/record/record_view_model.dart';
import 'package:study_recorder/features/save_recording/save_recording_view.dart';
import 'package:study_recorder/features/save_recording/save_recording_view_model.dart';

class RecordView extends StatefulWidget {
  final RecordBundle bundle;
  const RecordView({super.key, required this.bundle});

  /// Returns the message to show on the folder screen ("Saved to Physics"),
  /// or null when the user left without a take.
  static Future<String?> open(BuildContext context, RecordBundle bundle) {
    return Navigator.push<String>(
      context,
      appModalRoute((_) => RecordView(bundle: bundle)),
    );
  }

  @override
  State<RecordView> createState() => _RecordViewState();
}

class _RecordViewState extends State<RecordView> {
  late final RecordViewModel ctrl;
  final ChromeController chrome = ChromeController();
  RecordingType? _lastType;
  RecordPhase? _lastPhase;

  @override
  void initState() {
    super.initState();
    final deps = AppDependencies.instance;
    ctrl = RecordViewModel(
      bundle: widget.bundle,
      prepare: deps.prepareRecorder,
      start: deps.startRecording,
      pause: deps.pauseRecording,
      resume: deps.resumeRecording,
      stop: deps.stopRecording,
      switchCamera: deps.switchCamera,
      discardTake: deps.discardTake,
      release: deps.releaseRecorder,
      getPreview: deps.getRecorderPreview,
      getElapsed: deps.getRecordingElapsed,
    );
    ctrl.actionState.addListener(_onActionStateChanged);
    ctrl.finished.addListener(_onFinished);
    ctrl.session.addListener(_onSessionChanged);
  }

  void _onActionStateChanged() {
    final state = ctrl.actionState.value;
    if (state is ViewStateError && mounted) {
      showFailureToast(context, state.failure);
      ctrl.onErrorShown();
    }
  }

  Future<void> _onFinished() async {
    final file = ctrl.finished.value;
    if (file == null || !mounted) return;
    // The Save screen opens on top. Whatever it returns ("Saved to ...",
    // "Recording discarded") closes this screen too and goes to the folder.
    final message = await Navigator.push<String>(
      context,
      appModalRoute(
        (_) => SaveRecordingView(
          bundle: SaveRecordingBundle(
            folderId: widget.bundle.folderId,
            file: file,
          ),
        ),
      ),
    );
    if (mounted) Navigator.pop(context, message);
  }

  @override
  void dispose() {
    ctrl.actionState.removeListener(_onActionStateChanged);
    ctrl.finished.removeListener(_onFinished);
    ctrl.session.removeListener(_onSessionChanged);
    chrome.dispose();
    ctrl.dispose();
    super.dispose();
  }

  /// Back button and the close button.
  Future<void> _leave() async {
    if (ctrl.isBusy) return;
    if (ctrl.session.value.isStarted) {
      final discard = await showConfirmSheet(
        context,
        title: 'Discard this recording?',
        message: 'What you have recorded so far will be lost.',
        confirmLabel: 'Discard',
        destructive: true,
      );
      if (!discard) return;
      await ctrl.onDiscard();
    }
    if (mounted) Navigator.pop(context);
  }

  /// The controls hide by themselves 3 s into a video take. A change of type
  /// or phase (start, pause, resume) brings them back. The timer ticking does
  /// not.
  void _onSessionChanged() {
    final s = ctrl.session.value;
    if (s.type == _lastType && s.phase == _lastPhase) return;
    _lastType = s.type;
    _lastPhase = s.phase;
    chrome.show(autoHide: s.type == RecordingType.video && s.isRecording);
  }

  /// A tap on the picture shows or hides the controls (video only: audio has
  /// nothing to look at, so its controls stay).
  void _onTapPicture() {
    final s = ctrl.session.value;
    if (s.type != RecordingType.video) return;
    if (!chrome.visible.value) {
      chrome.show(autoHide: s.isRecording);
    } else if (s.isRecording) {
      chrome.hide();
    }
  }

  /// Touching a control keeps the controls up for another 3 s.
  void _onTouchControls() {
    final s = ctrl.session.value;
    if (s.type == RecordingType.video && s.isRecording) {
      chrome.show(autoHide: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ObxMulti(
      listenables: [
        ctrl.prepareState,
        ctrl.session,
        ctrl.actionState,
        chrome.visible,
      ],
      builder: () {
        final session = ctrl.session.value;
        final busy = ctrl.isBusy;
        final isVideo = session.type == RecordingType.video;
        final showChrome = chrome.visible.value || !isVideo;
        final fg = isVideo ? AppColors.onDark : AppColors.text;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: isVideo
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.dark,
          child: PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) _leave();
            },
            child: ColoredBox(
              color: isVideo ? const Color(0xFF000000) : AppColors.stage,
              child: DefaultTextStyle(
                style: AppText.base.copyWith(color: fg),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _onTapPicture,
                      child: _stage(session, fg, showChrome),
                    ),
                    if (session.isRecording)
                      IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.record.withAlpha(140),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    AppChromeBar(
                      visible: showChrome,
                      atTop: true,
                      scrim: isVideo,
                      child: Listener(
                        onPointerDown: (_) => _onTouchControls(),
                        child: _topBar(session, busy, fg),
                      ),
                    ),
                    AppChromeBar(
                      visible: showChrome,
                      atTop: false,
                      scrim: isVideo,
                      child: Listener(
                        onPointerDown: (_) => _onTouchControls(),
                        child: _controls(session, busy, fg),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _topBar(RecordSession session, bool busy, Color fg) {
    final isVideo = session.type == RecordingType.video;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        8,
        MediaQuery.paddingOf(context).top + 8,
        12,
        28,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppIconButton(
            icon: CupertinoIcons.xmark,
            label: 'Close',
            color: fg,
            onPressed: busy ? null : _leave,
          ),
          AppPillTabs(
            labels: const ['Video', 'Audio'],
            selected: isVideo ? 0 : 1,
            color: fg,
            indicator: isVideo ? const Color(0x47FFFFFF) : AppColors.onDark,
            onChanged: busy || session.isStarted
                ? null
                : (i) => ctrl.onSelectType(
                    i == 0 ? RecordingType.video : RecordingType.audio,
                  ),
          ),
          if (isVideo)
            AppIconButton(
              icon: CupertinoIcons.camera_rotate,
              label: 'Switch camera',
              color: fg,
              onPressed: ctrl.isBusy || !ctrl.canRecord && !session.isStarted
                  ? null
                  : ctrl.onSwitchCamera,
            )
          else
            const SizedBox(width: 40),
        ],
      ),
    );
  }

  /// The picture (camera or the audio backdrop) with the timer on it.
  Widget _stage(RecordSession session, Color fg, bool showChrome) {
    final isVideo = session.type == RecordingType.video;
    final top = MediaQuery.paddingOf(context).top;
    return Stack(
      fit: StackFit.expand,
      children: [
        ctrl.prepareState.value.when(
          idle: () => const SizedBox.shrink(),
          loading: () => const Center(child: AppSpinner()),
          error: (failure) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(messageFor(failure), textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  AppButton(
                    label: 'Try again',
                    style: AppButtonStyle.ghost,
                    onPressed: ctrl.onRetryPrepare,
                  ),
                ],
              ),
            ),
          ),
          loaded: (_) => Stack(
            fit: StackFit.expand,
            children: [
              if (isVideo)
                Positioned.fill(
                  child: IgnorePointer(child: ctrl.buildPreview() ?? const SizedBox.shrink()),
                ),
              if (isVideo)
                Positioned(
                  top: top + 64,
                  left: 0,
                  right: 0,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: IgnorePointer(child: _timerPill(session)),
                  ),
                )
              else
                Center(child: _timer(session)),
            ],
          ),
        ),
        Positioned(
          top: top + 70,
          left: 20,
          child: AnimatedOpacity(
            opacity: showChrome ? 0.75 : 0,
            duration: const Duration(milliseconds: 250),
            child: Text(
              isVideo ? 'Camera' : 'Microphone only',
              style: AppText.rowSubtitle.copyWith(color: fg),
            ),
          ),
        ),
      ],
    );
  }

  String _status(RecordSession session) => switch (session.phase) {
    RecordPhase.ready => 'Ready',
    RecordPhase.recording => 'Recording',
    RecordPhase.paused => 'Paused',
  };

  Widget _recordDot() => Container(
    width: 7,
    height: 7,
    margin: const EdgeInsets.only(right: 6),
    decoration: const BoxDecoration(
      color: AppColors.record,
      shape: BoxShape.circle,
    ),
  );

  /// Over the camera: a small pill, so the picture stays clear.
  Widget _timerPill(RecordSession session) {
    const style = TextStyle(
      color: AppColors.onDark,
      fontSize: 15,
      fontWeight: FontWeight.w500,
      decoration: TextDecoration.none,
      fontFeatures: [FontFeature.tabularFigures()],
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x80000000),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            formatClock(session.elapsed),
            key: const Key('record-timer'),
            style: style,
          ),
          const SizedBox(width: 8),
          if (session.isRecording) _recordDot(),
          Text(
            _status(session),
            style: style.copyWith(
              color: const Color(0xBFFFFFFF),
              fontWeight: FontWeight.w400,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  /// Audio: the big timer in the middle.
  Widget _timer(RecordSession session) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          formatClock(session.elapsed),
          key: const Key('record-timer'),
          style: AppText.timer,
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (session.isRecording) _recordDot(),
            Text(_status(session), style: AppText.rowSubtitle),
          ],
        ),
      ],
    );
  }

  Widget _controls(RecordSession session, bool busy, Color fg) {
    final started = session.isStarted;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        0,
        40,
        0,
        MediaQuery.paddingOf(context).bottom + 30,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppIconButton(
            key: const Key('record-pause'),
            icon: session.isPaused
                ? CupertinoIcons.play_fill
                : CupertinoIcons.pause_fill,
            label: session.isPaused ? 'Resume' : 'Pause',
            size: 56,
            iconSize: 28,
            color: fg,
            onPressed: started && !busy ? ctrl.onPauseResume : null,
          ),
          const SizedBox(width: 36),
          AppPressable(
            onPressed: busy || !(started || ctrl.canRecord)
                ? null
                : started
                ? ctrl.onDone
                : ctrl.onStart,
            semanticLabel: started ? 'Stop recording' : 'Start recording',
            child: Container(
              key: const Key('record-start'),
              width: 70,
              height: 70,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: fg, width: 3),
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: started ? 24 : 52,
                height: started ? 24 : 52,
                decoration: BoxDecoration(
                  color: AppColors.record,
                  borderRadius: BorderRadius.circular(started ? 6 : 26),
                ),
              ),
            ),
          ),
          const SizedBox(width: 36),
          AppIconButton(
            key: const Key('record-done'),
            icon: CupertinoIcons.checkmark_alt,
            label: 'Done',
            size: 56,
            iconSize: 30,
            color: fg,
            onPressed: started && !busy ? ctrl.onDone : null,
          ),
        ],
      ),
    );
  }
}
