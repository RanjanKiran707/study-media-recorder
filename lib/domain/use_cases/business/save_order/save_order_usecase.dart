import 'package:study_recorder/core/errors/failure.dart';
import 'package:study_recorder/core/errors/result.dart';
import 'package:study_recorder/data/folder/folder_repository_interface.dart';
import 'package:study_recorder/data/recording/recording_repository_interface.dart';
import 'package:study_recorder/domain/use_cases/business/save_order/ordered_item.dart';

/// Saves a rearranged folder: [items] (folders and recordings together) get
/// the positions 0..n-1 in the order given. Top-level folders cannot be
/// rearranged, so the items always belong to a parent folder.
class SaveOrderUsecase {
  final FolderRepositoryInterface _folders;
  final RecordingRepositoryInterface _recordings;

  SaveOrderUsecase(this._folders, this._recordings);

  Future<Result<void>> call(List<OrderedItem> items) async {
    if (items.map((i) => i.id).toSet().length != items.length) {
      return const Err(ValidationFailure('duplicate_items'));
    }

    final folderOrder = <String, int>{};
    final recordingOrder = <String, int>{};
    for (var i = 0; i < items.length; i++) {
      final target = switch (items[i].kind) {
        OrderedItemKind.folder => folderOrder,
        OrderedItemKind.recording => recordingOrder,
      };
      target[items[i].id] = i;
    }

    if (folderOrder.isNotEmpty) {
      final saved = await _folders.updateSortOrder(folderOrder);
      if (saved is Err<void>) return saved;
    }
    if (recordingOrder.isNotEmpty) {
      final saved = await _recordings.updateSortOrder(recordingOrder);
      if (saved is Err<void>) return saved;
    }
    return const Ok(null);
  }
}
