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
import 'package:study_recorder/core/widgets/app_theme.dart';
import 'package:study_recorder/core/widgets/app_toast.dart';
import 'package:study_recorder/core/widgets/obx_value.dart';
import 'package:study_recorder/domain/use_cases/ui/get_folder_path/get_folder_path_return_model.dart';
import 'package:study_recorder/domain/use_cases/ui/list_subfolders/list_subfolders_return_model.dart';
import 'package:study_recorder/features/move_to/move_to_view_model.dart';

/// The folder picker. Pops with the name of the folder the recording was
/// moved to, or null when the user backed out.
class MoveToView extends StatefulWidget {
  final MoveToBundle bundle;
  const MoveToView({super.key, required this.bundle});

  static Future<String?> open(BuildContext context, MoveToBundle bundle) {
    return Navigator.push<String>(
      context,
      appModalRoute((_) => MoveToView(bundle: bundle)),
    );
  }

  @override
  State<MoveToView> createState() => _MoveToViewState();
}

class _MoveToViewState extends State<MoveToView> {
  late final MoveToViewModel ctrl;

  @override
  void initState() {
    super.initState();
    final deps = AppDependencies.instance;
    ctrl = MoveToViewModel(
      bundle: widget.bundle,
      moveRecording: deps.moveRecording,
      listSubfolders: deps.listSubfolders,
      getFolderPath: deps.getFolderPath,
    );
    ctrl.actionState.addListener(_onActionStateChanged);
  }

  void _onActionStateChanged() {
    final state = ctrl.actionState.value;
    if (!mounted) return;
    if (state is ViewStateError) {
      showFailureToast(context, state.failure);
      ctrl.onErrorShown();
    } else if (state is ViewStateLoaded) {
      Navigator.pop(context, ctrl.currentFolderName ?? 'the folder');
    }
  }

  @override
  void dispose() {
    ctrl.actionState.removeListener(_onActionStateChanged);
    ctrl.dispose();
    super.dispose();
  }

  /// The back arrow and the system back button go up one level, then close.
  void _back() {
    if (!ctrl.onUp() && mounted) Navigator.pop(context);
  }

  String _buttonLabel() {
    if (ctrl.isTopLevel) return 'Open a folder to select it';
    if (ctrl.currentFolderId.value == widget.bundle.currentFolderId) {
      return 'Already in this folder';
    }
    return 'Select this folder';
  }

  @override
  Widget build(BuildContext context) {
    return ObxMulti(
      listenables: [ctrl.currentFolderId, ctrl.actionState],
      builder: () {
        final busy = ctrl.actionState.value.isLoading;
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && !busy) _back();
          },
          child: AppPage(
            topBar: AppTopBar(
              leading: AppBackButton(onPressed: busy ? null : _back),
              title: const Text('Move to'),
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ObxValue<ViewState<GetFolderPathReturnModel>>(
                  listenable: ctrl.pathState,
                  builder: (state) => AppCrumbs(
                    state is ViewStateLoaded<GetFolderPathReturnModel>
                        ? state.data.label
                        : 'All folders',
                  ),
                ),
                Expanded(child: _list(busy)),
              ],
            ),
            bottom: AppActionBar(
              children: [
                AppButton(
                  label: _buttonLabel(),
                  loading: busy,
                  onPressed: ctrl.canSelect ? ctrl.onSelect : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _list(bool busy) {
    return ObxValue<ViewState<ListSubfoldersReturnModel>>(
      listenable: ctrl.state,
      builder: (state) => state.when(
        loading: () => const Center(child: AppSpinner()),
        error: (failure) => Center(child: Text(messageFor(failure))),
        loaded: (data) {
          if (data.folders.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: AppEmpty('No subfolders here.'),
            );
          }
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              for (final folder in data.folders)
                AppRow(
                  title: folder.name,
                  subtitle: folder.id == widget.bundle.currentFolderId
                      ? 'Current folder'
                      : formatCounts(
                          subfolders: 0,
                          recordings: data.recordingCounts[folder.id] ?? 0,
                        ).replaceFirst('Empty', '0 recordings'),
                  trailing: const Icon(
                    CupertinoIcons.chevron_right,
                    size: 18,
                    color: AppColors.muted,
                  ),
                  onTap: busy ? null : () => ctrl.onOpenFolder(folder.id),
                ),
            ],
          );
        },
      ),
    );
  }
}
