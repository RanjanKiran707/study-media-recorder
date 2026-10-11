import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:study_recorder/core/di/app_dependencies.dart';
import 'package:study_recorder/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Portrait only, on every screen.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  // Lets audio keep playing with the screen off, with a notification.
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.ranjan.study_recorder.playback',
    androidNotificationChannelName: 'Study Recorder playback',
    androidNotificationOngoing: true,
  );
  await AppDependencies.init();
  runApp(const StudyRecorderApp());
}
