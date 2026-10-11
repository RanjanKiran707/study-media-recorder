import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_recorder/core/widgets/app_buttons.dart';
import 'package:study_recorder/core/widgets/app_chrome.dart';
import 'package:study_recorder/core/widgets/app_controls.dart';
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
    env.folders.folders.add(folderOf('physics', name: 'Physics'));
    env.recordings.recordings.addAll([
      recordingOf('r1', 'physics', title: 'Work and energy', createdAt: 1),
      recordingOf(
        'r2',
        'physics',
        title: 'Newton',
        createdAt: 2,
        type: RecordingType.video,
      ),
      recordingOf('r3', 'physics', title: 'Electric field', createdAt: 3),
    ]);
  });

  /// Opens the folder and taps the first recording: the whole folder is the
  /// queue and the full-screen player shows.
  Future<void> openPlayer(WidgetTester tester) async {
    await pumpScreen(
      tester,
      env,
      const FolderView(bundle: FolderBundle(folderId: 'physics')),
    );
    await tapAndSettle(tester, find.text('Work and energy'));
  }

  Finder title(String text) => find.byWidgetPredicate(
    (w) => w is Text && w.key == const Key('player-title') && w.data == text,
    description: 'player title "$text"',
  );

  testScreen('shows the title, position in the playlist and Up next', (
    tester,
  ) async {
    await openPlayer(tester);

    expect(title('Work and energy'), findsOneWidget);
    expect(find.text('Audio · 1 of 3'), findsOneWidget);
    expect(find.text('Physics'), findsWidgets); // the folder in the top bar

    // Up next is a sheet.
    await tapAndSettle(tester, iconButton('Up next'));
    expect(find.text('Up next'), findsOneWidget);
    expect(find.text('Newton'), findsOneWidget);
    expect(find.text('Electric field'), findsOneWidget);
  });

  testScreen('play/pause toggles the player', (tester) async {
    await openPlayer(tester);
    expect(iconButton('Pause'), findsOneWidget);

    await tapAndSettle(tester, iconButton('Pause'));
    expect(env.player.state.playing, isFalse);
    expect(iconButton('Play'), findsOneWidget);

    await tapAndSettle(tester, iconButton('Play'));
    expect(env.player.state.playing, isTrue);
  });

  testScreen('next and previous change the recording', (tester) async {
    await openPlayer(tester);

    await tapAndSettle(tester, iconButton('Next'));
    expect(title('Newton'), findsOneWidget);
    expect(find.text('Video · 2 of 3'), findsOneWidget);

    await tapAndSettle(tester, iconButton('Previous'));
    expect(title('Work and energy'), findsOneWidget);
  });

  testScreen('Next is off at the last recording when repeat is off', (
    tester,
  ) async {
    await openPlayer(tester);
    await tapAndSettle(tester, iconButton('Repeat all on')); // turns it off
    await tapAndSettle(tester, iconButton('Next'));
    await tapAndSettle(tester, iconButton('Next'));

    expect(title('Electric field'), findsOneWidget);
    expect(tester.widget<AppIconButton>(iconButton('Next')).onPressed, isNull);
  });

  testScreen('Next wraps to the first recording when repeat is on', (
    tester,
  ) async {
    await openPlayer(tester);
    await tapAndSettle(tester, iconButton('Next'));
    await tapAndSettle(tester, iconButton('Next'));

    await tapAndSettle(tester, iconButton('Next'));

    expect(title('Work and energy'), findsOneWidget);
  });

  testScreen('repeat all is on by default and can be turned off', (
    tester,
  ) async {
    await openPlayer(tester);
    expect(iconButton('Repeat all on'), findsOneWidget);

    await tapAndSettle(tester, iconButton('Repeat all on'));

    expect(iconButton('Repeat all off'), findsOneWidget);
    expect(env.player.state.repeatAll, isFalse);
  });

  testScreen('tapping a recording in Up next plays it', (tester) async {
    await openPlayer(tester);

    await tapAndSettle(tester, iconButton('Up next'));
    await tapAndSettle(tester, find.text('Electric field'));

    expect(title('Electric field'), findsOneWidget);
    expect(find.text('Audio · 3 of 3'), findsOneWidget);
  });

  testScreen('a video shows the video area', (tester) async {
    await openPlayer(tester);

    await tapAndSettle(tester, iconButton('Next'));

    expect(find.byKey(const Key('fake-video')), findsOneWidget);
  });

  bool controlsShown(WidgetTester tester) => tester
      .widgetList<AppChromeBar>(find.byType(AppChromeBar))
      .every((bar) => bar.visible);

  testScreen('video: controls hide after 3 s and a tap shows them', (
    tester,
  ) async {
    await openPlayer(tester);
    await tapAndSettle(tester, iconButton('Next')); // Newton, a video
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
    await openPlayer(tester); // Work and energy, audio

    await tester.pump(const Duration(seconds: 5));
    await settle(tester);
    await tester.tapAt(const Offset(400, 300));
    await settle(tester);

    expect(controlsShown(tester), isTrue);
  });

  testScreen('tapping the seek slider seeks', (tester) async {
    await openPlayer(tester);

    final rect = tester.getRect(find.byType(AppSlider));
    await tester.tapAt(Offset(rect.left + rect.width * 0.5, rect.center.dy));
    await settle(tester);

    expect(env.player.calls, contains('seekTo'));
    expect(env.player.state.positionMs, 500); // half of the 1 second fake
  });

  testScreen('minimise keeps playing, the mini player shows', (tester) async {
    await openPlayer(tester);

    await tapAndSettle(tester, iconButton('Minimise'));

    expect(find.byKey(const Key('player-title')), findsNothing);
    expect(env.player.state.playing, isTrue);
    expect(find.byKey(const Key('mini-player')), findsOneWidget);
  });

  testScreen('Android back minimises and does not stop', (tester) async {
    await openPlayer(tester);

    await tester.binding.handlePopRoute();
    await settle(tester);

    expect(find.byKey(const Key('player-title')), findsNothing);
    expect(env.player.state.isActive, isTrue);
  });

  testScreen('✕ stops playback and closes the player', (tester) async {
    await openPlayer(tester);

    await tapAndSettle(tester, iconButton('Stop and close'));

    expect(env.player.state.isActive, isFalse);
    expect(find.byKey(const Key('player-title')), findsNothing);
    expect(find.byKey(const Key('mini-player')), findsNothing);
  });
}
