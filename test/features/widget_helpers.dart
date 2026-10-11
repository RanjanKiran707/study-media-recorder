import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_recorder/core/widgets/app_buttons.dart';
import 'package:study_recorder/core/widgets/app_root.dart';
import 'package:study_recorder/core/widgets/app_toast.dart';

import '../domain/fakes/test_env.dart';

/// Like `testWidgets`, and removes a toast that is still showing, so its timer
/// is not left pending.
void testScreen(
  String description,
  Future<void> Function(WidgetTester tester) body,
) {
  testWidgets(description, (tester) async {
    try {
      await body(tester);
    } finally {
      dismissAppToast();
    }
  });
}

/// Whether the topmost screen lets the user go back right now.
bool canPopNow(WidgetTester tester) => tester
    .widgetList<PopScope>(find.byWidgetPredicate((w) => w is PopScope))
    .first
    .canPop;

/// Installs the fakes as the app's dependencies and shows [home] in the app
/// shell (no Material app).
Future<void> pumpScreen(WidgetTester tester, TestEnv env, Widget home) async {
  env.install();
  await tester.pumpWidget(AppRoot(home: home));
  await settle(tester);
}

/// Lets streams, futures and animations finish. `pumpAndSettle` is not used
/// because spinners and the equalizer animate forever.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// An [AppIconButton] by its label ("Back", "More", "Rearrange", ...).
Finder iconButton(String label) => find.byWidgetPredicate(
  (w) => w is AppIconButton && w.label == label,
  description: 'icon button "$label"',
);

/// An [AppButton] by its label.
Finder button(String label) => find.byWidgetPredicate(
  (w) => w is AppButton && w.label == label,
  description: 'button "$label"',
);

Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.tap(finder, warnIfMissed: false);
  await settle(tester);
}

/// Types into the (only) text field on screen.
Future<void> typeText(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(EditableText), text);
  await tester.pump();
}
