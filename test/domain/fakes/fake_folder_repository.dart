import 'dart:async';

import 'package:study_recorder/core/errors/failure.dart';
import 'package:study_recorder/core/errors/result.dart';
import 'package:study_recorder/data/folder/folder_model.dart';
import 'package:study_recorder/data/folder/folder_repository_interface.dart';

/// In-memory folder repository. Streams emit the current value when listened
/// to, and again after [notify]. Set [failure] to make every call return Err.
class FakeFolderRepository implements FolderRepositoryInterface {
  final List<FolderModel> folders = [];
  Map<String, FolderCounts> counts = {};
  Failure? failure;

  final List<FolderModel> created = [];
  final Map<String, String> renamed = {};
  final List<String> deleted = [];
  final List<Map<String, int>> sortOrders = [];

  final _changes = StreamController<void>.broadcast();

  /// Makes the watch streams emit again.
  void notify() => _changes.add(null);

  Stream<T> _watch<T>(T Function() read) {
    late final StreamController<T> controller;
    StreamSubscription<void>? sub;
    controller = StreamController<T>(
      onListen: () {
        controller.add(read());
        sub = _changes.stream.listen((_) => controller.add(read()));
      },
      onCancel: () => sub?.cancel(),
    );
    return controller.stream;
  }

  @override
  Future<Result<void>> createFolder(FolderModel folder) async {
    if (failure != null) return Err(failure!);
    created.add(folder);
    folders.add(folder);
    return const Ok(null);
  }

  @override
  Future<Result<void>> renameFolder(String folderId, String name) async {
    if (failure != null) return Err(failure!);
    renamed[folderId] = name;
    return const Ok(null);
  }

  @override
  Future<Result<void>> deleteFolder(String folderId) async {
    if (failure != null) return Err(failure!);
    deleted.add(folderId);
    return const Ok(null);
  }

  @override
  Future<Result<FolderModel?>> getFolder(String folderId) async {
    if (failure != null) return Err(failure!);
    final matches = folders.where((f) => f.id == folderId);
    return Ok(matches.isEmpty ? null : matches.first);
  }

  @override
  Stream<Result<List<FolderModel>>> watchFolders(String? parentId) {
    return _watch<Result<List<FolderModel>>>(() {
      if (failure != null) return Err(failure!);
      return Ok(folders.where((f) => f.parentId == parentId).toList());
    });
  }

  @override
  Stream<Result<Map<String, FolderCounts>>> watchFolderCounts() {
    return _watch<Result<Map<String, FolderCounts>>>(() {
      if (failure != null) return Err(failure!);
      return Ok(Map.of(counts));
    });
  }

  @override
  Future<Result<void>> updateSortOrder(Map<String, int> sortIndexById) async {
    if (failure != null) return Err(failure!);
    sortOrders.add(sortIndexById);
    return const Ok(null);
  }
}
