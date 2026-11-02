import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:study_recorder/app.dart';
import 'package:study_recorder/core/di/app_dependencies.dart';
import 'package:study_recorder/core/storage/media_storage_provider.dart';
import 'package:study_recorder/core/errors/failure.dart';
import 'package:study_recorder/core/errors/result.dart';
import 'package:study_recorder/core/widgets/app_buttons.dart';
import 'package:study_recorder/core/widgets/app_toast.dart';
import 'package:study_recorder/data/database/app_database.dart';
import 'package:study_recorder/data/folder/folder_repository.dart';
import 'package:study_recorder/data/recorder/recorder_repository_interface.dart';
import 'package:study_recorder/data/recording/recording_repository.dart';

import '../test/domain/fakes/fake_player_repository.dart';
import '../test/domain/fakes/fake_recorder_repository.dart';

/// Key journeys through the real screens, the real use cases, the real
/// database and real files in a temporary folder. Only the hardware is
/// faked: the camera and microphone (a take is a small real file) and the
/// audio and video player.
///
/// Run with `flutter test integration_test` or, on a device,
/// `flutter test integration_test -d <device>`.

/// A recorder whose takes are real files, so saving can move them.
class _FileRecorder extends FakeRecorderRepository {
  final Directory dir;
  _FileRecorder(this.dir);

  @override
  Future<Result<RecordedFile>> stop() async {
    final result = await super.stop();
    if (result is Err<RecordedFile>) return result;
    final take = (result as Ok<RecordedFile>).value;
    final file = File(
      '${dir.path}/take_${DateTime.now().microsecondsSinceEpoch}.m4a',
    );
    await file.writeAsBytes(List.filled(64, 1));
    return Ok(
      RecordedFile(
        path: file.path,
        durationMs: take.durationMs,
        type: take.type,
      ),
    );
  }
}

class AppEnv {
  final AppDatabase db;
  final Directory root;
  final FakePlayerRepository player = FakePlayerRepository();
  late final FakeRecorderRepository recorder;

  AppEnv(this.db, this.root) {
    recorder = _FileRecorder(Directory('${root.path}/cache')..createSync());
  }

  Directory get mediaDir => Directory('${root.path}/recordings');

  List<FileSystemEntity> get storedFiles =>
      mediaDir.existsSync() ? mediaDir.listSync() : [];
}

Future<AppEnv> startApp(WidgetTester tester) async {
  final root = Directory.systemTemp.createTempSync('study_recorder_it_');
  final db = AppDatabase(NativeDatabase.memory());
  final env = AppEnv(db, root);
  AppDependencies.instance = AppDependencies.fromRepositories(
    FolderRepository(db, MediaStoragePlatform(env.mediaDir)),
    RecordingRepository(db, MediaStoragePlatform(env.mediaDir)),
    env.recorder,
    env.player,
  );
  addTearDown(() async {
    dismissAppToast();
    await db.close();
    if (root.existsSync()) root.deleteSync(recursive: true);
  });
  await tester.pumpWidget(const StudyRecorderApp());
  await waitFor(tester, find.text('Study Recorder'));
  return env;
}

/// Pumps real time until [finder] matches. Animations never settle (the
/// spinner), so `pumpAndSettle` is not used.
Future<void> waitFor(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
  }
  expect(finder, findsWidgets, reason: 'timed out waiting for $finder');
}

Future<void> tapOn(WidgetTester tester, Finder finder) async {
  await tester.tap(finder.first, warnIfMissed: false);
  await tester.pump(const Duration(milliseconds: 400));
}

Finder button(String label) => find.byWidgetPredicate(
  (w) => w is AppButton && w.label == label,
  description: 'button "$label"',
);

Finder iconButton(String label) => find.byWidgetPredicate(
  (w) => w is AppIconButton && w.label == label,
  description: 'icon button "$label"',
);

