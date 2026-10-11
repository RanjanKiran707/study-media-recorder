import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/widgets.dart';
import 'package:study_recorder/core/di/app_dependencies.dart';
import 'package:study_recorder/core/utils/failure_message.dart';
import 'package:study_recorder/core/utils/format.dart';
import 'package:study_recorder/core/utils/view_state.dart';
import 'package:study_recorder/core/widgets/app_buttons.dart';
import 'package:study_recorder/core/widgets/app_controls.dart';
import 'package:study_recorder/core/widgets/app_route.dart';
import 'package:study_recorder/core/widgets/app_row.dart';
import 'package:study_recorder/core/widgets/app_scaffold.dart';
import 'package:study_recorder/core/widgets/app_sheet.dart';
import 'package:study_recorder/core/widgets/app_toast.dart';
import 'package:study_recorder/core/widgets/obx_value.dart';
import 'package:study_recorder/data/recording/recording_model.dart';
import 'package:study_recorder/domain/use_cases/ui/get_folder_path/get_folder_path_return_model.dart';
import 'package:study_recorder/domain/use_cases/ui/list_folder_items/list_folder_items_return_model.dart';
import 'package:study_recorder/features/folder/folder_view_model.dart';
import 'package:study_recorder/features/mini_player/mini_player_view.dart';
import 'package:study_recorder/features/move_to/move_to_view.dart';
import 'package:study_recorder/features/move_to/move_to_view_model.dart';
import 'package:study_recorder/features/player/player_view.dart';
import 'package:study_recorder/features/record/record_view.dart';
import 'package:study_recorder/features/record/record_view_model.dart';

enum _FolderAction { rename, delete }

enum _RecordingAction { rename, move, delete }

/// Home (folderId null) and every folder screen.
class FolderView extends StatefulWidget {
  final FolderBundle bundle;
  const FolderView({super.key, required this.bundle});

  static Future<void> open(BuildContext context, FolderBundle bundle) {
    return Navigator.push(
      context,
      appRoute<void>((_) => FolderView(bundle: bundle)),
    );
  }

  @override
  State<FolderView> createState() => _FolderViewState();
}

class _FolderViewState extends State<FolderView> {
  late final FolderViewModel ctrl;

  @override
  void initState() {
    super.initState();
    final deps = AppDependencies.instance;
    ctrl = FolderViewModel(
      bundle: widget.bundle,
      createFolder: deps.createFolder,
      renameFolder: deps.renameFolder,
      deleteFolder: deps.deleteFolder,
      renameRecording: deps.renameRecording,
      deleteRecording: deps.deleteRecording,
      saveOrder: deps.saveOrder,
      playRecording: deps.playRecording,
      getFolderPath: deps.getFolderPath,
      listFolderItems: deps.listFolderItems,
      watchPlayer: deps.watchPlayer,
    );
    ctrl.actionState.addListener(_onActionStateChanged);
    ctrl.playState.addListener(_onPlayStateChanged);
  }

  void _onActionStateChanged() {
    final state = ctrl.actionState.value;
    if (state is ViewStateError && mounted) {
      showFailureToast(context, state.failure);
      ctrl.onErrorShown();
    }
  }

  void _onPlayStateChanged() {
    final state = ctrl.playState.value;
    if (!mounted) return;
    if (state is ViewStateError) {
      showFailureToast(context, state.failure);
      ctrl.onPlayHandled();
    } else if (state is ViewStateLoaded) {
      ctrl.onPlayHandled();
      PlayerView.open(context);
    }
  }

  @override
  void dispose() {
    ctrl.actionState.removeListener(_onActionStateChanged);
    ctrl.playState.removeListener(_onPlayStateChanged);
    ctrl.dispose();
    super.dispose();
  }

  Future<void> _newFolder() async {
    final name = await showNameSheet(
      context,
      title: ctrl.isHome ? 'New folder' : 'New subfolder',
      confirmLabel: 'Create',
    );
    if (name == null) return;
    final ok = await ctrl.onCreateFolder(name);
    if (ok && mounted) showAppToast(context, 'Folder created');
  }

