import 'package:study_recorder/core/di/app_dependencies.dart';

import 'fake_folder_repository.dart';
import 'fake_player_repository.dart';
import 'fake_recorder_repository.dart';
import 'fake_recording_repository.dart';

/// All four fakes, and the real use cases built on them.
class TestEnv {
  final FakeFolderRepository folders = FakeFolderRepository();
  final FakeRecordingRepository recordings = FakeRecordingRepository();
  final FakeRecorderRepository recorder = FakeRecorderRepository();
  final FakePlayerRepository player = FakePlayerRepository();

  late final AppDependencies deps = AppDependencies.fromRepositories(
    folders,
    recordings,
    recorder,
    player,
  );

  /// Makes [deps] the app's dependencies, for widget tests.
  void install() => AppDependencies.instance = deps;
}
