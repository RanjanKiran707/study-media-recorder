import 'package:study_recorder/core/errors/failure.dart';

/// The text shown to the user for a [Failure]. Use case failures carry a key
/// (see `docs/progress/use_cases_progress.md`), which is translated here.
String messageFor(Failure failure) {
  return switch (failure.message) {
    'name_required' => 'Please enter a name.',
    'title_required' => 'Please enter a title.',
    'duration_invalid' => 'The recording is empty.',
    'folder_not_found' => 'That folder no longer exists.',
    'recording_not_found' => 'That recording no longer exists.',
    'same_folder' => 'The recording is already in that folder.',
    'duplicate_items' => 'The order could not be saved.',
    _ => switch (failure) {
      StorageFailure() => 'Could not read or save your data. Please try again.',
      _ => 'Something went wrong. Please try again.',
    },
  };
}
