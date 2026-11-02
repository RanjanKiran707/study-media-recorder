import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:study_recorder/app.dart';
import 'package:study_recorder/core/di/app_dependencies.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    // Portrait only, on mobile devices.
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    // Lets audio keep playing with the screen off, with an Android notification.
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.ranjan.study_recorder.playback',
      androidNotificationChannelName: 'Study Recorder playback',
      androidNotificationOngoing: true,
    );
  }
  await AppDependencies.init();
  runApp(const StudyRecorderApp());
}
