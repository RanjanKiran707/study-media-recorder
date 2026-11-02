import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:flutter/widgets.dart';
import 'package:study_recorder/core/di/app_dependencies.dart';
import 'package:study_recorder/core/utils/chrome_controller.dart';
import 'package:study_recorder/core/utils/failure_message.dart';
import 'package:study_recorder/core/utils/format.dart';
import 'package:study_recorder/core/utils/view_state.dart';
import 'package:study_recorder/core/widgets/app_buttons.dart';
import 'package:study_recorder/core/widgets/app_chrome.dart';
import 'package:study_recorder/core/widgets/app_controls.dart';
import 'package:study_recorder/core/widgets/app_route.dart';
import 'package:study_recorder/core/widgets/app_row.dart';
import 'package:study_recorder/core/widgets/app_sheet.dart';
import 'package:study_recorder/core/widgets/app_theme.dart';
import 'package:study_recorder/core/widgets/app_toast.dart';
import 'package:study_recorder/core/widgets/obx_value.dart';
import 'package:study_recorder/data/recording/recording_model.dart';
import 'package:study_recorder/domain/use_cases/ui/watch_player/watch_player_return_model.dart';
import 'package:study_recorder/features/player/player_view_model.dart';

/// The full-screen player: the video fills the screen and the controls show
/// when it is tapped. Back minimises it (playback continues). The ✕ button
/// stops playback and closes it.
class PlayerView extends StatefulWidget {
  const PlayerView({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.push(
      context,
      appModalRoute<void>((_) => const PlayerView()),
    );
  }

  @override
  State<PlayerView> createState() => _PlayerViewState();
}

class _PlayerViewState extends State<PlayerView> {
  late final PlayerViewModel ctrl;
  final ChromeController chrome = ChromeController();
  String? _lastRecordingId;
  bool? _lastPlaying;

  @override
  void initState() {
    super.initState();
    final deps = AppDependencies.instance;
    ctrl = PlayerViewModel(
      watchPlayer: deps.watchPlayer,
      play: deps.playPlayer,
      pause: deps.pausePlayer,
      next: deps.nextTrack,
      previous: deps.previousTrack,
      seek: deps.seekPlayer,
      setRepeatAll: deps.setRepeatAll,
      skipTo: deps.skipToTrack,
      stop: deps.stopPlayback,
      getVideo: deps.getPlayerVideo,
    );
    ctrl.state.addListener(_onStateChanged);
    ctrl.actionState.addListener(_onActionStateChanged);
  }

  void _onStateChanged() {
    final state = ctrl.state.value;
    if (state is ViewStateLoaded<WatchPlayerReturnModel>) {
      _syncChrome(state.data);
    }
    // Stopped (the ✕ button, or from elsewhere): nothing left to show.
    if (state is ViewStateLoaded<WatchPlayerReturnModel> &&
        !state.data.isActive &&
        mounted) {
      Navigator.maybePop(context);
    }
  }

  void _onActionStateChanged() {
    final state = ctrl.actionState.value;
    if (state is ViewStateError && mounted) {
      showFailureToast(context, state.failure);
      ctrl.onErrorShown();
    }
  }

  @override
  void dispose() {
    ctrl.state.removeListener(_onStateChanged);
    ctrl.actionState.removeListener(_onActionStateChanged);
    chrome.dispose();
    ctrl.dispose();
    super.dispose();
  }

  /// The controls hide by themselves 3 s after a video starts playing. A new
  /// recording or play/pause brings them back. Progress ticks do not.
  void _syncChrome(WatchPlayerReturnModel data) {
    if (!data.isActive) return;
    if (data.recordingId == _lastRecordingId && data.playing == _lastPlaying) {
      return;
    }
    _lastRecordingId = data.recordingId;
    _lastPlaying = data.playing;
    chrome.show(autoHide: data.type == RecordingType.video && data.playing);
  }

  WatchPlayerReturnModel? get _data {
    final state = ctrl.state.value;
    return state is ViewStateLoaded<WatchPlayerReturnModel> &&
            state.data.isActive
        ? state.data
        : null;
  }

  /// A tap on the picture shows or hides the controls (video only: audio has
  /// nothing to look at, so its controls stay).
  void _onTapPicture() {
    final data = _data;
    if (data == null || data.type != RecordingType.video) return;
    if (!chrome.visible.value) {
      chrome.show(autoHide: data.playing);
    } else if (data.playing) {
      chrome.hide();
    }
  }