Future<void> createFolder(WidgetTester tester, String name) async {
  await tapOn(tester, button('New folder'));
  await waitFor(tester, find.byType(EditableText));
  await tester.enterText(find.byType(EditableText), name);
  await tester.pump();
  await tapOn(tester, button('Create'));
  await waitFor(tester, find.text(name));
}

/// In a folder: Record here, start, Done, type the title, Save.
Future<void> recordTake(WidgetTester tester, String title) async {
  await tapOn(tester, button('Record here'));
  await waitFor(tester, find.byKey(const Key('record-start')));
  await tapOn(tester, find.byKey(const Key('tab-Audio')));
  await waitFor(tester, find.text('Microphone only'));
  await tapOn(tester, find.byKey(const Key('record-start')));
  await waitFor(tester, find.text('Recording'));
  await tapOn(tester, iconButton('Done'));
  await waitFor(tester, find.text('Save recording'));
  await tester.enterText(find.byType(EditableText), title);
  await tester.pump();
  await tapOn(tester, button('Save'));
  await waitFor(tester, find.text(title));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('create a folder and a subfolder, and open them', (tester) async {
    await startApp(tester);
    expect(find.textContaining('No folders yet'), findsOneWidget);

    await createFolder(tester, 'Physics');
    expect(find.text('Empty'), findsOneWidget);

    await tapOn(tester, find.text('Physics'));
    await waitFor(tester, button('Record here'));
    await createFolder(tester, 'Mechanics');

    await tapOn(tester, find.text('Mechanics'));
    await waitFor(tester, find.text('Physics / Mechanics'));

    // Back twice returns to Home, where Physics now has a subfolder.
    await tapOn(tester, iconButton('Back'));
    await tapOn(tester, iconButton('Back'));
    await waitFor(tester, find.text('Study Recorder'));
    expect(find.text('1 subfolder'), findsOneWidget);
  });

  testWidgets('record, save, rename, move and delete a recording', (
    tester,
  ) async {
    final env = await startApp(tester);
    await createFolder(tester, 'Physics');
    await createFolder(tester, 'Chemistry');

    // Record into Physics.
    await tapOn(tester, find.text('Physics'));
    await waitFor(tester, button('Record here'));
    await recordTake(tester, 'Newton second law');
    expect(find.textContaining('Audio · 1:30'), findsOneWidget);
    expect(env.storedFiles, hasLength(1)); // the take was moved into storage
    expect(env.recorder.discarded, isEmpty);

    // Rename it.
    await tapOn(tester, iconButton('More'));
    await tapOn(tester, find.text('Rename'));
    await waitFor(tester, find.byType(EditableText));
    await tester.enterText(find.byType(EditableText), 'Newton 2');
    await tester.pump();
    await tapOn(tester, button('Save'));
    await waitFor(tester, find.text('Newton 2'));

    // Move it to Chemistry.
    await tapOn(tester, iconButton('More'));
    await tapOn(tester, find.text('Move to folder'));
    await waitFor(tester, find.text('Move to'));
    await tapOn(tester, find.text('Chemistry'));
    await waitFor(tester, button('Select this folder'));
    await tapOn(tester, button('Select this folder'));
    await waitFor(tester, find.text('Moved to Chemistry'));
    expect(find.text('Newton 2'), findsNothing); // gone from Physics

    // Home counts follow the move.
    await tapOn(tester, iconButton('Back'));
    await waitFor(tester, find.text('Study Recorder'));
    expect(find.text('1 recording'), findsOneWidget); // Chemistry
    expect(find.text('Empty'), findsOneWidget); // Physics

    // It is in Chemistry. Delete it there.
    await tapOn(tester, find.text('Chemistry'));
    await waitFor(tester, find.text('Newton 2'));
    await tapOn(tester, iconButton('More'));
    await tapOn(tester, find.text('Delete'));
    await waitFor(tester, find.text('Recording deleted'));
    expect(find.text('Newton 2'), findsNothing);
    expect(env.storedFiles, isEmpty); // the file went with the row
  });

  testWidgets('a discarded take leaves nothing behind', (tester) async {
    final env = await startApp(tester);
    await createFolder(tester, 'Physics');
    await tapOn(tester, find.text('Physics'));
    await waitFor(tester, button('Record here'));

    await tapOn(tester, button('Record here'));
    await waitFor(tester, find.byKey(const Key('record-start')));
    await tapOn(tester, find.byKey(const Key('record-start')));
    await waitFor(tester, find.text('Recording'));
    await tapOn(tester, iconButton('Done'));
    await waitFor(tester, find.text('Save recording'));
    await tapOn(tester, button('Discard'));
    await waitFor(tester, find.text('Recording discarded'));

    expect(env.recorder.discarded, hasLength(1));
    expect(File(env.recorder.discarded.single).existsSync(), isFalse);
    expect(env.storedFiles, isEmpty);
    expect(find.textContaining('Nothing here yet'), findsOneWidget);
  });

  testWidgets('deleting a folder removes everything inside it', (tester) async {
    final env = await startApp(tester);
    await createFolder(tester, 'Physics');
    await tapOn(tester, find.text('Physics'));
    await waitFor(tester, button('Record here'));
    await createFolder(tester, 'Mechanics');
    await recordTake(tester, 'Top level take');
    await tapOn(tester, find.text('Mechanics'));
    await waitFor(tester, find.text('Physics / Mechanics'));
    await recordTake(tester, 'Nested take');
    expect(env.storedFiles, hasLength(2));
    await tapOn(tester, iconButton('Back'));
    await tapOn(tester, iconButton('Back'));
    await waitFor(tester, find.text('Study Recorder'));
    expect(find.text('2 recordings · 1 subfolder'), findsOneWidget);

    await tapOn(tester, iconButton('More'));
    await tapOn(tester, find.text('Delete'));
    await waitFor(tester, find.text('Delete this folder?'));
    await tapOn(tester, button('Delete'));
    await waitFor(tester, find.text('Folder deleted'));

    expect(find.text('Physics'), findsNothing);
    expect(env.storedFiles, isEmpty);
  });

  testWidgets('play a folder, minimise to the mini player, stop', (
    tester,
  ) async {
    final env = await startApp(tester);
    await createFolder(tester, 'Physics');
    await tapOn(tester, find.text('Physics'));
    await waitFor(tester, button('Record here'));
    await recordTake(tester, 'First');
    await recordTake(tester, 'Second');

    await tapOn(tester, find.text('First'));
    await waitFor(tester, find.text('Audio · 1 of 2'));
    expect(env.player.state.queue.map((t) => t.title), ['First', 'Second']);

    await tapOn(tester, iconButton('Next'));
    await waitFor(tester, find.text('Audio · 2 of 2'));

    await tapOn(tester, iconButton('Minimise'));
    await waitFor(tester, find.byKey(const Key('mini-player')));
    expect(find.byKey(const Key('playing-dot')), findsOneWidget);

    await tapOn(tester, find.byKey(const Key('mini-player-stop')));
    await waitFor(tester, button('Record here'));
    expect(find.byKey(const Key('mini-player')), findsNothing);
    expect(env.player.state.isActive, isFalse);
  });

  testWidgets('a refused camera permission can be retried', (tester) async {
    final env = await startApp(tester);
    await createFolder(tester, 'Physics');
    await tapOn(tester, find.text('Physics'));
    await waitFor(tester, button('Record here'));
    env.recorder.failure = const ValidationFailure('permission_denied');

    await tapOn(tester, button('Record here'));
    await waitFor(tester, find.textContaining('Permission was denied'));

    env.recorder.failure = null;
    await tapOn(tester, button('Try again'));
    await waitFor(tester, find.text('Ready'));
    expect(find.textContaining('Permission was denied'), findsNothing);
  });
}
