import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_recorder/core/widgets/app_buttons.dart';
import 'package:study_recorder/data/folder/folder_model.dart';
import 'package:study_recorder/data/recording/recording_model.dart';
import 'package:study_recorder/features/folder/folder_view.dart';
import 'package:study_recorder/features/folder/folder_view_model.dart';

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
      'physics': const FolderCounts(subfolders: 1, recordings: 4),
    };
    env.recordings.recordings.addAll([
      recordingOf('r1', 'physics', title: 'Work and energy', createdAt: 10),
      recordingOf(
        'r2',
        'physics',
        title: 'Newton',
        createdAt: 11,
        type: RecordingType.video,
      ),
    ]);
  });

  Future<void> openHome(WidgetTester tester) =>
      pumpScreen(tester, env, const FolderView(bundle: FolderBundle()));

  Future<void> openPhysics(WidgetTester tester) => pumpScreen(
    tester,
    env,
    const FolderView(bundle: FolderBundle(folderId: 'physics')),
  );

  group('Home', () {
    testScreen('shows the title, folders with counts and New folder', (
      tester,
    ) async {
      await openHome(tester);

      expect(find.text('Study Recorder'), findsOneWidget);
      expect(find.text('Physics'), findsOneWidget);
      expect(find.text('Chemistry'), findsOneWidget);
      expect(find.text('4 recordings · 1 subfolder'), findsOneWidget);
      expect(find.text('Empty'), findsOneWidget); // Chemistry
      expect(button('New folder'), findsOneWidget);
      expect(button('Record here'), findsNothing);
      expect(iconButton('Back'), findsNothing);
    });

    testScreen('an empty Home explains what to do', (tester) async {
      env.folders.folders.clear();
      await openHome(tester);

      expect(
        find.text('No folders yet. Create one for each subject.'),
        findsOneWidget,
      );
    });

    testScreen('New folder asks for a name and creates it', (tester) async {
      await openHome(tester);

      await tapAndSettle(tester, button('New folder'));
      await typeText(tester, 'History');
      await tapAndSettle(tester, button('Create'));

      expect(env.folders.created.single.name, 'History');
      expect(env.folders.created.single.parentId, isNull);
      expect(find.text('Folder created'), findsOneWidget);
    });

    testScreen('a blank name shows the error and creates nothing', (
      tester,
    ) async {
      await openHome(tester);

      await tapAndSettle(tester, button('New folder'));
      await tapAndSettle(tester, button('Create'));

      expect(find.text('Please enter a name.'), findsOneWidget);
      expect(env.folders.created, isEmpty);
    });

    testScreen('while creating, buttons are disabled and back is blocked', (
      tester,
    ) async {
      env.folders.gate = Completer<void>();
      await openHome(tester);
      await tapAndSettle(tester, button('New folder'));
      await typeText(tester, 'History');
      await tester.tap(button('Create'));
      await tester.pump(const Duration(milliseconds: 400));

      expect(canPopNow(tester), isFalse);
      final newFolder = tester.widget<AppButton>(button('New folder'));
      expect(newFolder.onPressed, isNull);

      env.folders.gate!.complete();
      await settle(tester);
      expect(env.folders.created.single.name, 'History');
      expect(canPopNow(tester), isTrue);
    });

    testScreen('the folder menu renames', (tester) async {
      await openHome(tester);

      await tapAndSettle(tester, iconButton('More').first);
      await tapAndSettle(tester, find.text('Rename'));
      await typeText(tester, 'Physics 2');
      await tapAndSettle(tester, button('Save'));

      expect(env.folders.renamed, {'physics': 'Physics 2'});
    });

    testScreen('the folder menu deletes after confirming', (tester) async {
      await openHome(tester);

      await tapAndSettle(tester, iconButton('More').first);
      await tapAndSettle(tester, find.text('Delete'));
      expect(find.text('Delete this folder?'), findsOneWidget);
      expect(
        find.text('4 recordings · 1 subfolder inside will also be deleted.'),
        findsOneWidget,
      );
      await tapAndSettle(tester, button('Delete'));

      expect(env.folders.deleted, ['physics']);
      expect(find.text('Folder deleted'), findsOneWidget);
    });

    testScreen('cancelling the delete keeps the folder', (tester) async {
      await openHome(tester);

      await tapAndSettle(tester, iconButton('More').first);
      await tapAndSettle(tester, find.text('Delete'));
      await tapAndSettle(tester, button('Cancel'));

      expect(env.folders.deleted, isEmpty);
    });

    testScreen('tapping a folder opens it', (tester) async {
      await openHome(tester);

      await tapAndSettle(tester, find.text('Physics'));

      expect(iconButton('Back'), findsOneWidget);
      expect(button('Record here'), findsOneWidget);
      expect(find.text('Work and energy'), findsOneWidget);
    });
  });

  group('Folder', () {
    testScreen('lists subfolders and recordings together', (tester) async {
      await openPhysics(tester);

      expect(find.text('Physics'), findsOneWidget); // the title
      expect(find.text('Mechanics'), findsOneWidget);
      expect(find.text('Work and energy'), findsOneWidget);
      expect(find.textContaining('Audio · 0:01'), findsOneWidget);
      expect(find.textContaining('Video · 0:01'), findsOneWidget);
      expect(button('New folder'), findsOneWidget);
      expect(button('Record here'), findsOneWidget);
    });

    testScreen('a subfolder shows its path under the title', (tester) async {
      await pumpScreen(
        tester,
        env,
        const FolderView(bundle: FolderBundle(folderId: 'mechanics')),
      );

      expect(find.text('Physics / Mechanics'), findsOneWidget);
    });

    testScreen('an empty folder explains what to do', (tester) async {
      await pumpScreen(
        tester,
        env,
        const FolderView(bundle: FolderBundle(folderId: 'chemistry')),
      );

      expect(find.textContaining('Nothing here yet.'), findsOneWidget);
    });

    testScreen('New folder creates a subfolder', (tester) async {
      await openPhysics(tester);

      await tapAndSettle(tester, button('New folder'));
      expect(find.text('New subfolder'), findsOneWidget);
      await typeText(tester, 'Optics');
      await tapAndSettle(tester, button('Create'));

      expect(env.folders.created.single.parentId, 'physics');
    });

    testScreen('the recording menu renames', (tester) async {
      await openPhysics(tester);

      // The first More button is Mechanics (a folder), then the recordings.
      await tapAndSettle(tester, iconButton('More').at(1));
      expect(find.text('Move to folder'), findsOneWidget);
      await tapAndSettle(tester, find.text('Rename'));
      await typeText(tester, 'Energy');
      await tapAndSettle(tester, button('Save'));

      expect(env.recordings.renamed, {'r1': 'Energy'});
    });

    testScreen('the recording menu deletes', (tester) async {
      await openPhysics(tester);

      await tapAndSettle(tester, iconButton('More').at(1));
      await tapAndSettle(tester, find.text('Delete'));

      expect(env.recordings.deleted, ['r1']);
      expect(find.text('Recording deleted'), findsOneWidget);
    });

    testScreen('Move to folder opens the picker and moves', (tester) async {
      await openPhysics(tester);

      await tapAndSettle(tester, iconButton('More').at(1));
      await tapAndSettle(tester, find.text('Move to folder'));
      expect(find.text('Move to'), findsOneWidget);
      await tapAndSettle(tester, find.text('Chemistry'));
      await tapAndSettle(tester, button('Select this folder'));

      expect(env.recordings.moved, {'r1': 'chemistry'});
      expect(find.text('Moved to Chemistry'), findsOneWidget);
    });

    testScreen('Rearrange shows Cancel and Save, and back cancels', (
      tester,
    ) async {
      await openPhysics(tester);

      await tapAndSettle(tester, iconButton('Rearrange'));
      expect(find.text('Drag to change the order'), findsOneWidget);
      expect(button('Save'), findsOneWidget);
      expect(button('Cancel'), findsOneWidget);
      expect(button('Record here'), findsNothing);

      await tester.binding.handlePopRoute(); // the Android back button
      await settle(tester);

      expect(find.text('Drag to change the order'), findsNothing);
      expect(button('Record here'), findsOneWidget);
      expect(env.folders.sortOrders, isEmpty);
    });

    testScreen('Rearrange then Save writes the order', (tester) async {
      await openPhysics(tester);

      await tapAndSettle(tester, iconButton('Rearrange'));
      await tapAndSettle(tester, button('Save'));

      expect(env.recordings.sortOrders, hasLength(1));
      expect(find.text('Order saved'), findsOneWidget);
      expect(find.text('Drag to change the order'), findsNothing);
    });

    testScreen('a row drags from its body, with no long press', (tester) async {
      await openPhysics(tester);
      await tapAndSettle(tester, iconButton('Rearrange'));

      // Touch the title text (not the handle) and drag two rows down.
      await tester.drag(find.text('Work and energy'), const Offset(0, 160));
      await settle(tester);
      await tapAndSettle(tester, button('Save'));

      expect(env.recordings.sortOrders, hasLength(1));
      expect(env.recordings.sortOrders.single['r1'], isNot(0));
    });

    testScreen('Home has no Rearrange button', (tester) async {
      await openHome(tester);

      expect(iconButton('Rearrange'), findsNothing);
    });
  });

  group('Playing', () {
    testScreen('tapping a recording opens the player', (tester) async {
      await openPhysics(tester);

      await tapAndSettle(tester, find.text('Work and energy'));

      expect(env.player.state.queue.map((t) => t.recordingId), ['r1', 'r2']);
      expect(find.byKey(const Key('player-title')), findsOneWidget);
      expect(find.text('Audio · 1 of 2'), findsOneWidget);
    });

    testScreen('minimising leaves a mini player; ✕ stops it', (tester) async {
      await openPhysics(tester);
      await tapAndSettle(tester, find.text('Work and energy'));

      await tapAndSettle(tester, iconButton('Minimise'));
      expect(find.byKey(const Key('mini-player')), findsOneWidget);

      await tapAndSettle(tester, find.byKey(const Key('mini-player-stop')));
      expect(find.byKey(const Key('mini-player')), findsNothing);
      expect(env.player.state.isActive, isFalse);
    });

    testScreen('the mini player pauses, and reopens the full player', (
      tester,
    ) async {
      await openPhysics(tester);
      await tapAndSettle(tester, find.text('Work and energy'));
      await tapAndSettle(tester, iconButton('Minimise'));

      await tapAndSettle(
        tester,
        find.byKey(const Key('mini-player-play-pause')),
      );
      expect(env.player.state.playing, isFalse);

      await tapAndSettle(tester, find.byKey(const Key('mini-player-open')));
      expect(find.byKey(const Key('player-title')), findsOneWidget);
    });

    testScreen('the playing recording is marked in the list', (tester) async {
      await openPhysics(tester);
      await tapAndSettle(tester, find.text('Work and energy'));
      await tapAndSettle(tester, iconButton('Minimise'));

      expect(find.byKey(const Key('playing-dot')), findsOneWidget);
    });
  });
}
