import 'package:study_recorder/core/errors/result.dart';
import 'package:study_recorder/core/utils/combine_latest.dart';
import 'package:study_recorder/data/folder/folder_model.dart';
import 'package:study_recorder/data/folder/folder_repository_interface.dart';
import 'package:study_recorder/data/recording/recording_model.dart';
import 'package:study_recorder/data/recording/recording_repository_interface.dart';
import 'package:study_recorder/domain/use_cases/ui/list_folder_items/list_folder_items_return_model.dart';

/// The list of one folder (or of Home when [folderId] is null): subfolders
/// and recordings merged into one list, ordered by sort index (items that
/// were never rearranged last), then by created time.
class ListFolderItemsUsecase {
  final FolderRepositoryInterface _folders;
  final RecordingRepositoryInterface _recordings;

  ListFolderItemsUsecase(this._folders, this._recordings);

  Stream<Result<ListFolderItemsReturnModel>> call(String? folderId) {
    final recordings = folderId == null
        ? Stream.value(const Ok(<RecordingModel>[]))
        : _recordings.watchRecordings(folderId);

    final foldersAndRecordings = combineLatest2(
      _folders.watchFolders(folderId),
      recordings,
      (folders, recordings) => (folders, recordings),
    );

    return combineLatest2(
      foldersAndRecordings,
      _folders.watchFolderCounts(),
      (pair, counts) => pair.$1.flatMap(
        (folders) => pair.$2.flatMap(
          (recordings) => counts.map(
            (countsById) => ListFolderItemsReturnModel(
              items: _merge(folders, recordings, countsById),
            ),
          ),
        ),
      ),
    );
  }

  List<FolderItem> _merge(
    List<FolderModel> folders,
    List<RecordingModel> recordings,
    Map<String, FolderCounts> countsById,
  ) {
    final entries = <_Entry>[
      for (final f in folders)
        _Entry(
          sortIndex: f.sortIndex,
          createdAt: f.createdAt,
          item: FolderListItem(
            folder: f,
            subfolderCount: countsById[f.id]?.subfolders ?? 0,
            recordingCount: countsById[f.id]?.recordings ?? 0,
          ),
        ),
      for (final r in recordings)
        _Entry(
          sortIndex: r.sortIndex,
          createdAt: r.createdAt,
          item: RecordingListItem(recording: r),
        ),
    ];
    entries.sort((a, b) {
      final ai = a.sortIndex;
      final bi = b.sortIndex;
      if (ai != null && bi != null && ai != bi) return ai.compareTo(bi);
      if (ai != null && bi == null) return -1;
      if (ai == null && bi != null) return 1;
      return a.createdAt.compareTo(b.createdAt);
    });
    return entries.map((e) => e.item).toList();
  }
}

class _Entry {
  final int? sortIndex;
  final DateTime createdAt;
  final FolderItem item;

  const _Entry({
    required this.sortIndex,
    required this.createdAt,
    required this.item,
  });
}
