import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/widgets.dart';
import 'package:study_recorder/core/di/app_dependencies.dart';
import 'package:study_recorder/core/utils/view_state.dart';
import 'package:study_recorder/core/widgets/app_buttons.dart';
import 'package:study_recorder/core/widgets/app_controls.dart';
import 'package:study_recorder/core/widgets/app_theme.dart';
import 'package:study_recorder/core/widgets/app_toast.dart';
import 'package:study_recorder/core/widgets/obx_value.dart';
import 'package:study_recorder/domain/use_cases/ui/watch_player/watch_player_return_model.dart';
import 'package:study_recorder/features/mini_player/mini_player_view_model.dart';
import 'package:study_recorder/features/player/player_view.dart';

/// The small player at the bottom of Home and the folder screens. Nothing is
/// drawn when nothing is playing.
class MiniPlayerView extends StatefulWidget {
  const MiniPlayerView({super.key});

  @override
  State<MiniPlayerView> createState() => _MiniPlayerViewState();
}

class _MiniPlayerViewState extends State<MiniPlayerView> {
  late final MiniPlayerViewModel ctrl;

  @override
  void initState() {
    super.initState();
    final deps = AppDependencies.instance;
    ctrl = MiniPlayerViewModel(
      watchPlayer: deps.watchPlayer,
      play: deps.playPlayer,
      pause: deps.pausePlayer,
      stop: deps.stopPlayback,
    );
    ctrl.actionState.addListener(_onActionStateChanged);
  }

  void _onActionStateChanged() {
    final state = ctrl.actionState.value;
    if (state is ViewStateError && mounted) {
      showFailureToast(context, state.failure);
    }
  }

  @override
  void dispose() {
    ctrl.actionState.removeListener(_onActionStateChanged);
    ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ObxValue<ViewState<WatchPlayerReturnModel>>(
      listenable: ctrl.state,
      builder: (state) => state.when(
        loading: () => const SizedBox.shrink(),
        error: (_) => const SizedBox.shrink(),
        loaded: (data) {
          if (!data.isActive) return const SizedBox.shrink();
          return Container(
            key: const Key('mini-player'),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.line)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppProgressLine(value: data.progress),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 8, 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          key: const Key('mini-player-open'),
                          behavior: HitTestBehavior.opaque,
                          onTap: () => PlayerView.open(context),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.rowTitle.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${data.folderName} · ${data.number}/${data.count}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.small,
                              ),
                            ],
                          ),
                        ),
                      ),
                      AppIconButton(
                        key: const Key('mini-player-play-pause'),
                        icon: data.playing
                            ? CupertinoIcons.pause_fill
                            : CupertinoIcons.play_fill,
                        label: data.playing ? 'Pause' : 'Play',
                        onPressed: ctrl.onPlayPause,
                      ),
                      AppIconButton(
                        key: const Key('mini-player-stop'),
                        icon: CupertinoIcons.xmark,
                        label: 'Stop and close',
                        onPressed: ctrl.onStop,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
