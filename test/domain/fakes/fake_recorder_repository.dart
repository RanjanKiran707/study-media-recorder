import 'package:flutter/widgets.dart';
import 'package:study_recorder/core/errors/failure.dart';
import 'package:study_recorder/core/errors/result.dart';
import 'package:study_recorder/data/recorder/recorder_repository_interface.dart';
import 'package:study_recorder/data/recording/recording_model.dart';

/// A recorder that does nothing on the device. Set [failure] to make every
/// call return Err. [elapsed] is set by the test.
class FakeRecorderRepository implements RecorderRepositoryInterface {
  Failure? failure;
  Duration elapsedValue = Duration.zero;

  /// Used when the take is stopped.
  int takeDurationMs = 90000;

  RecordingType? prepared;
  final List<String> calls = [];
  final List<String> discarded = [];
  bool released = false;

  Result<void> _result(String call) {
    calls.add(call);
    if (failure != null) return Err(failure!);
    return const Ok(null);
  }

  @override
  Duration get elapsed => elapsedValue;

  @override
  Widget? buildPreview() => prepared == RecordingType.video
      ? const SizedBox(key: Key('fake-camera-preview'), height: 100)
      : null;

  @override
  Future<Result<void>> prepare({required RecordingType type}) async {
    prepared = type;
    released = false;
    return _result('prepare');
  }

  @override
  Future<Result<void>> start() async => _result('start');

  @override
  Future<Result<void>> pause() async => _result('pause');

  @override
  Future<Result<void>> resume() async => _result('resume');

  @override
  Future<Result<RecordedFile>> stop() async {
    calls.add('stop');
    if (failure != null) return Err(failure!);
    return Ok(
      RecordedFile(
        path: '/cache/take.${prepared == RecordingType.video ? 'mp4' : 'm4a'}',
        durationMs: takeDurationMs,
        type: prepared ?? RecordingType.audio,
      ),
    );
  }

  @override
  Future<Result<void>> switchCamera() async => _result('switchCamera');

  @override
  Future<Result<void>> discard(String path) async {
    discarded.add(path);
    return _result('discard');
  }

  @override
  Future<void> release() async {
    released = true;
    calls.add('release');
  }
}
