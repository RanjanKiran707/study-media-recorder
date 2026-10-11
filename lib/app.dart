import 'package:flutter/widgets.dart';
import 'package:study_recorder/core/widgets/app_root.dart';
import 'package:study_recorder/features/folder/folder_view.dart';
import 'package:study_recorder/features/folder/folder_view_model.dart';

/// The whole app: Home inside the app shell. Needs `AppDependencies.instance`.
class StudyRecorderApp extends StatelessWidget {
  const StudyRecorderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppRoot(home: FolderView(bundle: FolderBundle()));
  }
}
