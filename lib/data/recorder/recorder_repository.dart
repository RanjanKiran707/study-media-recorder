import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';
import 'package:record/record.dart';
import 'package:study_recorder/core/errors/failure.dart';
import 'package:study_recorder/core/errors/result.dart';
import 'package:study_recorder/core/storage/file_utils.dart';
import 'package:study_recorder/data/recorder/recorder_repository_interface.dart';
import 'package:study_recorder/data/recording/recording_model.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Video uses the `camera` package, audio uses `record`. Needs a device, so
/// it is covered by the fake in tests and checked by running the app.
class RecorderRepository implements RecorderRepositoryInterface {
  RecordingType? _type;
  CameraController? _camera;
  List<CameraDescription> _cameras = const [];
  CameraDescription? _current;
  AudioRecorder? _audio;
  bool _recording = false;
  final Stopwatch _stopwatch = Stopwatch();

  @override
  Duration get elapsed => _stopwatch.elapsed;

  @override
  Widget? buildPreview() {
    if (_type != RecordingType.video) return null;
    // Rebuilds by itself when the camera is swapped (front/back).
    return ValueListenableBuilder<CameraController?>(
      valueListenable: _preview,
      builder: (context, camera, _) {
        if (camera == null || !camera.value.isInitialized) {
          return const SizedBox.shrink();
        }
        final size = camera.value.previewSize;
        if (size == null) return CameraPreview(camera);
        // Fill the viewfinder (crop the overflow) instead of letterboxing.
        final portrait =
            MediaQuery.orientationOf(context) == Orientation.portrait;
        final long = size.width > size.height ? size.width : size.height;
        final short = size.width > size.height ? size.height : size.width;
        return ClipRect(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: portrait ? short : long,
              height: portrait ? long : short,
              child: CameraPreview(camera),
            ),
          ),
        );
      },
    );
  }

  final ValueNotifier<CameraController?> _preview = ValueNotifier(null);

  @override
  Future<Result<void>> prepare({required RecordingType type}) async {
    try {
      await release();
      _type = type;

      if (type == RecordingType.video) {
        // The camera plugin asks for the camera and microphone permissions
        // itself when it opens the camera.
        _cameras = await availableCameras();
        if (_cameras.isEmpty) {
          return const Err(UnexpectedFailure('camera_unavailable'));
        }
        _current = _cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
          orElse: () => _cameras.first,
        );
        await _openCamera(_current!);
      } else {
        final recorder = AudioRecorder();
        _audio = recorder;
        // Asks for the microphone permission when it is not granted yet.
        if (!await recorder.hasPermission()) {
          return const Err(ValidationFailure('permission_denied'));
        }
      }
      return const Ok(null);
    } on CameraException catch (e) {
      final denied = e.code.contains('AccessDenied');
      return Err(
        denied
            ? const ValidationFailure('permission_denied')
            : UnexpectedFailure(e.toString()),
      );
    } catch (e) {
      return Err(UnexpectedFailure(e.toString()));
    }
  }

  Future<void> _openCamera(CameraDescription description) async {
    // Most phones cannot hold two cameras open, so close the old one first.
    final old = _camera;
    _camera = null;
    _preview.value = null;
    await old?.dispose();
    final controller = CameraController(
      description,
      ResolutionPreset.high,
      enableAudio: true,
    );
    await controller.initialize();
    _camera = controller;
    _current = description;
    _preview.value = controller;
  }

  @override
  Future<Result<void>> start() async {
    try {
      _stopwatch
        ..reset()
        ..start();
      if (_type == RecordingType.video) {
        await _camera!.startVideoRecording();
      } else {
        final path = await getAudioTempPath();
        await _audio!.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: path,
        );
      }
      _recording = true;
      await WakelockPlus.enable();
      return const Ok(null);
    } catch (e) {
      _stopwatch.stop();
      return Err(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> pause() async {
    try {
      if (_type == RecordingType.video) {
        await _camera!.pauseVideoRecording();
      } else {
        await _audio!.pause();
      }
      _stopwatch.stop();
      return const Ok(null);
    } catch (e) {
      return Err(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> resume() async {
    try {
      if (_type == RecordingType.video) {
        await _camera!.resumeVideoRecording();
      } else {
        await _audio!.resume();
      }
      _stopwatch.start();
      return const Ok(null);
    } catch (e) {
      return Err(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Result<RecordedFile>> stop() async {
    try {
      _stopwatch.stop();
      final durationMs = _stopwatch.elapsedMilliseconds;
      final String? path;
      if (_type == RecordingType.video) {
        path = (await _camera!.stopVideoRecording()).path;
      } else {
        path = await _audio!.stop();
      }
      _recording = false;
      await WakelockPlus.disable();
      if (path == null) {
        return const Err(UnexpectedFailure('nothing_recorded'));
      }
      return Ok(RecordedFile(path: path, durationMs: durationMs, type: _type!));
    } catch (e) {
      return Err(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> switchCamera() async {
    try {
      if (_type != RecordingType.video || _cameras.length < 2) {
        return const Ok(null);
      }
      final wanted = _current?.lensDirection == CameraLensDirection.back
          ? CameraLensDirection.front
          : CameraLensDirection.back;
      final next = _cameras.firstWhere(
        (c) => c.lensDirection == wanted,
        orElse: () => _current!,
      );
      if (_recording) {
        await _camera!.setDescription(next);
        _current = next;
      } else {
        await _openCamera(next);
      }
      return const Ok(null);
    } catch (e) {
      return Err(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> discard(String path) async {
    try {
      await deleteFileIfExists(path);
      return const Ok(null);
    } catch (e) {
      return Err(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<void> release() async {
    try {
      _stopwatch
        ..stop()
        ..reset();
      _recording = false;
      await WakelockPlus.disable();
      _preview.value = null;
      await _camera?.dispose();
      _camera = null;
      await _audio?.dispose();
      _audio = null;
    } catch (_) {
      // Releasing must never fail the caller.
    }
  }
}
