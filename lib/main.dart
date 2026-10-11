import 'package:flutter/material.dart';
import 'package:study_recorder/core/di/app_dependencies.dart';
import 'package:study_recorder/features/folder/folder_view.dart';
import 'package:study_recorder/features/folder/folder_view_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDependencies.init();
  runApp(const StudyRecorderApp());
}

class StudyRecorderApp extends StatelessWidget {
  const StudyRecorderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Study Recorder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE5392F)),
        useMaterial3: true,
      ),
      home: const FolderView(bundle: FolderBundle()),
    );
  }
}
