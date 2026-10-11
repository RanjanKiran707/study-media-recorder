import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_recorder/core/errors/failure.dart';
import 'package:study_recorder/core/widgets/app_buttons.dart';
import 'package:study_recorder/core/widgets/app_chrome.dart';
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
      folderOf('physics', name: 'Physics'),
      folderOf('mechanics', name: 'Mechanics', parentId: 'physics'),
    ]);
  });

  /// Opens the Physics folder and taps Record here.
  Future<void> openRecord(
    WidgetTester tester, {
    String folder = 'physics',
  }) async {
    await pumpScreen(
      tester,
      env,
      FolderView(bundle: FolderBundle(folderId: folder)),
    );
    await tapAndSettle(tester, button('Record here'));
  }

  Finder startButton() => find.byKey(const Key('record-start'));

  group('Record screen', () {
    testScreen('opens ready, as video, with the camera prepared', (
      tester,
    ) async {
      await openRecord(tester);

      expect(find.byKey(const Key('record-start')), findsOneWidget);
      expect(find.byKey(const Key('tab-Video')), findsOneWidget);
      expect(find.byKey(const Key('tab-Audio')), findsOneWidget);
      expect(find.text('Ready'), findsOneWidget);
      expect(find.byKey(const Key('record-timer')), findsOneWidget);
      expect(find.text('00:00'), findsOneWidget);
      expect(find.text('Camera'), findsOneWidget);
      expect(iconButton('Switch camera'), findsOneWidget);
      expect(find.byKey(const Key('fake-camera-preview')), findsOneWidget);
      expect(env.recorder.prepared, RecordingType.video);
      // Pause and Done wait for the take to start.
      expect(
        tester.widget<AppIconButton>(iconButton('Done')).onPressed,
        isNull,
      );
    });

    testScreen('Audio hides the camera controls', (tester) async {
      await openRecord(tester);

      await tapAndSettle(tester, find.byKey(const Key('tab-Audio')));

      expect(find.text('Microphone only'), findsOneWidget);
      expect(iconButton('Switch camera'), findsNothing);
      expect(env.recorder.prepared, RecordingType.audio);
    });

    testScreen('start runs the timer, pause and resume change the label', (
      tester,
    ) async {
      await openRecord(tester);

      await tapAndSettle(tester, startButton());
      env.recorder.elapsedValue = const Duration(seconds: 65);
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Recording'), findsOneWidget);
      expect(find.text('01:05'), findsOneWidget);
      expect(iconButton('Pause'), findsOneWidget);

      await tapAndSettle(tester, iconButton('Pause'));
      expect(find.text('Paused'), findsOneWidget);
      expect(iconButton('Resume'), findsOneWidget);

      await tapAndSettle(tester, iconButton('Resume'));
      expect(find.text('Recording'), findsOneWidget);
    });

    testScreen('the type cannot change once the take has started', (
      tester,
    ) async {
      await openRecord(tester);
      await tapAndSettle(tester, startButton());

      await tapAndSettle(tester, find.byKey(const Key('tab-Audio')));

      expect(env.recorder.prepared, RecordingType.video);
      expect(find.text('Camera'), findsOneWidget);
    });

    testScreen('a refused permission shows the reason and Try again', (
      tester,
    ) async {
      env.recorder.failure = const ValidationFailure('permission_denied');
      await openRecord(tester);

      expect(find.textContaining('Permission was denied'), findsOneWidget);
      expect(button('Try again'), findsOneWidget);

      env.recorder.failure = null;
      await tapAndSettle(tester, button('Try again'));

      expect(find.textContaining('Permission was denied'), findsNothing);
      expect(env.recorder.calls.where((c) => c == 'prepare'), hasLength(2));
    });

    bool controlsShown(WidgetTester tester) => tester
        .widgetList<AppChromeBar>(find.byType(AppChromeBar))
        .every((bar) => bar.visible);

    testScreen('video: controls hide 3 s into a take and a tap shows them', (
      tester,
    ) async {
      await openRecord(tester);
      expect(controlsShown(tester), isTrue); // ready: always showing

      await tapAndSettle(tester, startButton());
      expect(controlsShown(tester), isTrue);
      await tester.pump(const Duration(seconds: 3));
      await settle(tester);
      expect(controlsShown(tester), isFalse);

      await tester.tapAt(const Offset(400, 300)); // the picture
      await settle(tester);
      expect(controlsShown(tester), isTrue);

      await tester.tapAt(const Offset(400, 300)); // a tap hides them again
      await settle(tester);
      expect(controlsShown(tester), isFalse);
    });

    testScreen('audio: the controls stay on screen', (tester) async {
      await openRecord(tester);
      await tapAndSettle(tester, find.byKey(const Key('tab-Audio')));
      await tapAndSettle(tester, startButton());

      await tester.pump(const Duration(seconds: 5));
      await settle(tester);
      await tester.tapAt(const Offset(400, 300));
      await settle(tester);

      expect(controlsShown(tester), isTrue);
    });

    testScreen('closing before recording goes back without a prompt', (
      tester,
    ) async {
      await openRecord(tester);

      await tapAndSettle(tester, iconButton('Close'));

      expect(find.byKey(const Key('record-start')), findsNothing);
      expect(button('Record here'), findsOneWidget);
      expect(env.recorder.released, isTrue);
    });

    testScreen('back during a take asks, and discarding deletes the file', (
      tester,
    ) async {
      await openRecord(tester);
      await tapAndSettle(tester, startButton());

      await tester.binding.handlePopRoute(); // Android back
      await settle(tester);
      expect(find.text('Discard this recording?'), findsOneWidget);

      await tapAndSettle(tester, button('Discard'));

      expect(env.recorder.discarded, ['/cache/take.mp4']);
      expect(find.byKey(const Key('record-start')), findsNothing);
    });

    testScreen('keep recording on the prompt stays on the screen', (
      tester,
    ) async {
      await openRecord(tester);
      await tapAndSettle(tester, startButton());

      await tapAndSettle(tester, iconButton('Close'));
      await tapAndSettle(tester, button('Cancel'));

      expect(find.byKey(const Key('record-start')), findsOneWidget);
      expect(env.recorder.discarded, isEmpty);
    });
  });

  group('Save screen', () {
    Future<void> recordAndFinish(
      WidgetTester tester, {
      String folder = 'physics',
      bool audio = false,
    }) async {
      await openRecord(tester, folder: folder);
      if (audio) await tapAndSettle(tester, find.byKey(const Key('tab-Audio')));
      await tapAndSettle(tester, startButton());
      await tapAndSettle(tester, iconButton('Done'));
    }

    testScreen('Done opens Save with a summary and the folder path', (
      tester,
    ) async {
      await recordAndFinish(tester, folder: 'mechanics');

      expect(find.text('Save recording'), findsOneWidget);
      expect(
        find.text('Video · 1:30 · Saving to Physics / Mechanics'),
        findsOneWidget,
      );
      expect(button('Save'), findsOneWidget);
      expect(button('Discard'), findsOneWidget);
    });

    testScreen('entering a title and saving stores it and returns', (
      tester,
    ) async {
      await recordAndFinish(tester, audio: true);

      await typeText(tester, 'Newton second law');
      await tapAndSettle(tester, button('Save'));

      final saved = env.recordings.added.single;
      expect(saved.title, 'Newton second law');
      expect(saved.folderId, 'physics');
      expect(saved.type, RecordingType.audio);
      expect(saved.durationMs, 90000);
      // Back on the folder screen, with the message.
      expect(find.text('Save recording'), findsNothing);
      expect(find.byKey(const Key('record-start')), findsNothing);
      expect(button('Record here'), findsOneWidget);
      expect(find.text('Saved to Physics'), findsOneWidget);
    });

    testScreen('a blank title shows the error and stays', (tester) async {
      await recordAndFinish(tester);

      await tapAndSettle(tester, button('Save'));

      expect(find.text('Please enter a title.'), findsOneWidget);
      expect(find.text('Save recording'), findsOneWidget);
      expect(env.recordings.added, isEmpty);
    });

    testScreen('Discard deletes the take and returns', (tester) async {
      await recordAndFinish(tester);

      await tapAndSettle(tester, button('Discard'));

      expect(env.recorder.discarded, ['/cache/take.mp4']);
      expect(env.recordings.added, isEmpty);
      expect(find.text('Recording discarded'), findsOneWidget);
      expect(button('Record here'), findsOneWidget);
    });

    testScreen('back asks before throwing the take away', (tester) async {
      await recordAndFinish(tester);

      await tester.binding.handlePopRoute();
      await settle(tester);
      expect(find.text('Discard this recording?'), findsOneWidget);
      await tapAndSettle(tester, button('Cancel'));

      expect(find.text('Save recording'), findsOneWidget);
      expect(env.recorder.discarded, isEmpty);
    });

    testScreen('while saving, the buttons are off and back is blocked', (
      tester,
    ) async {
      env.recordings.gate = Completer<void>();
      await recordAndFinish(tester);
      await typeText(tester, 'Title');

      await tester.tap(button('Save'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(canPopNow(tester), isFalse);
      expect(tester.widget<AppButton>(button('Save')).onPressed, isNull);
      expect(tester.widget<AppButton>(button('Discard')).onPressed, isNull);
      expect(
        tester.widget<AppIconButton>(iconButton('Close')).onPressed,
        isNull,
      );

      env.recordings.gate!.complete();
      await settle(tester);
      expect(env.recordings.added, hasLength(1));
      expect(find.text('Saved to Physics'), findsOneWidget);
    });
  });
}
