import 'package:flutter/widgets.dart';
import 'package:study_recorder/core/errors/result.dart';
import 'package:study_recorder/data/recording/recording_model.dart';

/// A finished take, in a temporary file. It is stored by saving it as a
/// recording, or removed with [RecorderRepositoryInterface.discard].
class RecordedFile {
  final String path;
  final int durationMs;
  final RecordingType type;

  const RecordedFile({
    required this.path,
    required this.durationMs,
    required this.type,
  });
}

/// The camera and microphone. One take at a time: [prepare], then [start],
/// optionally [pause] and [resume], then [stop]. Call [release] when the
/// Record screen closes.
///
/// Failures: `ValidationFailure('permission_denied')` when a permission is
/// refused, `UnexpectedFailure` for any device error.
abstract class RecorderRepositoryInterface {
  /// Asks for the permissions and opens the camera (video) or microphone.
  Future<Result<void>> prepare({required RecordingType type});

  /// The camera preview, or null for audio or before [prepare].
  Widget? buildPreview();

  Future<Result<void>> start();

  Future<Result<void>> pause();

  Future<Result<void>> resume();

  /// Stops the take. The duration does not count paused time.
  Future<Result<RecordedFile>> stop();

  /// Switches between the front and back camera (video only).
  Future<Result<void>> switchCamera();

  /// Time recorded so far, not counting paused time.
  Duration get elapsed;

  /// Deletes the temporary file of a take that is not saved.
  Future<Result<void>> discard(String path);

  /// Closes the camera and microphone. Never fails.
  Future<void> release();
}