  Future<void> _folderMenu(FolderListItem item) async {
    final action = await showOptionsSheet<_FolderAction>(
      context,
      title: item.folder.name,
      choices: const [
        AppChoice(value: _FolderAction.rename, label: 'Rename'),
        AppChoice(value: _FolderAction.delete, label: 'Delete', danger: true),
      ],
    );
    if (action == null || !mounted) return;
    switch (action) {
      case _FolderAction.rename:
        final name = await showNameSheet(
          context,
          title: 'Rename folder',
          confirmLabel: 'Save',
          initialText: item.folder.name,
        );
        if (name != null) await ctrl.onRenameFolder(item.id, name);
      case _FolderAction.delete:
        final confirmed = await showConfirmSheet(
          context,
          title: 'Delete this folder?',
          message:
              '${formatCounts(subfolders: item.subfolderCount, recordings: item.recordingCount)} '
              'inside will also be deleted.',
          confirmLabel: 'Delete',
          destructive: true,
        );
        if (!confirmed) return;
        final ok = await ctrl.onDeleteFolder(item.id);
        if (ok && mounted) showAppToast(context, 'Folder deleted');
    }
  }

  Future<void> _recordingMenu(RecordingListItem item) async {
    final action = await showOptionsSheet<_RecordingAction>(
      context,
      title: item.recording.title,
      choices: const [
        AppChoice(value: _RecordingAction.rename, label: 'Rename'),
        AppChoice(value: _RecordingAction.move, label: 'Move to folder'),
        AppChoice(
          value: _RecordingAction.delete,
          label: 'Delete',
          danger: true,
        ),
      ],
    );
    if (action == null || !mounted) return;
    switch (action) {
      case _RecordingAction.rename:
        final title = await showNameSheet(
          context,
          title: 'Rename',
          confirmLabel: 'Save',
          initialText: item.recording.title,
          hint: 'Title',
        );
        if (title != null) await ctrl.onRenameRecording(item.id, title);
      case _RecordingAction.move:
        final moved = await MoveToView.open(
          context,
          MoveToBundle(
            recordingId: item.id,
            currentFolderId: item.recording.folderId,
          ),
        );
        if (moved != null && mounted) showAppToast(context, 'Moved to $moved');
      case _RecordingAction.delete:
        final ok = await ctrl.onDeleteRecording(item.id);
        if (ok && mounted) showAppToast(context, 'Recording deleted');
    }
  }

  Future<void> _recordHere() async {
    final folderId = widget.bundle.folderId;
    if (folderId == null) return;
    final saved = await RecordView.open(
      context,
      RecordBundle(folderId: folderId),
    );
    if (saved != null && mounted) showAppToast(context, saved);
  }

  Future<void> _saveRearrange() async {
    final ok = await ctrl.onSaveRearrange();
    if (ok && mounted) showAppToast(context, 'Order saved');
  }

