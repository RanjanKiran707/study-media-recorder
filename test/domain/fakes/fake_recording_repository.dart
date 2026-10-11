import 'dart:async';

import 'package:study_recorder/core/errors/failure.dart';
import 'package:study_recorder/core/errors/result.dart';
import 'package:study_recorder/data/recording/recording_model.dart';
import 'package:study_recorder/data/recording/recording_repository_interface.dart';

/// In-memory recording repository. Streams emit the current value when
/// listened to, and again after [notify]. Set [failure] to make every call
/// return Err.
class FakeRecordingRepository implements RecordingRepositoryInterface {
  final List<RecordingModel> recordings = [];
  Failure? failure;

  /// When set, addRecording waits for it. Lets a test hold a save in Loading.
  Completer<void>? gate;

  final List<RecordingModel> added = [];
  final Map<String, String> renamed = {};
  final Map<String, String> moved = {};
  final List<String> deleted = [];
  final List<Map<String, int>> sortOrders = [];

  final _changes = StreamController<void>.broadcast();

  /// Makes the watch streams emit again.
  void notify() => _changes.add(null);

  @override
  Future<Result<RecordingModel>> addRecording({
    required String id,
    required String folderId,
    required String title,
    required RecordingType type,
    required String sourcePath,
    required int durationMs,
    required DateTime createdAt,
  }) async {
    await gate?.future;
    if (failure != null) return Err(failure!);
    final model = RecordingModel(
      id: id,
      folderId: folderId,
      title: title,
      type: type,
      filePath: '$id.m4a',
      durationMs: durationMs,
      createdAt: createdAt,
    );
    added.add(model);
    recordings.add(model);
    return Ok(model);
  }

  @override
  Future<Result<void>> renameRecording(String recordingId, String title) async {
    if (failure != null) return Err(failure!);
    renamed[recordingId] = title;
    return const Ok(null);
  }

  @override
  Future<Result<void>> moveRecording(
    String recordingId,
    String folderId,
  ) async {
    if (failure != null) return Err(failure!);
    moved[recordingId] = folderId;
    return const Ok(null);
  }

  @override
  Future<Result<void>> deleteRecording(String recordingId) async {
    if (failure != null) return Err(failure!);
    deleted.add(recordingId);
    return const Ok(null);
  }

  @override
  Future<Result<RecordingModel?>> getRecording(String recordingId) async {
    if (failure != null) return Err(failure!);
    final matches = recordings.where((r) => r.id == recordingId);
    return Ok(matches.isEmpty ? null : matches.first);
  }

  @override
  Stream<Result<List<RecordingModel>>> watchRecordings(String folderId) {
    Result<List<RecordingModel>> read() {
      if (failure != null) return Err(failure!);
      return Ok(recordings.where((r) => r.folderId == folderId).toList());
    }

    return Stream.multi((controller) {
      controller.add(read());
      final sub = _changes.stream.listen((_) => controller.add(read()));
      controller.onCancel = () {
        sub.cancel();
      };
    });
  }

  @override
  Future<Result<void>> updateSortOrder(Map<String, int> sortIndexById) async {
    if (failure != null) return Err(failure!);
    sortOrders.add(sortIndexById);
    return const Ok(null);
  }

  @override
  String absolutePath(RecordingModel recording) =>
      '/storage/${recording.filePath}';
}
