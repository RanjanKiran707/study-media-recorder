import 'package:flutter/material.dart';
import 'package:study_recorder/core/di/app_dependencies.dart';
import 'package:study_recorder/core/utils/failure_message.dart';
import 'package:study_recorder/core/utils/format.dart';
import 'package:study_recorder/core/utils/view_state.dart';
import 'package:study_recorder/core/widgets/obx_value.dart';
import 'package:study_recorder/data/recording/recording_model.dart';
import 'package:study_recorder/domain/use_cases/ui/get_folder_path/get_folder_path_return_model.dart';
import 'package:study_recorder/domain/use_cases/ui/list_folder_items/list_folder_items_return_model.dart';
import 'package:study_recorder/features/folder/folder_view_model.dart';
import 'package:study_recorder/features/folder/name_dialog.dart';

/// Home (folderId null) and every folder screen.
class FolderView extends StatefulWidget {
  final FolderBundle bundle;
  const FolderView({super.key, required this.bundle});

  static Future<void> open(BuildContext context, FolderBundle bundle) {
    return Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FolderView(bundle: bundle)),
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
      getFolderPath: deps.getFolderPath,
      listFolderItems: deps.listFolderItems,
    );
    ctrl.actionState.addListener(_onActionStateChanged);
  }

  void _onActionStateChanged() {
    final state = ctrl.actionState.value;
    if (state is ViewStateError && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(messageFor(state.failure))));
      ctrl.onErrorShown();
    }
  }

  @override
  void dispose() {
    ctrl.actionState.removeListener(_onActionStateChanged);
    ctrl.dispose();
    super.dispose();
  }

  Future<void> _newFolder() async {
    final name = await showNameDialog(
      context,
      title: 'New folder',
      confirmLabel: 'Create',
    );
    if (name != null) ctrl.onCreateFolder(name);
  }

  Future<void> _renameFolder(FolderListItem item) async {
    final name = await showNameDialog(
      context,
      title: 'Rename folder',
      confirmLabel: 'Save',
      initialText: item.folder.name,
    );
    if (name != null) ctrl.onRenameFolder(item.id, name);
  }

  Future<void> _deleteFolder(FolderListItem item) async {
    final confirmed = await confirmDelete(
      context,
      title: 'Delete "${item.folder.name}"?',
      message: 'Everything inside this folder is deleted too.',
    );
    if (confirmed) ctrl.onDeleteFolder(item.id);
  }

  Future<void> _renameRecording(RecordingListItem item) async {
    final title = await showNameDialog(
      context,
      title: 'Rename recording',
      confirmLabel: 'Save',
      initialText: item.recording.title,
      hint: 'Title',
    );
    if (title != null) ctrl.onRenameRecording(item.id, title);
  }

  Future<void> _deleteRecording(RecordingListItem item) async {
    final confirmed = await confirmDelete(
      context,
      title: 'Delete "${item.recording.title}"?',
      message: 'The recording is deleted from this device.',
    );
    if (confirmed) ctrl.onDeleteRecording(item.id);
  }

  @override
  Widget build(BuildContext context) {
    return ObxMulti(
      listenables: [ctrl.actionState, ctrl.rearrangeItems],
      builder: () {
        final busy = ctrl.actionState.value.isLoading;
        final rearranging = ctrl.isRearranging;

        return PopScope(
          // Blocked while saving. In rearrange mode, back cancels the changes.
          canPop: !busy && !rearranging,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && !busy && rearranging) ctrl.onCancelRearrange();
          },
          child: Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: !rearranging,
              title: _title(),
              actions: [
                if (rearranging) ...[
                  TextButton(
                    onPressed: busy ? null : ctrl.onCancelRearrange,
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: busy ? null : ctrl.onSaveRearrange,
                    child: busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save'),
                  ),
                ] else if (!ctrl.isHome)
                  IconButton(
                    tooltip: 'Rearrange',
                    icon: const Icon(Icons.swap_vert),
                    onPressed: busy ? null : ctrl.onStartRearrange,
                  ),
              ],
            ),
            body: _body(busy, rearranging),
            bottomNavigationBar: rearranging
                ? null
                : SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: OutlinedButton.icon(
                        onPressed: busy ? null : _newFolder,
                        icon: const Icon(Icons.create_new_folder_outlined),
                        label: const Text('New folder'),
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _title() {
    if (ctrl.isHome) return const Text('Study Recorder');
    return ObxValue<ViewState<GetFolderPathReturnModel>>(
      listenable: ctrl.pathState,
      builder: (state) => state.when(
        idle: () => const Text(''),
        loading: () => const Text(''),
        error: (_) => const Text('Folder'),
        loaded: (path) => Text(path.label),
      ),
    );
  }

  Widget _body(bool busy, bool rearranging) {
    if (rearranging) return _rearrangeList(busy);
    return ObxValue<ViewState<ListFolderItemsReturnModel>>(
      listenable: ctrl.state,
      builder: (state) => state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (failure) => Center(child: Text(messageFor(failure))),
        loaded: (data) {
          if (data.items.isEmpty) {
            return Center(
              child: Text(
                ctrl.isHome
                    ? 'No folders yet. Create one to get started.'
                    : 'This folder is empty.',
              ),
            );
          }
          return ListView(
            children: [
              for (final item in data.items)
                _tile(item, busy: busy, key: ValueKey(item.id)),
            ],
          );
        },
      ),
    );
  }

  Widget _rearrangeList(bool busy) {
    return ObxValue<List<FolderItem>?>(
      listenable: ctrl.rearrangeItems,
      builder: (items) => ReorderableListView(
        onReorder: busy ? (_, _) {} : ctrl.onReorder,
        children: [
          for (final item in items ?? const <FolderItem>[])
            _tile(item, busy: busy, rearranging: true, key: ValueKey(item.id)),
        ],
      ),
    );
  }

  Widget _tile(
    FolderItem item, {
    required bool busy,
    bool rearranging = false,
    required Key key,
  }) {
    switch (item) {
      case FolderListItem():
        return ListTile(
          key: key,
          leading: const Icon(Icons.folder_outlined),
          title: Text(item.folder.name),
          subtitle: Text(
            formatCounts(
              subfolders: item.subfolderCount,
              recordings: item.recordingCount,
            ),
          ),
          trailing: rearranging
              ? const Icon(Icons.drag_handle)
              : PopupMenuButton<String>(
                  enabled: !busy,
                  onSelected: (value) => value == 'rename'
                      ? _renameFolder(item)
                      : _deleteFolder(item),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'rename', child: Text('Rename')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
          onTap: rearranging || busy
              ? null
              : () => FolderView.open(
                  context,
                  FolderBundle(folderId: item.folder.id),
                ),
        );
      case RecordingListItem():
        final recording = item.recording;
        final type = recording.type == RecordingType.video ? 'Video' : 'Audio';
        return ListTile(
          key: key,
          leading: Icon(
            recording.type == RecordingType.video
                ? Icons.videocam_outlined
                : Icons.mic_none,
          ),
          title: Text(recording.title),
          subtitle: Text(
            '$type · ${formatDuration(recording.durationMs)} · '
            '${formatDate(recording.createdAt)}',
          ),
          trailing: rearranging
              ? const Icon(Icons.drag_handle)
              : PopupMenuButton<String>(
                  enabled: !busy,
                  onSelected: (value) => value == 'rename'
                      ? _renameRecording(item)
                      : _deleteRecording(item),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'rename', child: Text('Rename')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
        );
    }
  }
}
