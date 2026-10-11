import 'package:study_recorder/data/recording/recording_model.dart';

/// One recording ready for the player.
class PlayableItem {
  final String recordingId;
  final String title;
  final String folderName;
  final RecordingType type;
  final int durationMs;

  /// Full path of the file on this device.
  final String filePath;

  const PlayableItem({
    required this.recordingId,
    required this.title,
    required this.folderName,
    required this.type,
    required this.durationMs,
    required this.filePath,
  });
}

class GetPlaylistReturnModel {
  /// The folder's recordings in the order shown in the list. Subfolders are
  /// skipped.
  final List<PlayableItem> items;

  const GetPlaylistReturnModel({required this.items});
}