  @override
  Widget build(BuildContext context) {
    return ObxMulti(
      listenables: [ctrl.actionState, ctrl.playState, ctrl.rearrangeItems],
      builder: () {
        final busy = ctrl.isBusy;
        final rearranging = ctrl.isRearranging;

        return PopScope(
          // Blocked while a future runs. In rearrange mode back cancels.
          canPop: !busy && !rearranging,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && !busy && rearranging) ctrl.onCancelRearrange();
          },
          child: AppPage(
            topBar: _topBar(busy, rearranging),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!ctrl.isHome) _crumbs(),
                Expanded(child: _list(busy, rearranging)),
              ],
            ),
            bottom: _bottom(busy, rearranging),
          ),
        );
      },
    );
  }

  Widget _topBar(bool busy, bool rearranging) {
    if (ctrl.isHome) {
      return const AppTopBar(title: Text('Study Recorder'));
    }
    return AppTopBar(
      leading: AppBackButton(
        onPressed: busy
            ? null
            : () => rearranging
                  ? ctrl.onCancelRearrange()
                  : Navigator.maybePop(context),
      ),
      title: ObxValue<ViewState<GetFolderPathReturnModel>>(
        listenable: ctrl.pathState,
        builder: (state) => state.when(
          idle: () => const Text(''),
          loading: () => const Text(''),
          error: (_) => const Text('Folder'),
          loaded: (path) => Text(path.folders.last.name),
        ),
      ),
      actions: [
        AppIconButton(
          icon: CupertinoIcons.arrow_up_arrow_down,
          label: 'Rearrange',
          selected: rearranging,
          onPressed: busy
              ? null
              : rearranging
              ? ctrl.onCancelRearrange
              : ctrl.onStartRearrange,
        ),
      ],
    );
  }

  Widget _crumbs() {
    return ObxValue<ViewState<GetFolderPathReturnModel>>(
      listenable: ctrl.pathState,
      builder: (state) => state.when(
        idle: () => const AppCrumbs(''),
        loading: () => const AppCrumbs(''),
        error: (_) => const AppCrumbs(''),
        // The breadcrumb shows only for a subfolder, as in the mockup.
        loaded: (path) => AppCrumbs(path.folders.length > 1 ? path.label : ''),
      ),
    );
  }

  Widget _bottom(bool busy, bool rearranging) {
    if (rearranging) {
      return AppActionBar(
        children: [
          AppButton(
            label: 'Cancel',
            style: AppButtonStyle.ghost,
            onPressed: busy ? null : ctrl.onCancelRearrange,
          ),
          AppButton(
            label: 'Save',
            loading: busy,
            onPressed: busy ? null : _saveRearrange,
          ),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const MiniPlayerView(),
        AppActionBar(
          children: ctrl.isHome
              ? [
                  AppButton(
                    label: 'New folder',
                    onPressed: busy ? null : _newFolder,
                  ),
                ]
              : [
                  AppButton(
                    label: 'New folder',
                    style: AppButtonStyle.ghost,
                    onPressed: busy ? null : _newFolder,
                  ),
                  AppButton(
                    label: 'Record here',
                    style: AppButtonStyle.record,
                    onPressed: busy ? null : _recordHere,
                  ),
                ],
        ),
      ],
    );
  }

  Widget _list(bool busy, bool rearranging) {
    if (rearranging) return _rearrangeList(busy);
    return ObxValue<ViewState<ListFolderItemsReturnModel>>(
      listenable: ctrl.state,
      builder: (state) => state.when(
        loading: () => const Center(child: AppSpinner()),
        error: (failure) => Center(child: Text(messageFor(failure))),
        loaded: (data) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            children: [
              if (data.items.isEmpty)
                AppEmpty(
                  ctrl.isHome
                      ? 'No folders yet. Create one for each subject.'
                      : 'Nothing here yet. Tap “Record here” to add your first explanation.',
                ),
              ObxValue<String?>(
                listenable: ctrl.playingRecordingId,
                builder: (playingId) => Column(
                  children: [
                    for (final item in data.items)
                      _row(
                        item,
                        busy: busy,
                        playing: item.id == playingId,
                        key: ValueKey(item.id),
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

  Widget _rearrangeList(bool busy) {
    return ObxValue<List<FolderItem>?>(
      listenable: ctrl.rearrangeItems,
      builder: (items) {
        final list = items ?? const <FolderItem>[];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: AppSectionLabel('Drag to change the order'),
            ),
            Expanded(
              child: ReorderableList(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: list.length,
                onReorder: busy ? (_, _) {} : ctrl.onReorder,
                itemBuilder: (context, index) => _row(
                  list[index],
                  busy: busy,
                  rearranging: true,
                  index: index,
                  key: ValueKey(list[index].id),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _handle(int index) {
    return const Padding(
      padding: EdgeInsets.all(6),
      child: Icon(CupertinoIcons.line_horizontal_3, size: 20),
    );
  }

  /// While rearranging, the whole row starts a drag as soon as it is touched.
  Widget _draggable(int index, bool rearranging, Widget row) {
    if (!rearranging) return row;
    return ReorderableDragStartListener(index: index, child: row);
  }

  Widget _row(
    FolderItem item, {
    required bool busy,
    bool playing = false,
    bool rearranging = false,
    int index = 0,
    required Key key,
  }) {
    final more = AppIconButton(
      icon: CupertinoIcons.ellipsis_vertical,
      label: 'More',
      onPressed: busy
          ? null
          : () => switch (item) {
              FolderListItem() => _folderMenu(item),
              RecordingListItem() => _recordingMenu(item),
            },
    );

    switch (item) {
      case FolderListItem():
        return KeyedSubtree(
          key: key,
          child: _draggable(
            index,
            rearranging,
            AppRow(
              title: item.folder.name,
              subtitle: formatCounts(
                subfolders: item.subfolderCount,
                recordings: item.recordingCount,
              ),
              leading: rearranging ? _handle(index) : null,
              trailing: rearranging ? null : more,
              onTap: rearranging || busy
                  ? null
                  : () => FolderView.open(
                      context,
                      FolderBundle(folderId: item.folder.id),
                    ),
            ),
          ),
        );
      case RecordingListItem():
        final recording = item.recording;
        final type = recording.type == RecordingType.video ? 'Video' : 'Audio';
        return KeyedSubtree(
          key: key,
          child: _draggable(
            index,
            rearranging,
            AppRow(
              title: recording.title,
              subtitle:
                  '$type · ${formatDuration(recording.durationMs)} · '
                  '${formatDate(recording.createdAt)}',
              playing: playing,
              leading: rearranging ? _handle(index) : null,
              trailing: rearranging ? null : more,
              onTap: rearranging || busy
                  ? null
                  : () => ctrl.onPlayRecording(item.id),
            ),
          ),
        );
    }
  }
}