  /// Touching a control keeps the controls up for another 3 s.
  void _onTouchControls() {
    final data = _data;
    if (data != null && data.type == RecordingType.video && data.playing) {
      chrome.show(autoHide: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ObxMulti(
      listenables: [ctrl.actionState, ctrl.state, chrome.visible],
      builder: () {
        final data = _data;
        final isVideo = data?.type == RecordingType.video;
        final showChrome = chrome.visible.value || !isVideo;
        final fg = isVideo ? AppColors.onDark : AppColors.text;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: isVideo
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.dark,
          child: PopScope(
            canPop: !ctrl.actionState.value.isLoading,
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
                      child: _stage(data),
                    ),
                    AppChromeBar(
                      visible: showChrome,
                      atTop: true,
                      scrim: isVideo,
                      child: Listener(
                        onPointerDown: (_) => _onTouchControls(),
                        child: _topBar(data, fg),
                      ),
                    ),
                    if (data != null)
                      AppChromeBar(
                        visible: showChrome,
                        atTop: false,
                        scrim: isVideo,
                        child: Listener(
                          onPointerDown: (_) => _onTouchControls(),
                          child: _bottom(data, fg, isVideo),
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

  Widget _topBar(WatchPlayerReturnModel? data, Color fg) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        8,
        MediaQuery.paddingOf(context).top + 8,
        12,
        28,
      ),
      child: Row(
        children: [
          AppIconButton(
            icon: CupertinoIcons.chevron_down,
            label: 'Minimise',
            color: fg,
            onPressed: () => Navigator.maybePop(context),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Text(
              data?.folderName ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.rowSubtitle.copyWith(
                color: fg.withValues(alpha: 0.8),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          AppIconButton(
            icon: CupertinoIcons.xmark,
            label: 'Stop and close',
            color: fg,
            onPressed: ctrl.onStop,
          ),
        ],
      ),
    );
  }

  /// The picture: the video, or the equalizer for audio.
  Widget _stage(WatchPlayerReturnModel? data) {
    final state = ctrl.state.value;
    if (data == null) {
      return state.when(
        loading: () => const Center(child: AppSpinner()),
        error: (failure) => Center(child: Text(messageFor(failure))),
        loaded: (_) => const SizedBox.shrink(),
      );
    }
    if (data.type == RecordingType.video) {
      return Center(child: IgnorePointer(child: ctrl.buildVideo() ?? const SizedBox.shrink()));
    }
    return Center(child: AppEqualizer(active: data.playing));
  }

  Widget _bottom(WatchPlayerReturnModel data, Color fg, bool isVideo) {
    final kind = data.type == RecordingType.video ? 'Video' : 'Audio';
    return Padding(
      padding: EdgeInsets.fromLTRB(
        0,
        48,
        0,
        MediaQuery.paddingOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$kind · ${data.number} of ${data.count}',
                  key: const Key('player-kind'),
                  style: AppText.small.copyWith(
                    color: fg.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  data.title,
                  key: const Key('player-title'),
                  style: AppText.nowPlaying.copyWith(fontSize: 24, color: fg),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 12, 28, 0),
            child: _seekBar(data, fg),
          ),
          _transport(data, fg, isVideo),
        ],
      ),
    );
  }

  Widget _seekBar(WatchPlayerReturnModel data, Color fg) {
    final timeStyle = AppText.small.copyWith(color: fg.withValues(alpha: 0.75));
    return ObxValue<double?>(
      listenable: ctrl.seekPreview,
      builder: (preview) {
        final fraction = preview ?? data.progress;
        final shownMs = preview == null
            ? data.positionMs
            : (preview * data.durationMs).round();
        return Column(
          children: [
            AppSlider(
              value: fraction,
              color: fg,
              trackColor: const Color(0x597F7F7F),
              onChanged: ctrl.onSeekChanged,
              onChangeEnd: ctrl.onSeekEnd,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(formatDuration(shownMs), style: timeStyle),
                Text(formatDuration(data.durationMs), style: timeStyle),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _transport(WatchPlayerReturnModel data, Color fg, bool isVideo) {
    final repeatColor = data.repeatAll ? fg : fg.withValues(alpha: 0.45);
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppIconButton(
            key: const Key('player-queue'),
            icon: CupertinoIcons.list_bullet,
            label: 'Up next',
            color: fg,
            onPressed: () => _openQueue(),
          ),
          const SizedBox(width: 12),
          AppIconButton(
            key: const Key('player-previous'),
            icon: CupertinoIcons.backward_end_fill,
            label: 'Previous',
            color: fg,
            onPressed: ctrl.onPrevious,
          ),
          const SizedBox(width: 12),
          AppIconButton(
            key: const Key('player-play-pause'),
            icon: data.playing
                ? CupertinoIcons.pause_fill
                : CupertinoIcons.play_fill,
            label: data.playing ? 'Pause' : 'Play',
            size: 64,
            iconSize: 26,
            background: fg,
            color: isVideo ? AppColors.text : AppColors.onDark,
            onPressed: ctrl.onPlayPause,
          ),
          const SizedBox(width: 12),
          AppIconButton(
            key: const Key('player-next'),
            icon: CupertinoIcons.forward_end_fill,
            label: 'Next',
            color: fg,
            onPressed: data.hasNext ? ctrl.onNext : null,
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIconButton(
                key: const Key('player-repeat'),
                icon: CupertinoIcons.repeat,
                label: data.repeatAll ? 'Repeat all on' : 'Repeat all off',
                color: repeatColor,
                onPressed: ctrl.onToggleRepeat,
              ),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: data.repeatAll ? fg : const Color(0x00000000),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// "Up next" opens as a sheet; tapping a recording plays it.
  Future<void> _openQueue() {
    return showAppSheet<void>(
      context,
      builder: (sheetContext) => ObxValue<ViewState<WatchPlayerReturnModel>>(
        listenable: ctrl.state,
        builder: (state) {
          final data = state is ViewStateLoaded<WatchPlayerReturnModel>
              ? state.data
              : null;
          final queue = data?.queue ?? const <QueueEntry>[];
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Up next', style: AppText.sheetTitle),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.5,
                ),
                child: ListView(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  children: [
                    for (var i = 0; i < queue.length; i++)
                      AppRow(
                        title: queue[i].title,
                        subtitle:
                            '${queue[i].type == RecordingType.video ? 'Video' : 'Audio'}'
                            ' · ${formatDuration(queue[i].durationMs)}',
                        playing: data != null && i == data.number - 1,
                        onTap: () {
                          Navigator.pop(sheetContext);
                          ctrl.onSkipTo(i);
                        },
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
