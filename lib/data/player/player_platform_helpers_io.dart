import 'dart:io';

import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:video_player/video_player.dart';

AudioSource createAudioSource(
  String pathOrUri, {
  required String id,
  required String title,
  required String album,
}) =>
    AudioSource.file(
      pathOrUri,
      tag: MediaItem(id: id, title: title, album: album),
    );

VideoPlayerController createVideoPlayer(String pathOrUri) =>
    VideoPlayerController.file(File(pathOrUri));
