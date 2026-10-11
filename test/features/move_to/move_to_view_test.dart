import 'package:flutter_test/flutter_test.dart';
import 'package:study_recorder/core/widgets/app_buttons.dart';
import 'package:study_recorder/data/folder/folder_model.dart';
import 'package:study_recorder/features/move_to/move_to_view.dart';
import 'package:study_recorder/features/move_to/move_to_view_model.dart';

import '../../domain/fakes/test_env.dart';
import '../../domain/fakes/test_models.dart';
import '../widget_helpers.dart';

void main() {
  late TestEnv env;

  setUp(() {
    env = TestEnv();
    env.folders.folders.addAll([
      folderOf('physics', name: 'Physics', createdAt: 1),
      folderOf('chemistry', name: 'Chemistry', createdAt: 2),
      folderOf('mechanics', name: 'Mechanics', parentId: 'physics'),
    ]);
    env.folders.counts = {
      'physics': const FolderCounts(subfolders: 1, recordings: 3),
      'chemistry': const FolderCounts(subfolders: 0, recordings: 1),
    };
    env.recordings.recordings.add(recordingOf('r1', 'physics'));
  });

  Future<void> openPicker(WidgetTester tester) => pumpScreen(
    tester,
    env,
    const MoveToView(
      bundle: MoveToBundle(recordingId: 'r1', currentFolderId: 'physics'),
    ),
  );

  bool selectEnabled(WidgetTester tester) => tester
      .widgetList<AppButton>(find.byType(AppButton))
      .any((b) => b.label.contains('folder') && b.onPressed != null);

  testScreen('starts at the top level and cannot select there', (tester) async {
    await openPicker(tester);

    expect(find.text('Move to'), findsOneWidget);
    expect(find.text('All folders'), findsOneWidget);
    expect(find.text('Physics'), findsOneWidget);
    expect(find.text('Chemistry'), findsOneWidget);
    expect(find.text('Open a folder to select it'), findsOneWidget);
    expect(selectEnabled(tester), isFalse);
  });

  testScreen('rows show the recording count, or Current folder', (
    tester,
  ) async {
    await openPicker(tester);

    expect(find.text('Current folder'), findsOneWidget); // Physics
    expect(find.text('1 recording'), findsOneWidget); // Chemistry
  });

  testScreen('opening a folder shows its path and its subfolders', (
    tester,
  ) async {
    await openPicker(tester);

    await tapAndSettle(tester, find.text('Chemistry'));

    expect(find.text('Chemistry'), findsOneWidget); // the crumb
    expect(find.text('No subfolders here.'), findsOneWidget);
    expect(find.text('Select this folder'), findsOneWidget);
    expect(selectEnabled(tester), isTrue);
  });

  testScreen('the folder the recording is in cannot be selected', (
    tester,
  ) async {
    await openPicker(tester);

    await tapAndSettle(tester, find.text('Physics'));

    expect(find.text('Mechanics'), findsOneWidget);
    expect(find.text('Already in this folder'), findsOneWidget);
    expect(selectEnabled(tester), isFalse);
  });

  testScreen('the back arrow goes up one level at a time', (tester) async {
    await openPicker(tester);
    await tapAndSettle(tester, find.text('Physics'));
    await tapAndSettle(tester, find.text('Mechanics'));
    expect(find.text('Physics / Mechanics'), findsOneWidget);

    await tapAndSettle(tester, iconButton('Back'));
    expect(find.text('Mechanics'), findsOneWidget);
    expect(find.text('Physics / Mechanics'), findsNothing);

    await tester.binding.handlePopRoute(); // Android back does the same
    await settle(tester);
    expect(find.text('All folders'), findsOneWidget);
  });

  testScreen('selecting a folder moves the recording', (tester) async {
    await openPicker(tester);
    await tapAndSettle(tester, find.text('Chemistry'));

    await tapAndSettle(tester, button('Select this folder'));

    expect(env.recordings.moved, {'r1': 'chemistry'});
  });
}
