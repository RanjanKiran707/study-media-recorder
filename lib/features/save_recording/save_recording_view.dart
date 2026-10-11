import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/widgets.dart';
import 'package:study_recorder/core/di/app_dependencies.dart';
import 'package:study_recorder/core/utils/format.dart';
import 'package:study_recorder/core/utils/view_state.dart';
import 'package:study_recorder/core/widgets/app_buttons.dart';
import 'package:study_recorder/core/widgets/app_scaffold.dart';
import 'package:study_recorder/core/widgets/app_sheet.dart';
import 'package:study_recorder/core/widgets/app_text_field.dart';
import 'package:study_recorder/core/widgets/app_theme.dart';
import 'package:study_recorder/core/widgets/app_toast.dart';
import 'package:study_recorder/core/widgets/obx_value.dart';
import 'package:study_recorder/data/recording/recording_model.dart';
import 'package:study_recorder/domain/use_cases/ui/get_folder_path/get_folder_path_return_model.dart';
import 'package:study_recorder/features/save_recording/save_recording_view_model.dart';

/// Opened by the Record screen. Pops with the message for the folder screen.
class SaveRecordingView extends StatefulWidget {
  final SaveRecordingBundle bundle;
  const SaveRecordingView({super.key, required this.bundle});

  @override
  State<SaveRecordingView> createState() => _SaveRecordingViewState();
}

class _SaveRecordingViewState extends State<SaveRecordingView> {
  late final SaveRecordingViewModel ctrl;
  final titleController = TextEditingController();
  bool _saving = false; // which action is running, for the message to return

  @override
  void initState() {
    super.initState();
    final deps = AppDependencies.instance;
    ctrl = SaveRecordingViewModel(
      bundle: widget.bundle,
      save: deps.saveRecording,
      discardTake: deps.discardTake,
      getFolderPath: deps.getFolderPath,
    );
    ctrl.actionState.addListener(_onActionStateChanged);
  }

  String _folderName() {
    final path = ctrl.pathState.value;
    if (path is ViewStateLoaded<GetFolderPathReturnModel>) {
      return path.data.folders.last.name;
    }
    return 'folder';
  }

  void _onActionStateChanged() {
    final state = ctrl.actionState.value;
    if (!mounted) return;
    if (state is ViewStateError) {
      showFailureToast(context, state.failure);
      ctrl.onErrorShown();
    } else if (state is ViewStateLoaded) {
      Navigator.pop(
        context,
        _saving ? 'Saved to ${_folderName()}' : 'Recording discarded',
      );
    }
  }

  @override
  void dispose() {
    ctrl.actionState.removeListener(_onActionStateChanged);
    titleController.dispose();
    ctrl.dispose();
    super.dispose();
  }

  void _save() {
    _saving = true;
    ctrl.onSave(titleController.text);
  }

  void _discard() {
    _saving = false;
    ctrl.onDiscard();
  }

  /// The close button and the back button ask first, so a take is not lost
  /// by accident.
  Future<void> _confirmDiscard() async {
    if (ctrl.actionState.value.isLoading) return;
    final confirmed = await showConfirmSheet(
      context,
      title: 'Discard this recording?',
      message: 'It will not be saved.',
      confirmLabel: 'Discard',
      destructive: true,
    );
    if (confirmed) _discard();
  }

  @override
  Widget build(BuildContext context) {
    final file = widget.bundle.file;
    final type = file.type == RecordingType.video ? 'Video' : 'Audio';

    return ObxValue<ViewState<void>>(
      listenable: ctrl.actionState,
      builder: (state) {
        final busy = state.isLoading;
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _confirmDiscard();
          },
          child: AppPage(
            topBar: AppTopBar(
              leading: AppBackButton(
                icon: CupertinoIcons.xmark,
                label: 'Close',
                onPressed: busy ? null : _confirmDiscard,
              ),
              title: const Text('Save recording'),
            ),
            body: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ObxValue<ViewState<GetFolderPathReturnModel>>(
                    listenable: ctrl.pathState,
                    builder: (path) => Text(
                      '$type · ${formatDuration(file.durationMs)}'
                      '${path is ViewStateLoaded<GetFolderPathReturnModel> ? ' · Saving to ${path.data.label}' : ''}',
                      key: const Key('save-summary'),
                      style: AppText.rowSubtitle.copyWith(fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 24),
                  AppTextField(
                    controller: titleController,
                    label: 'Title',
                    hint: "e.g. Newton's second law",
                    enabled: !busy,
                    autofocus: true,
                    onSubmitted: (_) => busy ? null : _save(),
                  ),
                ],
              ),
            ),
            bottom: AppActionBar(
              children: [
                AppButton(
                  label: 'Discard',
                  style: AppButtonStyle.text,
                  onPressed: busy ? null : _discard,
                ),
                AppButton(
                  label: 'Save',
                  loading: busy,
                  onPressed: busy ? null : _save,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
